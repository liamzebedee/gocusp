(* Consider a segment lost if timer expires or we receive an ack for a packet
 * that is >= 3 sequence numbers ahead (TCP fast retransmit).
 *)
functor FastRetransmit(structure CongestionControl : CONGESTION_CONTROL
                       structure Event             : EVENT) 
   :> ACK_CALLBACKS where type host = CongestionControl.host =
   struct
      structure Q = ImperativeQueue
      
      type record = {
         ack  : CongestionControl.status -> unit,
         seq  : Word32.word,
         sent : Time.t,
         srtt : Time.t }
      type t = { base   : CongestionControl.t,
                 queue  : record Q.t,
                 expiry : Event.t,
                 rtt    : Time.t ref }
      type host = CongestionControl.host
      
      (* How quickly do we include new estimates on the RTT?
       * We use every ack/nack to calculate an exponential moving average.
       * The weight given to each new measurement is defined below. 
       *)
      val newWeight = 20 (* percentage *)
      val maxRTT = Time.fromSeconds 60 
      val jitter = Time.fromMilliseconds 10 (* userland scheduling delay *)
      val reorderLimit = 0w3 (* Retransmit if 3 packets ahead are acked *)
      
      val totalWeight = 100
      val oldWeight = totalWeight - newWeight
      
      fun updateRTT (srtt, rtt, sent) =
         let
            open Time
            val new = Event.time() - sent
            val mix = !rtt * oldWeight + new * newWeight
            val mix = Time.divInt (mix, totalWeight)
            val mix = Time.min (mix, maxRTT)
            (* forbid more than doubling the RTT within one round trip *)
            val mix = Time.min (mix, srtt+srtt)
         in
            rtt := mix
         end
      
      fun reschedule { base, queue, rtt, expiry } =
         case Q.peek queue of
            NONE => Event.cancel expiry
          | SOME { ack=_, seq=_, sent, srtt=_ } => 
                let
                   open Time
                   (* give it 2* RTT time + userland jitter *)
                   val date = !rtt + !rtt + jitter + sent
                in
                   if Time.<= (date, Event.time())
                   then timeout { base=base, queue=queue, rtt=rtt } expiry
                   else Event.reschedule (expiry, date)
                end 
      and timeout { base, queue, rtt } expiry =
         case Q.pop queue of
            NONE => raise Fail "unreachable code: cannot timeout no acks!"
          | SOME { ack, seq=_, sent, srtt } => 
            let
               (* safe to fire user-level callbacks;
                * timeout happens either at toplevel or in channel
                * layer processing of recv or after send.
                *)
               val () = ack CongestionControl.TIMEOUT
               val () = updateRTT (srtt, rtt, sent)
            in
               reschedule { base = base, queue = queue, expiry = expiry, rtt = rtt }
            end
      
      fun recv (t as { base, queue, rtt, expiry=_ }, { asn, acklen, data }) =
         let
            val aln = Word32.fromInt acklen
            val b31 = Word32.<< (0w1, 0w31) (* bit 23 *)
            
            fun loop () =
               case Q.pop queue of
                  NONE => ()
                | SOME (r as { ack, seq, sent, srtt }) =>
                      (* Be careful here. Wrap-around arithmetic! *)
                      (* Sequence number is acknowledged if in [asn-aln, asn] *)
                      (* If asn < seq, this ack tells us nothing new. *)
                      if Word32.andb (asn-seq, b31) <> 0w0
                         then Q.pushFront (queue, r)
                      (* If asn >= seq >= asn-aln, packet was acknowledged *)
                      else if Word32.andb (seq-asn+aln, b31) = 0w0 (* seq >= asn-aln *)
                         then (ack CongestionControl.ACK
                               ; updateRTT (srtt, rtt, sent)
                               ; loop ())
                      (* If asn-seq >= reorderLimit, consider it Nack'd *)
                      else if Word32.andb (asn-seq-reorderLimit, b31) = 0w0
                         then (ack CongestionControl.MISSING
                               ; updateRTT (srtt, rtt, sent)
                               ; loop ())
                      (* This packet was not acknowledged. However, it's not past 
                       * the reoderLimit, so hold on to it for now. *)
                      else 
                         (loop (); Q.pushFront (queue, r))
            
            val () = loop ()
            val () = reschedule t
         in
            CongestionControl.recv (base, data)
         end
      
      fun pull (t as { base, queue, rtt, expiry=_ }, { tsn, data }) =
         let
            val { filled, ack } =
               CongestionControl.pull (base, data)
            val record = {
               ack  = ack,
               seq  = tsn,
               sent = Event.time (),
               srtt = !rtt }
            val () = Q.pushBack (queue, record)
            val () = reschedule t
         in
             filled
         end
      
      fun host ({ base, ... } : t) = CongestionControl.host base
      
      (* Create an nackcallback stack giving the rts method *)       
      fun new { rts, rtt, host } =
         let
            val base = 
               CongestionControl.new 
               { rts = rts, host = host }
            val queue = Q.new ()
            val rtt = Time.min (rtt, maxRTT)
            val rtt = ref rtt
            val expiry =
               Event.new 
               (timeout { base = base, rtt  = rtt, queue = queue })
         in
            { base = base, queue = queue, expiry = expiry, rtt = rtt }
         end
      
      (* We fire all the nacks here because if we are destroy in favour of
       * a replacement channel, this will put those segments back into their
       * respective retransmit heaps.
       *)
      fun destroy ({ base, expiry, queue, ... } : t) =
         (Event.cancel expiry
          ; CongestionControl.destroy base
          ; Iterator.app 
            (fn { ack, ... } => ack CongestionControl.TIMEOUT) 
            (Q.unordered queue))
   end

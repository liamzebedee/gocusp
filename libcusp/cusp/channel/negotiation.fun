functor Negotiation(structure Event        : EVENT
                    structure HostDispatch : HOST_DISPATCH
                    structure AckGenerator : ACK_GENERATOR where type host = HostDispatch.t)
   :> NEGOTIATION where type host = HostDispatch.t =
   struct
      structure Base = AckGenerator
      
      open PacketFormat
      structure P = Suite.PublicKey
      structure S = Suite.Symmetric
      
      datatype state = 
         CLOSED         of { noState : Word8Vector.vector option }
       | SENT           of { agreed  : bits, 
                             half    : Crypto.half_negotiation,
                             noState : Word8Vector.vector option }
       | RECEIVED       of { agreed  : bits, 
                             key     : Crypto.PublicKey.t,
                             half    : Crypto.half_negotiation,
                             full    : Crypto.full_negotiation,
                             tail    : Word8Vector.vector }
       | ESTABLISHED    of { base    : Base.t,
                             full    : Crypto.full_negotiation,
                             tail    : Word8Vector.vector, 
                             tsn     : LargeInt.int,
                             asn     : LargeInt.int }
      
      type t = { rts     : Real32.real Signal.t,
                 counter : int ref,
                 timeout : Event.t,
                 state   : state ref }
      type host = HostDispatch.t
      
      type args = { key     : Crypto.PrivateKey.t,
                    bits    : bits,
                    entropy : int -> Word8Vector.vector,
                    host    : Crypto.PublicKey.t -> host,
                    exist   : Crypto.PublicKey.t -> bool,
                    contact : host -> unit }
      
      val ready = Real32.posInf
      val idle  = Real32.negInf
      val destroyMe = ready * 0.0 (* NaN *)
      
      fun debug _ = ()
      (* val debug = print *)
      
      val host = fn
         ({ state = ref (ESTABLISHED { base, ... }), ... } : t) => 
            SOME (Base.host base)
       | _ => 
            NONE
      
      (* We retransmit connection attempts with exponentially
       * increasing delays, and randomized inter-transmission times.
       * We send 8 packets with these timeouts:
       *   packet 0 -> 0.5-1s
       *   packet 1 -> 1-2s
       *   packet 2 -> 2-4s
       *   packet 3 -> 4-8s
       *   packet 4 -> 8-16s
       *)
      val xmitGap = Time.fromMilliseconds 500
      
      fun pow2Int x = Word32.toInt (Word32.<< (0w1, Word32.fromInt x))
      fun boundRTT (count, timeout) = 
         let
            val ticks = pow2Int (!count + 2) - 1
            val bound = Time.* (xmitGap, ticks)
            val remaining = valOf (Event.timeTillExecution timeout)
         in
            Time.- (bound, remaining)
         end
      
      fun delay count = 
         let
            val base = Time.* (xmitGap, pow2Int count)
            val limit = Time.toNanoseconds64 base
            val jitter = Random.int64 (random, limit)
            val jitter = Time.fromNanoseconds64 jitter
         in
            Time.+ (base, jitter)
         end
            
      (* You have 15.5-31 seconds to comply! *)
      fun newDeathCounter (rts, count) =
         let
            fun handler event =
               if !count = 8 then Signal.set rts destroyMe else
               (count := !count + 1
                ; Signal.set rts ready (* retransmit *)
                ; Event.rescheduleIn (event, delay (!count)))
         in
            Event.scheduleIn (delay (!count), handler)
         end
      
      fun new { rts, busy=_ } =
         let
            val counter = ref 0
            val () = Signal.set rts ready
         in
            { rts     = rts,
              counter = counter,
              timeout = newDeathCounter (rts, counter),
              state   = ref (CLOSED { noState = NONE }) }
         end
      
      fun destroy ({ state, timeout, ... } : t) =
         (Event.cancel timeout
          ; case !state of
               ESTABLISHED { base, ... } => Base.destroy base
             | _ => ()
          ; state := CLOSED { noState = NONE })
      
      fun badMAC (full, data, sn) =
         let
            val { macLen, decipher, ... } = full
            val { f=_, mac } = decipher sn
            val off = Word8ArraySlice.length data - macLen
            val body = Word8ArraySlice.subslice (data, 0, SOME off)
            val tail = Word8ArraySlice.subslice (data, off, NONE)
            val tail = Word8ArraySlice.vector tail
            val mac = mac body
         in
            tail <> mac
         end
         handle _ => true
      
      fun makeProgress ({ counter, timeout, rts, ... } : t) =
         let
            val () = Signal.set rts ready
         in
            Event.rescheduleIn (timeout, delay (!counter))
         end
      
      fun goFAIL (self as { state, ... } : t) =
         let
            val () = state := CLOSED { noState = NONE }
         in
            makeProgress self
         end
      
      fun goNOSTATE (self as { state, ... } : t, data) =
         let
            val () = state := CLOSED { noState = SOME (extractTail data) }
         in
            makeProgress self
         end
      
      fun goOOBNOSTATE (self as { state, ... } : t, agreed, half, data) =
         let
            val () = state := 
               SENT { agreed = agreed, half = half, 
                      noState = SOME (extractTail data) }
         in
            makeProgress self
         end
      
      fun goSENT (self as { state, ... } : t, 
                  { entropy, key, ... } : args,
                  bits as { publickey, ... } : bits,
                  half) =
         let
            val half =
               case half of
                  SOME half => half
                | NONE =>
                     Crypto.publickey {
                        suite   = valOf (P.cheapest publickey),
                        key     = key,
                        entropy = entropy }
            val () = state := SENT { agreed = bits, half = half, noState = NONE }
         in
            makeProgress self
         end
      
      fun goRECEIVED (self as { state, ... } : t, bits, half, full, key) =
         let
            (* empty mac is impossible to match against *)
            val mac = Word8Vector.tabulate (0, fn _ => 0w0)
            val () = state :=
               RECEIVED { agreed = bits, half = half, full = full, 
                          key = key, tail = mac }
         in
            makeProgress self
         end
      
      fun goESTABLISHED ({ state, timeout, counter, rts, ... } : t, 
                         { host, contact, ... } : args,
                         full, key, noEncrypt, resume) =
         let
            val { macLen, loopback, encipher, decipher } = full
            val full = 
               if noEncrypt then {
                  macLen = macLen,
                  loopback = loopback,
                  encipher = fn x => { f = fn _ => (), mac = #mac (encipher x) },
                  decipher = fn x => { f = fn _ => (), mac = #mac (decipher x) }
               } else full
            
            val host = host key
            val () = 
               if resume then debug "RESUME " else HostDispatch.wipeState host 
            
            val base = Base.new {
               rts  = rts,
               rtt  = boundRTT (counter, timeout),
               host = host
               }
            val tail = Word8Vector.tabulate (0, fn _ => 0w0)
            val e = { base=base, full=full, tail=tail, asn=0, tsn=0 }
            val () = state := ESTABLISHED e
            val () = Signal.set rts ready
            val () = Event.cancel timeout
            val () = contact host
         in
            e
         end
      
      fun processHELLO (self, args as { exist, key, entropy, ... } : args, 
                        agreed, half, { remote, B, Y }) =
         let
            val { publickey=sp, symmetric=ss, noEncrypt=se, ... } = agreed
            val { publickey=rp, symmetric=rs, noEncrypt=re, resume } = remote
            val ip = P.intersect (sp, rp)
            val is = S.intersect (ss, rs)
            val ie = se andalso re
            
            (* Can they use our key? no -> rekey *)
            val half =
               case half of
                  NONE => NONE
                | z =>
                  if P.contains (rp, valOf (P.cheapest sp)) then z else NONE
               
            (* Can we use their key? no -> stay HELLO *)
            val suite =
               Option.mapPartial
               (fn x => if P.contains (sp, x) then SOME x else NONE)
               (P.cheapest rp)
            
            (* Do we recognize this host? yes -> stay HELLO *)
            val pkey = 
               Option.map (fn s => #parse (Crypto.publickeyInfo s) {B=B}) suite
            val known = getOpt (Option.map exist pkey, false)
            
            (* Intersected options of local and remote *)
            val isect = { publickey=ip, symmetric=is, noEncrypt=ie, 
                          resume=known }
         in
            if P.isEmpty ip orelse S.isEmpty is then goFAIL self else
            case suite of 
               NONE => (debug "can't use their public-key, HELLO\n"
                        ; goSENT (self, args, isect, half))
             | SOME suite =>
            if known andalso not resume 
            then (debug "want resume, HELLO\n"
                  ; goSENT (self, args, isect, half))
            else
            let
               fun new () =
                  Crypto.publickey { suite=suite, key=key, entropy=entropy }
               val half as { symmetric, ... } = 
                  case half of
                     NONE => new ()
                   | SOME half => half
               val full = symmetric { suite = valOf (S.cheapest is), B = B, Y = Y }
               val () = debug "RECEIVED\n"
            in
               goRECEIVED (self, isect, half, full, valOf pkey)
            end
         end
      
      fun confirmWELCOME (agreed, remote) =
         let
            val { publickey=sp, symmetric=ss, noEncrypt=se, resume=sr } = agreed
            val { publickey=rp, symmetric=rs, noEncrypt=re, resume=rr } = remote
         in
            not (P.isEmpty rp) andalso
            not (S.isEmpty rs) andalso
            P.isEmpty (P.subtract (rp, sp)) andalso
            S.isEmpty (S.subtract (rs, ss)) andalso
            P.cheapest rp = P.cheapest sp andalso
            (se orelse not re) andalso
            (sr orelse not rr)
         end
      
      fun processWELCOME (self, args, half, agreed, data, { remote, B, Y }) =
         let
            exception NoGood
            val () = 
               if confirmWELCOME (agreed, remote) then () else raise NoGood
               
            (* These must be non-empty since confirmWELCOME is ok *)
            val { publickey=rp, symmetric=rs, noEncrypt=re, resume=rr } = remote
            val rp = valOf (P.cheapest rp)
            val rs = valOf (S.cheapest rs)
            
            val { parse, ... } = Crypto.publickeyInfo rp
            val key = parse { B = B }
            
            (* If there are problems with the keys, exception -> OOB NOSTATE *)
            val { symmetric, ... } = half
            val full = symmetric { suite = rs, B = B, Y = Y }
            val () = if badMAC (full, data, 0) then raise NoGood else ()
            
            val _ = goESTABLISHED (self, args, full, key, re, rr)
         in
            debug "ESTABLISHED\n"
         end
         handle _ => 
         ( debug "oob NOSTATE\n"; goOOBNOSTATE (self, agreed, half, data))
   
      fun processDATA (self as { state, ... }, 
                       { base, full, tail, asn=_, tsn }, data, d) =
         let
            val { tsn=rtsn, asn=rasn, acklen, finish } = d
            val rtsn32 = Word32.fromLargeInt rtsn
            val rasn32 = Word32.fromLargeInt rasn
            val { macLen, decipher, loopback, ... } = full
            val body =
               let
                  val { f, mac } = decipher rtsn
                  val off = Word8ArraySlice.length data - macLen
                  val text = Word8ArraySlice.subslice (data, 0, SOME off)
                  val tail = Word8ArraySlice.subslice (data, off, NONE)
                  val body = Word8ArraySlice.subslice (text, 8, NONE)
                  val tail = Word8ArraySlice.vector tail
                  val mac = mac text
               in
                  if tail <> mac then NONE else SOME (f body; body)
               end
               handle _ => NONE
            fun wrap (f, g) =
               (ignore (f ()) handle x => (ignore (g ()); raise x)
                ; g ())
         in
            case body of NONE => debug "corrupt, ignored\n" | SOME body =>
            wrap (fn () => Base.recv (base, { data = body, acklen = acklen,
                                              tsn = rtsn32, asn = rasn32 }),
                  fn () => 
                     if (finish orelse loopback) andalso 
                        HostDispatch.isZombie (Base.host base)
                     then (debug "CLOSED (NOSTATE)\n"
                           ; Base.destroy base
                           ; goNOSTATE (self, data))
                     else (debug "processed\n"
                           ; state := ESTABLISHED 
                            { base=base, full=full, tail=tail, tsn=tsn, asn=rtsn })
                     )
         end
      
      val seqs = fn
          ESTABLISHED { tsn, asn, ... } => (tsn, asn)
        | _ => (0, 0)
      
      (* The ultimate bad news would be if both sides got into AM_ESTABLISHED
       * with different keys. As long as one party never makes it, he can
       * timeout and reset the other party. The only transitions that take
       * a node to ESTABLISHED are receipt of a WELCOME message or a
       * valid data packet while in the RECEIVED state.
       *
       * Both transitions are completely safe. The MAC is nearly 100% proof 
       * that the connection establishment succeeded. 
       *)
      fun recv (self as { state, rts, counter, ... }, 
                args as {bits, ...}, 
                data) =
         case (!state, PacketFormat.parse (data, seqs (!state))) of
            (_, CORRUPT) => debug "--> CORRUPT packet received\n"
         (*----------------------CLOSED is always rts--------------------*)
         
          | (CLOSED _, NOSTATE _) => 
            (debug "--> CLOSED: NOSTATE => death\n"
             ; Signal.set rts destroyMe)
          | (CLOSED _, FAIL _)  =>
            (debug "--> CLOSED: FAIL => death\n"
             ; Signal.set rts destroyMe)
          | (CLOSED _, HELLO h) => 
               (* !!! if busy then goCHALLENGE else *)
            (debug "--> CLOSED: HELLO => "
             ; processHELLO (self, args, bits, NONE, h))
          | (CLOSED _, WELCOME _) =>
            (debug "--> CLOSED: WELCOME => NOSTATE\n"
             ; goNOSTATE (self, data))
          | (CLOSED _, DATA _)  => 
            (debug "--> CLOSED: DATA => NOSTATE\n"
             ; goNOSTATE (self, data))
          
         (*------------------SENT goes rts when change-------------------*)
         
          | (SENT _, NOSTATE _) => 
            debug "--> SENT: NOSTATE => ignored\n"
          | (SENT _, FAIL _) => 
             (* !!! maybe authenticate somehow? *)
            (debug "--> SENT: FAIL => death\n"
             ; Signal.set rts destroyMe)
          | (SENT { half, agreed, ... }, HELLO h) =>
            (debug "--> SENT: HELLO => "
             ; processHELLO (self, args, agreed, SOME half, h))
          | (SENT { half, agreed, ... }, WELCOME w) =>
            (debug "--> SENT: WELCOME => "
             ; processWELCOME (self, args, half, agreed, data, w))
          | (SENT { agreed, half, ... }, DATA _) =>
            (debug "--> SENT: DATA => oob NOSTATE\n"
             ; goOOBNOSTATE (self, agreed, half, data))

         (*------------------SEND_ESTAB goes rts when change-----------------*)
         
          | (RECEIVED { tail=my, ... }, NOSTATE { tail }) =>
             if my <> tail then debug "RECEIVED: bad NOSTATE\n" else
             (debug "--> RECEIVED: NOSTATE => SENT\n"
              ; goSENT (self, args, bits, NONE))
          | (RECEIVED _, FAIL _) => 
             debug "--> RECEIVED: FAIL => ignored (re-xmit will trigger NOSTATE)\n"
          | (RECEIVED _, HELLO _) => 
             debug "--> RECEIVED: HELLO => ignored (re-xmit will trigger NOSTATE)\n"
          | (RECEIVED { full, key, agreed, ... }, 
             WELCOME { remote as { noEncrypt, resume, ...}, ... }) =>
             if not (confirmWELCOME (agreed, remote)) then debug "--> RECEIVED: mismatched WELCOME\n" else
             if badMAC (full, data, 0) then debug "--> RECEIVED: bad WELCOME mac\n" else
             (debug "--> RECEIVED: WELCOME => "
              ; ignore (goESTABLISHED (self, args, full, key, noEncrypt, resume))
              ; debug "ESTABLISHED\n")
          | (RECEIVED { full, key, agreed, ... }, DATA (d as { tsn, ...})) =>
             if badMAC (full, data, tsn) then debug "--> RECEIVED: bad DATA\n" else
             let
                val { noEncrypt, resume, ... } = agreed
                val () = debug "--> RECEIVED: DATA => "
                val e = goESTABLISHED (self, args, full, key, noEncrypt, resume)
                val () = debug "ESTABLISHED, "
             in
                processDATA (self, e, data, d)
             end
          
         (*------------------ESTABLISHED connections are sticky--------------*)

          | (ESTABLISHED { tail=my, base, ... }, NOSTATE { tail }) =>
             if my <> tail then debug "--> ESTABLISHED: bad NOSTATE\n" else
             if HostDispatch.isZombie (Base.host base)
             then (debug "--> ESTABLISHED: NOSTATE zombie => death\n"
                   ; Signal.set rts destroyMe)
             else (debug "--> ESTABLISHED: NOSTATE => SENT\n"
                   ; Base.destroy base
                   ; counter := 0
                   ; goSENT (self, args, bits, NONE))
          | (ESTABLISHED _, FAIL _) => 
             debug "--> ESTABLISHED: FAIL => ignore\n"
          | (ESTABLISHED _, HELLO _) =>
             (debug "--> ESTABLISHED: HELLO => ack (to ellicit NOSTATE)\n"
              ; Signal.set rts ready)
          | (ESTABLISHED _, WELCOME _) =>
             (debug "--> ESTABLISHED: WELCOME => ack (prior ack lost?)\n"
              ; Signal.set rts ready)
          | (ESTABLISHED e, DATA d) =>
             (debug "--> ESTABLISHED: DATA => "
              ; processDATA (self, e, data, d))
      
      fun connect (self as { state, ... } : t, 
                   args as { bits, ... } : args) =
         case !state of
            CLOSED _ => goSENT (self, args, bits, NONE)
          | _ => () (* Already in-progress *)
      
      fun pull ({ rts, state, ... } : t, bits : bits, data) =
         case !state of
            CLOSED { noState = NONE } => 
               (debug "<-- CLOSED: FAIL, death\n"
                ; Signal.set rts destroyMe
                ; write (data, FAIL { remote = bits }))
          | CLOSED { noState = SOME tail } => 
               (debug "<-- CLOSED: NOSTATE, death\n"
                ; Signal.set rts destroyMe
                ; write (data, NOSTATE { tail = tail }))
          | SENT { noState = SOME tail, half, agreed } => 
               (debug "<-- SENT: oob NOSTATE\n"
                ; Signal.set rts idle
                ; state := SENT { noState = NONE, half = half, agreed = agreed }
                ; write (data, NOSTATE { tail = tail }))
          | SENT { agreed, half = { A, X, ... }, ... } =>
               (debug "<-- SENT: HELLO\n"
                ; Signal.set rts idle
                ; write (data, HELLO { remote = agreed, B = A, Y = X }))
          | RECEIVED { agreed, key, half as { A, X, ... }, full, tail=_ } =>
            let
               val () = debug "<-- RECEVIED: WELCOME\n"
               val () = Signal.set rts idle
               val len = write (data, WELCOME { remote = agreed, B = A, Y = X })
               
               val { encipher, macLen, ... } = full
               val { f=_, mac } = encipher 0
               val mac = mac (Word8ArraySlice.subslice (data, 0, SOME len))
               val (a, i, _) = Word8ArraySlice.base data
               val () = Word8Array.copyVec { src = mac, dst = a, di = i+len }
               
               val fullLen = len+macLen
               val tail = extractTail (Word8ArraySlice.subslice (data, 0, SOME fullLen))
               
               val () = state :=
                 RECEIVED { agreed=agreed, key=key, half=half, full=full, tail=tail }
            in
               fullLen
            end
          | ESTABLISHED { base, full, tail=_, tsn, asn } =>
            let
               val tsn = tsn + 1
               val tsn32 = Word32.fromLargeInt tsn
               val { macLen, encipher, ... } = full
               
               val len = Word8ArraySlice.length data - 8 - macLen
               val subdata = Word8ArraySlice.subslice (data, 8, SOME len)
               val { len, acklen, asn=asn32 } = 
                  Base.pull (base, {
                     data = subdata, 
                     tsn  = tsn32 })
               
               val finish = HostDispatch.isZombie (Base.host base)
               val off = write (data, DATA { acklen=acklen, finish=finish, asn=asn32, tsn=tsn32 })
               val textLen = len+off
               
               val () =
                 if finish
                 then debug "<-- ESTABLISHED: DATA(finish)\n"
                 else debug "<-- ESTABLISHED: DATA\n"
               
               val { f, mac } = encipher tsn
               val (a, i, _) = Word8ArraySlice.base data
               
               val () = f (Word8ArraySlice.subslice (subdata, 0, SOME len))
               val mac = mac (Word8ArraySlice.subslice (data, 0, SOME textLen))
               val () = Word8Array.copyVec { src = mac, dst = a, di = i+textLen }
               
               val fullLen = textLen + macLen
               val tail = extractTail (Word8ArraySlice.subslice (data, 0, SOME fullLen))
               
               val () = 
                  state := ESTABLISHED { base=base, full=full, tail=tail, tsn=tsn, asn=asn }
            in
               fullLen
            end
   end

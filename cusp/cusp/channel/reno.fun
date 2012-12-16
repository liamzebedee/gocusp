functor Reno(structure HostDispatch : HOST_DISPATCH) 
   :> CONGESTION_CONTROL where type host = HostDispatch.t =
   struct
      datatype fields = T of
         { base               : HostDispatch.t,
           congestionWindow   : Real32.real,
           slowStartThreshold : Real32.real, 
           inFlight           : int,
           rts                : bool Signal.t }
      withtype t = fields ref
      type host = HostDispatch.t
      
      datatype status = TIMEOUT | MISSING | ACK
      
      val newWindow = 2500.0
      val minWindow = 2500.0 (* only 1 packet inflight when link dies *)
      val maxWindow = 1000000000.0 (* 1GB in flight *)
      
      open FunctionalRecordUpdate
      fun get f (ref (T fields)) = f fields
      fun update (this as ref (T fields)) =
         let
            fun from v1 v2 v3 v4 v5 = 
               {base=v1,congestionWindow=v2,slowStartThreshold=v3,
                inFlight=v4,rts=v5}
            fun to f
               {base=v1,congestionWindow=v2,slowStartThreshold=v3,
                inFlight=v4,rts=v5} = f v1 v2 v3 v4 v5
         in
            Fold.post (makeUpdate5 (from, from, to) fields,
                       fn z => this := T z)
         end
      
      fun recv (this, data) = HostDispatch.recv (get#base this, data)
      
      fun pull (this, data) =
         let
            val (filled, ack) = HostDispatch.pull (get#base this, data)
            
            (* Here we cheat a little.
             * We know IP adds +20 bytes, UDP +8, and CUSP +8.
             * We guess that the encryption layer adds +16 more bytes MAC.
             *)
            val bytes = filled + 52
            val () = update this upd#inFlight (fn x => x + bytes) $
            
            val oldThreshold = get#slowStartThreshold this
            fun process ACK =
                  let
                     val rbytes = Real32.fromInt bytes
                     val cwnd = get#congestionWindow this
                     val growth = 
                        if cwnd < get#slowStartThreshold this
                        then rbytes
                        else rbytes * rbytes / cwnd
                     val congestionWindow = 
                        Real32.min (get#congestionWindow this + growth, maxWindow)
                  in
                     update this
                        set#congestionWindow   congestionWindow $
                  end
              | process TIMEOUT =
                  if Real32.!= (get#slowStartThreshold this, oldThreshold) then () else
                  let
                     val rflight = Real32.fromInt (get#inFlight this)
                     val window  = Real32.max (rflight / 2.0, minWindow)
(*
                     val () = print ("Slow start: " ^ Real32.toString window ^ " / " ^ Real32.toString (get#congestionWindow this) ^ "\n")
*)
                  in
                     update this
                        set#congestionWindow   minWindow
                        set#slowStartThreshold window $
                  end
              | process MISSING =
                  if Real32.!= (get#slowStartThreshold this, oldThreshold) then () else
                  let
                     val rflight = Real32.fromInt (get#inFlight this)
                     val window  = Real32.max (rflight / 2.0, minWindow)
(*
                     val () = print ("Fast recovery: " ^ Real32.toString window ^ " / " ^ Real32.toString (get#congestionWindow this) ^ "\n")
*)
                  in
                     update this
                        set#congestionWindow   window
                        set#slowStartThreshold window $
                  end
            
            fun setrts () =
               Signal.set (get#rts this)
               (Real32.fromInt (get#inFlight this) < get#congestionWindow this)
            
            fun wrap x = 
               (process x
                ; update this upd#inFlight (fn x => x - bytes) $
                ; setrts ()
                ; ack (x = ACK))
            val () = setrts ()
         in
            { filled = filled, ack = wrap }
         end
      
      fun host this = get#base this
      
      fun new { rts, host } =
         let
            val no = Real32.negInf
            fun ready (prio, true) = prio
              | ready (prio, false) = if Real32.isNan prio then prio else no
            val (his, mine) = Signal.split (rts, ready, (no, true))
            val () = HostDispatch.bind (host, Signal.set his)
         in
            ref (T { base               = host,
                     congestionWindow   = newWindow,
                     inFlight           = 0,
                     slowStartThreshold = maxWindow,
                     rts                = mine })
         end 
      
      fun destroy (ref (T { base, ... })) =
         HostDispatch.unbind base
   end

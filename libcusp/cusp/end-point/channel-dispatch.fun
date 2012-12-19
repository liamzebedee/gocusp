functor ChannelDispatch(structure Address      : ADDRESS
                        structure HostDispatch : HOST_DISPATCH
                        structure ChannelStack : NEGOTIATION
                          where type host = HostDispatch.t
                        structure Event        : EVENT) =
   struct
      structure PrioKey =
         struct
            type t = Real32.real * Time.t
            fun (a, b) < (c, d) =
               case Real32.compareReal (a, c) of
                  IEEEReal.LESS => false
                | IEEEReal.EQUAL => Time.< (b, d)
                | IEEEReal.GREATER => true
                | IEEEReal.UNORDERED => false (* NaNs suck *)
         end
      
      structure Map = HashTable(Address)
      structure Queue = ManagedHeap(PrioKey)
      
      type channel = ChannelStack.t
      type host = HostDispatch.t
      type listener = host option -> unit
      type record = channel * listener Ring.t
      type t = { table         : record Map.t,
                 queue         : Address.t Queue.t,
                 rts           : bool Signal.t,
                 key           : Crypto.PrivateKey.t,
                 bits          : ChannelStack.bits,
                 entropy       : int -> Word8Vector.vector,
                 bytesSent     : Counter.int ref,
                 bytesReceived : Counter.int ref,
                 safeToDestroy : (unit -> unit) Ring.t }
      
      fun new { key, rts, entropy, publickey, symmetric, noEncrypt } = {
         table         = Map.new (),
         queue         = Queue.new (),
         rts           = rts,
         key           = key,
         bits          = { publickey = publickey, symmetric = symmetric, 
                           noEncrypt = noEncrypt, resume = false },
         entropy       = entropy,
         bytesSent     = ref 0,
         bytesReceived = ref 0,
         safeToDestroy = Ring.new (fn () => ()) } :t
      
      fun safeExec ring a =
         let
            val cbs = tl (Iterator.toList (Ring.iterator ring))
            fun exec r =
               if Ring.isSolo r then () else
               (ignore (Ring.get r a); Ring.remove r)
         in
            List.app exec cbs
         end
      
      fun killRecord ({ queue, table, safeToDestroy, ... } : t) r =
         let
            val (_, _, a) = Queue.sub r
            val (c, cbs) = 
               case Map.find (table, a) of
                  NONE => raise Fail "Impossible to destroy unmapped channel"
                | SOME x => x
            val () = Queue.remove (queue, r)
            val () = Map.remove (table, a)
            val () = ChannelStack.destroy c
            
            (* Make certain we only run safeToDestroy from top-level loop.
             * destroy could take away endpoints, hosts, etc on the stack.
             *)
            fun doubleCheck _ =
               if not (Queue.isEmpty queue) then () else
               safeExec safeToDestroy ()
            val () = 
               if not (Queue.isEmpty queue) then () else
               ignore (Event.scheduleIn (Time.fromSeconds 0, doubleCheck))
         in
            safeExec cbs NONE
         end
      
      fun destroy (this as { queue, ... } : t) =
         while not (Queue.isEmpty queue)
         do killRecord this (valOf (Queue.peek queue))
      
      fun whenSafeToDestroy ({safeToDestroy, queue, ... } :t, cb) =
         if Queue.isEmpty queue then (cb (); fn () => ()) else
         let
            val r = Ring.add (safeToDestroy, cb)
         in
            fn () => Ring.remove r
         end
      
      fun key           (x:t) = #key x
      fun bytesSent     (x:t) = Counter.toLarge (! (#bytesSent      x))
      fun bytesReceived (x:t) = Counter.toLarge (! (#bytesReceived  x))
      
      val bound = (0.0, Time.maxTime)
      
      fun args ({ key, bits, entropy, ... } : t, host, exist, contact) = {
         key     = key,
         bits    = bits,
         entropy = entropy,
         host    = host,
         exist   = exist,
         contact = contact
      }
      fun fail _ = raise Domain
      fun connectArgs this = args (this, fail, fail, fail)
      
      fun create (this as { table, queue, rts, ... } : t, address, busy) =
         let
            fun resendRTS () =
               case Queue.peekBounded (queue, bound) of
                  NONE => Signal.set rts false
                | SOME _ => Signal.set rts true
            
            val entry = Queue.wrap ((Real32.negInf, Event.time ()), address)
            
            fun destroy () = (killRecord this entry; resendRTS ())
            
            fun channelRTS prio =
               let
                  val (inHeap, (old, when), _) = Queue.sub entry
               in
                  if not inHeap orelse Real32.== (prio, old) then () else
                  (if Real32.isNan prio 
                   then destroy ()
                   else Queue.update (queue, entry, (prio, when))
                   ; resendRTS ())
               end
            
            val out = ChannelStack.new { rts = Signal.new channelRTS,
                                         busy = busy }
            val () = Queue.push (queue, entry)
            val () = Map.add (table, address, (out, Ring.new (fn _ => ())))
         in
            out
         end
      
      fun reconnect (this as { table, ... }) address =
         case Map.find (table, address) of
            SOME _ => ()
          | NONE => 
            let
               val channel = create (this, address, false)
            in
               ChannelStack.connect (channel, connectArgs this)
            end

      fun recv (self as { table, bytesReceived, ... }, 
                host, exist, sender, data, numHosts) =
         let
            val busy = numHosts + 5 < Map.size table
            val (channel, cbs) =
               case Map.find (table, sender) of
                  NONE => (create (self, sender, busy), Ring.new (fn _ => ()))
                | SOME z => z
            
            fun contact host = safeExec cbs (SOME host)
            
            val len = Word8ArraySlice.length data
            val () = bytesReceived := !bytesReceived + Counter.fromInt len
            val host = host (sender, reconnect self)
            val args = args (self, host, exist, contact)
         in
            ChannelStack.recv (channel, args, data)
         end
      
      fun pull ({ table, queue, bytesSent, bits, ... } : t) =
         let
            val record =
               case Queue.popBounded (queue, bound) of
                  SOME x => x
                | NONE => raise Fail "Impossible. Asked to pull when no RTS channel."
            
            val (_, (prio, _), address) = Queue.sub record
            val (channel, _) =
               case Map.find (table, address) of
                  NONE => raise Fail "Impossible. Asked to pull half-existant channel."
                | SOME z => z
            
            fun writer data =
               let 
                   (* load balance *)
                   val () = Queue.update (queue, record, (prio, Event.time ()))
                   
                   val filled = ChannelStack.pull (channel, bits, data)
                   val () = bytesSent := !bytesSent + Counter.fromInt filled
                in
                   Word8ArraySlice.subslice (data, 0, SOME filled)
                end
         in
            { writer = writer, receiver = address }
         end
      
      fun channels ({ table, ... }: t) =
         Iterator.map 
         (fn (a, (c, _)) => (a, ChannelStack.host c)) 
         (Map.iterator table)
      
      fun contact (this as { table, ... }, address, service, cb) =
         let
            val (channel, cbs) =
               case Map.find (table, address) of
                  NONE => (create (this, address, false), Ring.new (fn _ => ()))
                | SOME z => z
            fun cbConnect host =
               case host of
                  NONE => cb NONE
                | SOME h => cb (SOME (h, HostDispatch.connect (h, service)))
         in
            case ChannelStack.host channel of
               SOME h => (cbConnect (SOME h); fn () => ())
             | NONE =>
               let
                  val r = Ring.add (cbs, cbConnect)
                  val () = Map.update (table, address, (channel, cbs))
                  val () = ChannelStack.connect (channel, connectArgs this)
               in
                  fn () => Ring.remove r
               end
            end
   end

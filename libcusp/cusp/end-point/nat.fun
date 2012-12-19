functor NAT(Transport : TRANSPORT) : TRANSPORT =
   struct
      open Transport
      
      structure EndPoint =
         struct
            open EndPoint
            
            val REVERSE_CONTACT = 0w1
            val FORWARD_CONTACT = 0w2
            
            local
               open Serial
               val { length, parser, writer } = pickle `Address.t $
            in
               val addressLength = length
               fun addressToVector  a = writer (fn v => v) a
               fun addressFromArray a = parser (a, fn v => v)
            end
            
            fun new args =
               let
                  fun readAddr (stream, cb) =
                     let
                        val a = Word8Array.array (addressLength, 0w0)
                        val buf = Word8ArraySlice.full a
                        val rec start = fn 
                           () => InStream.readFully (stream, buf, gotVector)
                        and gotVector = fn
                           false => cb NONE
                         | true => InStream.readShutdown (stream, done)
                        and done = fn
                           false => cb NONE
                         | true =>
                           cb (SOME (addressFromArray a))
                     in
                        start ()
                     end
                  
                  val rec reverseContact = fn 
                     (host, _, stream) =>
                        readAddr (stream, doContact (Host.endPoint host))
                  and doContact = fn endPoint => fn
                     NONE => ()
                   | SOME target =>
                        EndPoint.contactPeer (endPoint, target, fn _ => ())
                  
                  fun forwardContact (host, _, stream) =
                     case Host.channel host of
                        NONE => ()
                      | SOME channel =>
                        let
                           val endPoint = Host.endPoint host
                           val target = Channel.remoteAddress channel
                           val target = addressToVector target
                        in
                           readAddr (stream, doForward (endPoint, target))
                        end
                  and doForward (endPoint, target) = fn
                     NONE => ()
                   | SOME slave =>
                     let
                        val channel = EndPoint.channel (endPoint, slave)
                        val host = Option.mapPartial Channel.host channel
                     in
                        case host of
                           NONE => () (* Not connected to the slave? meh. *)
                         | SOME host =>
                           let
                              val stream = Host.connect (host, REVERSE_CONTACT)
                           in
                               OutStream.write (stream, target, doDone stream)
                           end
                     end
                  and doDone stream = fn
                     OutStream.RESET => ()
                   | OutStream.READY => OutStream.shutdown (stream, fn _ => ())
                  
                  val x = EndPoint.new args
                  val _ = advertise (x, SOME REVERSE_CONTACT, reverseContact)
                  val _ = advertise (x, SOME FORWARD_CONTACT, forwardContact)
               in
                  x
               end
            
            (* It might be a good idea not to do the indirection if already
             * established. OTOH, leaving it as it can help revive a dead link.
             *)
            fun contactSlave (x, slave, peer, cb) =
               let
                  val rec contact = fn
                     () => EndPoint.contactPeer (x, peer, request)
                  and request = fn
                     NONE => direct true
                   | SOME host => 
                     let
                        val stream = Host.connect (host, FORWARD_CONTACT)
                        val payload = addressToVector slave
                     in
                        OutStream.write (stream, payload, shutdown stream)
                     end
                  and shutdown = fn stream => fn
                     OutStream.RESET => direct true
                   | OutStream.READY => OutStream.shutdown (stream, direct)
                  and direct = fn
                     _ => EndPoint.contactPeer (x, slave, cb)
               in
                  contact ()
               end
         end
   end

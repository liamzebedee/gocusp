structure UDP4 :> UDP =
   struct
      structure Address =
         struct
            type t = INetSock.sock_addr
            
            local
               (* We pull some scary shit here to make addresses 16-bit
                * aligned only (so 2* an address fit nicely) and to make
                * certain we can parse relatively quickly.
                *)
               open Serial
               (* An address is fundamentally an (ip, port) *)
               val t = aggregate tuple2 `(vector (word8, 4)) `word16b $
               (* ... however, we need to convert in/out of a MLton address *)
            in
               val t = map {
                  store = fn addr => 
                     let
                        val (netdb, port) = INetSock.fromAddr addr
                        val v = MLton.Socket.Address.toVector netdb
                     in
                        (v, Word16.fromInt port)
                     end,
                  load  = fn (ip, port) => 
                     let
                        val netdb = MLton.Socket.Address.fromVector ip
                     in
                        INetSock.toAddr (netdb, Word16.toInt port)
                     end,
                  extra = fn _ => ()
               } t
            end
            
            fun toString addr = case INetSock.fromAddr addr of (ip, port) =>
               NetHostDB.toString ip ^ ":" ^ Int.toString port
            
            fun eq (a, b) = 
               let
                  val (aip, aport) = INetSock.fromAddr a
                  val (bip, bport) = INetSock.fromAddr b
               in
                  aport = bport andalso aip = bip
               end
            
            fun hash x = 
               let
                  val (ip, port) = INetSock.fromAddr x
               in
                  Hash.int port o 
                  Hash.word8vector (MLton.Socket.Address.toVector ip)
               end
            
            fun addrFromString str = 
               case NetHostDB.fromString str of
                  SOME addr => SOME addr
                | NONE =>
                      case NetHostDB.getByName str of 
                        NONE => NONE
                      | SOME entry => SOME (NetHostDB.addr entry)
            
            fun fromString str =
               case String.fields (fn c => c = #":") str of
                  [host, port] =>
                     (case (addrFromString host, Int.fromString port) of
                         (SOME ip, SOME port) => SOME (INetSock.toAddr (ip, port))
                       | _ => NONE)
                | [host] =>
                     (case addrFromString host of
                         (SOME ip) => SOME (INetSock.toAddr (ip, 8585))
                       | NONE => NONE)
                | _ => NONE
         end
      
      type t = {
         socket : INetSock.dgram_sock,
         unhook : unit -> bool }
            
      datatype status =
         DATA of { sender : Address.t, data : Word8ArraySlice.slice }
       | EXCEPTION of exn

      type callback = status -> unit
      
      exception AddressInUse
      
      fun mtu _ = 1472 (* ethernet - ip - udp *)
      val buffer = 
         OncePerThread.new 
         (fn () => Word8ArraySlice.full 
                   (Word8Array.tabulate (mtu (), fn _ => 0w0)))
      
      fun ready (cb, sock) () =
         OncePerThread.get (buffer, fn buffer =>
         case Socket.recvArrFromNB (sock, buffer) 
              handle x => (cb (EXCEPTION x); NONE) of
            NONE => Main.REHOOK
          | SOME (len, sender) => 
            let
               val data = Word8ArraySlice.subslice (buffer, 0, SOME len)
               val () = cb (DATA { sender = sender, data = data })
            in
               ready (cb, sock) ()
            end)
      
      fun bind (port, cb) =
         let
            val sock = INetSock.UDP.socket ()
            val desc = Socket.sockDesc sock
            val cb = ready (cb, sock)
            
            val addr = INetSock.any (getOpt (port, 0))
            val () = Socket.bind (sock, addr) 
                     handle OS.SysErr _ => (Socket.close sock; raise AddressInUse)
         in
            { socket = sock,
              unhook = Main.registerSocketForRead (desc, cb) }
         end
      
      fun close { socket, unhook } = 
         if unhook () then Socket.close socket else ()
      
      fun send { udp={socket, unhook=_}, receiver, writer } =
         OncePerThread.get (buffer, fn buffer =>
         Socket.sendArrTo (socket, receiver, writer buffer))
   end

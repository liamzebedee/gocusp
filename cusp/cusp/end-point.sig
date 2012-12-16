signature END_POINT =
   sig
      type t
      type address
      type host
      type instream
      type outstream
      type publickey
      type privatekey
      type publickey_set
      type symmetric_set
      type service = Word16.word
      
      (* Create a local transport end-point bound to the provided port.
       * Handler receives any exceptions generated by UDP send/recv.
       * Entropy is used to generate ephemeral keys for channels.
       * May raise a transport-specific exception if port is already in use.
       *)
      type options = { 
         encrypt   : bool, 
         publickey : publickey_set,
         symmetric : symmetric_set
      }
      val new : { port    : int option, 
                  handler : exn -> unit,
                  entropy : int -> Word8Vector.vector,
                  key     : privatekey,
                  options : options option } -> t
      
      (* Destroy the EndPoint and close the socket.
       * Any further use of EndPoint is undefined.
       *)
      val destroy : t -> unit
      (* Since this is a userland library, TIME_WAIT cannot happen after the
       * program exits. For a clean exit, an application should close all of
       * its streams and then call whenSafeToDestroy. The provided callback
       * will be invoked once all channels have been cleanly closed.
       * The returned callback unhooks the provided callback.
       *)
      val whenSafeToDestroy : t * (unit -> unit) -> (unit -> unit)
      
      (* Set a transmission rate limit (bytes/second) *)
      val setRate : t * int -> unit
      
      (* Recover the end-point's private key *)
      val key : t -> privatekey
      
      (* Total traffic used on this transport (entire packets) *)
      val bytesSent     : t -> LargeInt.int
      val bytesReceived : t -> LargeInt.int
      
      (* Attempt to contact the remote host and Host.connect to it.
       * Returned is a handle that can be used to cancel the callback.
       * If the connection fails, NONE is returned.
       * Please confirm that the host's public key is as expected
       * before using the outstream.
       *)
      val contact : t * address * service * ((host * outstream) option -> unit) -> (unit -> unit)
      
      (* Lookup a host by public key or walk all of them *)
      val host   : t * publickey -> host option
      val hosts  : t -> host Iterator.t
      
      (* List all the addresses associated to a channel *)
      val channels : t -> (address * host option) Iterator.t
      
      (* Advertise a service that can be connected to by any remote host.
       * If NONE is passed, the service name is dynamically assigned.
       * A well-known service name should have the high two bits cleared.
       * AddressInUse is raised if the named service is in use.
       * Service name 0 is reserved.
       *)
      val advertise : t * service option * (host * service * instream -> unit) -> service
      val unadvertise : t * service -> unit
   end

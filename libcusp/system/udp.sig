signature UDP =
   sig
      structure Address : ADDRESS
      
      type t
      
      (* The callback invoked when a message is received or read exception.
       * The sender address and data payload are as in normal UDP.
       *)
      datatype status =
         DATA of { sender : Address.t, data  : Word8ArraySlice.slice }
       | EXCEPTION of exn
      type callback = status -> unit
      
      exception AddressInUse
      
      (* Create a new UDP socket with the given receive callback. *)
      val bind : int option * callback -> t
      
      (* Close the socket, freeing resources and unhooking the receiver. *)
      val close : t -> unit
      
      (* Return the current MTU *)
      val mtu : t -> int
      
      (*  Send a message to the named node *)
      val send : { udp      : t,
                   receiver : Address.t,
                   writer   : Word8ArraySlice.slice -> Word8ArraySlice.slice } -> unit
   end

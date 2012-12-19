signature HOST_DISPATCH =
   sig
      include HOST 
      where type instream = InStreamQueue.t
      where type outstream = OutStreamQueue.t
      where type publickey = Crypto.PublicKey.t
      
      val recv: t * Word8ArraySlice.slice -> bool (* true -> packet ok *)
      val pull: t * Word8ArraySlice.slice -> int * (bool -> unit)
      
      val new: {
         key       : publickey,
         address   : address,
         global    : Word16.word -> (t * InStreamQueue.t -> unit) option,
         reconnect : address -> unit
      }-> t
      val updateAddress : t * address -> unit
      
      (* (Un)bind a Host to a channel *)
      val bind: t * (Real32.real -> unit) -> unit
      val unbind: t -> unit
      val isBound: t -> bool
      
      (* If a channel is negotiated with no prior state, then all instreams
       * must be reset and all outstreams older than the last unbind.
       *)
      val wipeState : t -> unit
      val isZombie  : t -> bool
      
      val poke : t -> unit
      
      (* Kill off as much state as possible.
       * Cancel all events. Reset all streams.
       *)
      val destroy : t -> unit
   end

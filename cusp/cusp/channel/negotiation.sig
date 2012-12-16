(* A Negotiation functor is constructed with a higher level layer (Integrity)
 * A Negotiation object (new) is constructed with a lower level rts (Transport)
 *)
signature NEGOTIATION =
   sig
      type t
      type host
      
      type bits = {
         publickey : Suite.PublicKey.set,
         symmetric : Suite.Symmetric.set,
         noEncrypt : bool,
         resume    : bool
      }
      
      type args = { key     : Crypto.PrivateKey.t,
                    bits    : bits,
                    entropy : int -> Word8Vector.vector,
                    host    : Crypto.PublicKey.t -> host,
                    exist   : Crypto.PublicKey.t -> bool,
                    contact : host -> unit }
      
      (* NaN -> destroy this channel *)
      val new : { rts       : Real32.real Signal.t, 
                  busy      : bool } -> t
      
      (* Clear all events associated to the channel.
       * Unbind any attached host.
       *)
      val destroy: t -> unit
      
      (* Become actively interested in connection establishment 
       * The arguments host, exist, and contact are not needed.
       *)
      val connect : t * args -> unit
      
      (* Returns the connected host (if any) *)
      val host : t -> host option
      
      val recv : t * args * Word8ArraySlice.slice -> unit
      val pull : t * bits * Word8ArraySlice.slice -> int
   end

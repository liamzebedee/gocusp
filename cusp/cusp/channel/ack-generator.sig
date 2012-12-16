(* An AckGenerator functor is constructed with a higher level layer (AckCallbacks)
 * An AckGenerator object (new) is constructed with a lower level rts (Integrity)
 *)
signature ACK_GENERATOR =
   sig
      type t
      type host
      
      val recv: t  * {
         data   : Word8ArraySlice.slice,
         tsn    : Word32.word,
         asn    : Word32.word,
         acklen : int
      } -> unit
      
      val pull: t * {
         data : Word8ArraySlice.slice,
         tsn  : Word32.word
      } -> {
         len    : int,
         asn    : Word32.word,
         acklen : int
      }
      
      val host: t -> host
      
      (* Create an nackcallback stack giving the rts method *)       
      val new: { rts      : Real32.real Signal.t, 
                 rtt      : Time.t,
                 host     : host } -> t
      val destroy: t -> unit
   end

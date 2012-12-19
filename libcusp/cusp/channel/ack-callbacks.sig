(* An AckCallbacks functor is constructed with a higher level layer (CongestionControl)
 * An AckCallbacks object (new) is constructed with a lower level rts (AckGenerator)
 *)
signature ACK_CALLBACKS =
   sig
      type t
      type host
      
      val recv: t * {
         data   : Word8ArraySlice.slice,
         asn    : Word32.word,
         acklen : int } -> bool
      val pull: t * {
         data : Word8ArraySlice.slice,
         tsn  : Word32.word } -> int
      
      val host: t -> host
      
      (* Create an nackcallback stack giving the rts method *)       
      val new: { rts      : Real32.real Signal.t,
                 rtt      : Time.t,
                 host     : host } -> t
      val destroy: t -> unit
   end

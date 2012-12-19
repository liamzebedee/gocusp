(* A CongestionControl functor is constructed with a higher level layer (Host)
 * A CongestionControl object (new) is constructed with a lower level rts (AckCallbacks)
 *)
signature CONGESTION_CONTROL =
   sig
      type t
      type host
      
      datatype status = TIMEOUT | MISSING | ACK
      
      val recv: t * Word8ArraySlice.slice -> bool
      val pull: t * Word8ArraySlice.slice ->
                { filled   : int,
                  ack      : status -> unit } (* callback to report (n)ack *)
      
      val host: t -> host
      
      (* Create a congestioncontrol stack giving the rts method *)       
      val new: { rts      : Real32.real Signal.t,
                 host     : host } -> t
      val destroy: t -> unit
   end

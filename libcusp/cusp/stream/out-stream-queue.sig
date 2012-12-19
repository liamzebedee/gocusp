signature OUT_STREAM_QUEUE =
   sig
      include OUT_STREAM
      eqtype t'
      sharing type t = t'
      
      datatype event = 
         RTS of Real32.real
       | BECAME_RESET
       | BECAME_COMPLETE
       | INFLIGHT_BYTES of int
       | RETRANSMIT_BYTES of int
      
      (* Expect at least 8 bytes available in the buffer *)
      val pull: t * Word16.word * Word8ArraySlice.slice -> int * (bool -> unit)
      val recv: t * Word8ArraySlice.slice * PacketFormat.writer -> int
      val isReset: t -> bool

      val new: (event -> unit) -> t
   end

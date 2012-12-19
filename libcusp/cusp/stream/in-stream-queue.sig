signature IN_STREAM_QUEUE =
   sig
      include IN_STREAM
      eqtype t'
      sharing type t = t'
      
      datatype event = 
         RTS of Real32.real
       | BECAME_UNASSIGNED
       | BECAME_COMPLETE
       | BECAME_RESET
       | UNREAD_BYTES of int 
       | OUT_OF_ORDER_BYTES of int
      
      (* Expect at least 4 bytes available in the buffer *)
      val pull: t * Word16.word * int * Word8ArraySlice.slice -> int * (bool -> unit)
      val recv: t * Word8ArraySlice.slice * PacketFormat.reader -> int
      val isReset: t -> bool
      
      val new: (event -> unit) -> t
   end

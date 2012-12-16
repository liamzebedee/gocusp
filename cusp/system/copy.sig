signature COPY =
   sig
      (* Be careful. Bounds are not checked. *)
      
      val word8v  : Word8ArraySlice.slice  * Word8VectorSlice.slice  -> unit
      val word16v : Word16ArraySlice.slice * Word16VectorSlice.slice -> unit
      val word32v : Word32ArraySlice.slice * Word32VectorSlice.slice -> unit
      val word64v : Word64ArraySlice.slice * Word64VectorSlice.slice -> unit

      val real32v : Real32ArraySlice.slice * Real32VectorSlice.slice -> unit
      val real64v : Real64ArraySlice.slice * Real64VectorSlice.slice -> unit
      
      val word8a  : Word8ArraySlice.slice  * Word8ArraySlice.slice  -> unit
      val word16a : Word16ArraySlice.slice * Word16ArraySlice.slice -> unit
      val word32a : Word32ArraySlice.slice * Word32ArraySlice.slice -> unit
      val word64a : Word64ArraySlice.slice * Word64ArraySlice.slice -> unit

      val real32a : Real32ArraySlice.slice * Real32ArraySlice.slice -> unit
      val real64a : Real64ArraySlice.slice * Real64ArraySlice.slice -> unit
   end

structure Copy :> COPY =
   struct
      fun make (base, copy) (a, v) =
         let
            val (a, ao, _) = base a
         in
            copy { dst = a, di = ao, src = v }
         end
      
      val word8v  = make (Word8ArraySlice.base,  Word8ArraySlice.copyVec)
      val word16v = make (Word16ArraySlice.base, Word16ArraySlice.copyVec)
      val word32v = make (Word32ArraySlice.base, Word32ArraySlice.copyVec)
      val word64v = make (Word64ArraySlice.base, Word64ArraySlice.copyVec)
      
      val real32v = make (Real32ArraySlice.base, Real32ArraySlice.copyVec)
      val real64v = make (Real64ArraySlice.base, Real64ArraySlice.copyVec)
      
      val word8a  = make (Word8ArraySlice.base,  Word8ArraySlice.copy)
      val word16a = make (Word16ArraySlice.base, Word16ArraySlice.copy)
      val word32a = make (Word32ArraySlice.base, Word32ArraySlice.copy)
      val word64a = make (Word64ArraySlice.base, Word64ArraySlice.copy)
      
      val real32a = make (Real32ArraySlice.base, Real32ArraySlice.copy)
      val real64a = make (Real64ArraySlice.base, Real64ArraySlice.copy)
   end

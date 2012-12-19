structure MakeVector :> MAKE_VECTOR =
   struct
      fun make (array, vector, z) (len, f) =
         let
            val a = array (len, z)
            val () = f a
         in
            vector a
         end
      
      val word8  = make (Word8Array.array,  Word8Array.vector,  0w0)
      val word16 = make (Word16Array.array, Word16Array.vector, 0w0)
      val word32 = make (Word32Array.array, Word32Array.vector, 0w0)
      val word64 = make (Word64Array.array, Word64Array.vector, 0w0)
      
      val real32 = make (Real32Array.array, Real32Array.vector, 0.0)
      val real64 = make (Real64Array.array, Real64Array.vector, 0.0)
   end

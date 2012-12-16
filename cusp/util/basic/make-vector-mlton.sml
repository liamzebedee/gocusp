structure MakeVector :> MAKE_VECTOR =
   struct
      fun make (cast, create) (len, f) =
         let
            val a = create len
            val () = f a
         in
            cast a
         end
      
      val cast8  = _prim "Array_toVector" : Word8Array.array  -> Word8Vector.vector;
      val cast16 = _prim "Array_toVector" : Word16Array.array -> Word16Vector.vector;
      val cast32 = _prim "Array_toVector" : Word32Array.array -> Word32Vector.vector;
      val cast64 = _prim "Array_toVector" : Word64Array.array -> Word64Vector.vector;
      
      val word8  = make (cast8,  Unsafe.Word8Array.create)
      val word16 = make (cast16, Unsafe.Word16Array.create)
      val word32 = make (cast32, Unsafe.Word32Array.create)
      val word64 = make (cast64, Unsafe.Word64Array.create)

      val cast32 = _prim "Array_toVector" : Real32Array.array -> Real32Vector.vector;
      val cast64 = _prim "Array_toVector" : Real64Array.array -> Real64Vector.vector;
      
      val real32 = make (cast32, Unsafe.Real32Array.create)
      val real64 = make (cast64, Unsafe.Real64Array.create)
   end

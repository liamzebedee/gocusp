signature STREAM =
   sig
      structure Key : SERIALIZABLE
      val length : int
      
      type stream = {
         key     : Key.t,
         counter : LargeInt.int
      } -> {
         f   : Word8ArraySlice.slice -> unit,
         mac : Word8ArraySlice.slice -> Word8Vector.vector
      }

      val decipher : stream
      val encipher : stream
   end

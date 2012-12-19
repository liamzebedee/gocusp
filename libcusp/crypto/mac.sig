signature MAC =
   sig
      structure Key   : SERIALIZABLE
      structure Nonce : SERIALIZABLE
      val length : int
      
      val f: { key   : Key.t,
               nonce : Nonce.t,
               text  : Word8ArraySlice.slice }
             -> Word8Vector.vector
   end

signature CRYPTO_EXTRA =
   sig
      include CRYPTO
      
      type full_negotiation = {
         macLen   : int,
         loopback : bool,
         encipher: LargeInt.int -> {
           f   : Word8ArraySlice.slice -> unit,
           mac : Word8ArraySlice.slice -> Word8Vector.vector
         },
         decipher : LargeInt.int -> {
           f   : Word8ArraySlice.slice -> unit,
           mac : Word8ArraySlice.slice -> Word8Vector.vector
         }
      }
      
      type half_negotiation = {
         A : Word8Vector.vector,
         X : Word8Vector.vector,
         symmetric : { suite : Suite.Symmetric.suite,
                       B : Word8ArraySlice.slice, 
                       Y : Word8ArraySlice.slice } -> full_negotiation
      }
      
      val publickeyInfo : Suite.PublicKey.suite -> {
         publicLength    : int,
         ephemeralLength : int,
         parse : { B : Word8ArraySlice.slice } -> PublicKey.t
      }
      
      val publickey : {
         suite   : Suite.PublicKey.suite,
         key     : PrivateKey.t,
         entropy : int -> Word8Vector.vector
      } -> half_negotiation
   end

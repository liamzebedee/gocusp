structure Crypto =
   struct
      open Crypto
      
      fun crc32 (k1, k2) =
         let
            val k1 = PackWord64Little.subVec (k1, 0)
            val k2 = PackWord64Little.subVec (k2, 0)
            open Serial
            val { writeVector, ... } = pickle `word64l `word64l $
            fun mac (k1, k2) _ = 
               let
                  open Serial
                  val v = writeVector (fn v => v) k1 k2
               in
                  v
               end
         in {
            macLen   = 16,
            loopback = k1 = k2,
            encipher = fn _ => { f = fn _ => (), mac = mac (k1, k2) },
            decipher = fn _ => { f = fn _ => (), mac = mac (k2, k1) }
            }
         end

      structure Poly1305AES =
         Counter(structure Cipher = AES128
                 structure Mac = Poly1305)
      
      val { length=poly1305AES_length, fromVector=poly1305AES_parser, ... } =
         Serial.methods Poly1305AES.Key.t
      
      fun poly1305aes (k1, k2) =
         let
            val k1' = poly1305AES_parser k1
            val k2' = poly1305AES_parser k2
         in {
            macLen   = Poly1305AES.length,
            loopback = k1 = k2,
            encipher = fn c => Poly1305AES.encipher { key = k1', counter = c },
            decipher = fn c => Poly1305AES.decipher { key = k2', counter = c }
            }
         end
      
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
      
      fun symmetricLength suite = 
         if suite = Suite.Symmetric.crc32       then 8 else
         if suite = Suite.Symmetric.poly1305aes then poly1305AES_length else
         raise Fail "key length for non-existant symmetric suite requested"
      
      fun symmetric (suite, k1, k2) =
         if suite = Suite.Symmetric.crc32       then crc32       (k1, k2) else
         if suite = Suite.Symmetric.poly1305aes then poly1305aes (k1, k2) else
         raise Fail "methods for non-existant symmetric suite requested"
   end

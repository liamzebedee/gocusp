functor Counter(structure Cipher : CIPHER
                structure Mac : MAC)
   :> STREAM =
   struct
      structure Key =
         struct
            type t = Cipher.Key.t * Mac.Key.t
            
            local
               open Serial
            in
               val t = aggregate tuple2 `Cipher.Key.t `Mac.Key.t $
            end
            
            fun eq ((ac, am), (bc, bm)) =
               Cipher.Key.eq (ac, bc) andalso Mac.Key.eq (am, bm)
            
            fun hash (c, m) = Cipher.Key.hash c o Mac.Key.hash m
            fun toString (c, m) = Cipher.Key.toString c ^ Mac.Key.toString m
         end
      
      val length = Mac.length
      val counterOff = Cipher.length div 4 - 1
      
      type stream = {
         key     : Key.t,
         counter : IntInf.int
      } -> {
         f   : Word8ArraySlice.slice -> unit,
         mac : Word8ArraySlice.slice -> Word8Vector.vector
      }
      
      val { writeSlice, ... } = Serial.methods (Serial.intinfl Cipher.length)
      val { parseSlice, length=nonceLength, ... } = Serial.methods Mac.Nonce.t
      
      exception BadCryptographicComposition
      val () =
         if nonceLength > Cipher.length 
         then raise BadCryptographicComposition
         else ()
      
      fun encipher { key=(kc, km), counter } =
         let
            val rawpad = Word8Array.array (Cipher.length, 0w0)
            val cipher = Word8Array.array (Cipher.length, 0w0)
            val () = writeSlice (Word8ArraySlice.full rawpad, counter)
            
            fun pad i =
               let
                  val () = 
                     PackWord32Little.update (rawpad, counterOff, LargeWord.fromInt i)
               in
                  Cipher.f { key = kc, plain = rawpad, cipher = cipher }
               end
            
            fun xor s =
               let
                  open Serial
                  val w32x4l = aggregate tuple4 `word32l `word32l `word32l `word32l $
                  val { parseSlice, writeSlice, ... } = methods w32x4l
                  val (w0, w1, w2, w3) = parseSlice s
                  val (x0, x1, x2, x3) = parseSlice (Word8ArraySlice.full cipher)
                  val op ^ = Word32.xorb
               in
                  writeSlice (s, (w0 ^ x0, w1 ^ x1, w2 ^ x2, w3 ^ x3))
               end
            
            val xorTail =
               Word8ArraySlice.modifyi
               (fn (i, w) => Word8.xorb (Word8Array.sub (cipher, i), w))
            
            fun crypt text =
               let
                  val len = Word8ArraySlice.length text
                  val full = len div Cipher.length
                  fun slice (i, len) =
                     Word8ArraySlice.subslice (text, i * Cipher.length, len)
                  
                  fun loop i =
                     if i < full then 
                        (pad i; xor (slice (i, SOME Cipher.length)); loop (i+1))
                     else if i * Cipher.length < len then 
                        (pad i; xorTail (slice (i, NONE)))
                     else
                        ()
               in
                  loop 0
               end
         in {
            f = crypt,
            mac = fn text =>
               let
                  val () = pad ~1
                  val nonce = parseSlice (Word8ArraySlice.full cipher)
               in
                  Mac.f { key = km, nonce = nonce, text = text } 
               end
            }
         end
      
      val decipher = encipher
   end

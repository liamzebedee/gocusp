structure Poly1305FFI :> MAC =
   struct
      val length = 16
      
      structure Nonce = Key(val length = length)
      structure Key =
         struct
            open Nonce
            
            val clamp =
               Word8Vector.fromList [
                  0wxff, 0wxff, 0wxff, 0wx0f, 
                  0wxfc, 0wxff, 0wxff, 0wx0f,
                  0wxfc, 0wxff, 0wxff, 0wx0f,
                  0wxfc, 0wxff, 0wxff, 0wx0f ]
            fun andb (i, x) = Word8.andb (Word8Vector.sub (clamp, i), x)
            
            val t = Serial.map {
               load  = Word8Vector.mapi andb,
               store = fn x => x,
               extra = fn () => ()
            } t
         end
      
      val raw =
         _import "poly1305_offs" public : 
            Word8Array.array * 
            Word8Vector.vector * 
            Word8Vector.vector *
            Word8Array.array * int * int -> unit;

      fun f { key, nonce, text } =
         let
            val output = Word8Array.array (length, 0w0)
            val (text, textoff, textlen) = Word8ArraySlice.base text
            val () = raw (output, key, nonce, text, textoff, textlen)
         in
            Word8Array.vector output
         end
   end

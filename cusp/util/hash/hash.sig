(* The idea is to compose hash functions like this:
 *   type me = Real64.real * Word32.word * int
 *   fun hashMeFn (x, w, i) = Hash.real64 x o Hash.word32 w o Hash.int i
 *   val hashMeFn : (me, 'a) Hash.function
 * Then the end final hash function can be constructed with:
 *   val hashMe : me Lookup3.t = Lookup3.make hashMeFn
 *)
signature HASH =
   sig
      datatype 'b state = S of 'b * ('b * Word32.word -> 'b state)
      type ('a, 'b) function = 'a -> 'b state -> 'b state
      
      val word:   (word,        'b) function            
      val word8:  (Word8.word,  'b) function
      val word16: (Word16.word, 'b) function
      val word32: (Word32.word, 'b) function
      val word64: (Word64.word, 'b) function

      val int:   (int,       'b) function      
      val int8:  (Int8.int,  'b) function
      val int16: (Int16.int, 'b) function
      val int32: (Int32.int, 'b) function
      val int64: (Int64.int, 'b) function
      
      val real:   (real,        'b) function
      val real32: (Real32.real, 'b) function
      val real64: (Real64.real, 'b) function
      
      val string: (string, 'b) function
      val bool:   (bool,   'b) function
      
      val word8vector : (Word8Vector.vector, 'b) function
      val iterator : ('a, 'b) function -> ('a Iterator.t, 'b) function
   end

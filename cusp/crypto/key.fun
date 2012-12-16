functor Key(val length: int) : SERIALIZABLE =
   struct
      type t = Word8Vector.vector
      
      val eq = op =
      val t = Serial.vector (Serial.word8, length)
      val hash = Hash.word8vector
      val toString = WordToString.fromBytes
   end

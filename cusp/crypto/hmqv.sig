signature HMQV =
   sig
      structure CyclicGroup : CYCLIC_GROUP
      
      (* Create two keys of the requested length *)
      val compute : {
         length : int, 
         a : LargeInt.int,
         x : LargeInt.int,
         A : CyclicGroup.t,
         B : CyclicGroup.t,
         X : CyclicGroup.t,
         Y : CyclicGroup.t } -> Word8Vector.vector * Word8Vector.vector
   end

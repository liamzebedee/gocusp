signature RANDOM_BASE =
   sig
      type t
      
      val new : Word32.word -> t
      val rand : t -> Word32.word
   end

signature RANDOM =
   sig
      type t
      
      val new : Word32.word -> t
      
      exception NonPositiveBound
            
      (* NONE => full precision random word.
       * SOME x => random word between [0,x)
       *           if x = 0, raises NonPositiveBound
       *)
      val word : t * word option -> word
      val word8 : t * Word8.word option -> Word8.word  
      val word16 : t * Word16.word option -> Word16.word      
      val word32 : t * Word32.word option -> Word32.word      
      val word64 : t * Word64.word option -> Word64.word
      
      (* Random integers always have a limit *)
      val int : t * int -> int
      val int8 : t * Int8.int -> Int8.int
      val int16 : t * Int16.int -> Int16.int  
      val int32 : t * Int32.int -> Int32.int  
      val int64 : t * Int64.int -> Int64.int
      
      (* Random number between [0, 1) *)
      val real : t -> real
      val real32 : t -> Real32.real  
      val real64 : t -> Real64.real
        
      val bool : t -> bool
      
      (* Normally distributed random variable (mean 0, variance 1) *)
      val normal : t -> real
      (* Exponentially distributed random variable (mean 1) *)
      val exponential : t -> real
      (* Poisson random variable *)
      (* val poisson : t * real -> real ... hard to do well *) 
   end

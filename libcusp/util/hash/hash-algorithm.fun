functor HashAlgorithm(Base : HASH_PRIMITIVE)
   :> HASH_ALGORITHM where type input = Base.initial
                     where type output = Base.final =
   struct
      type state = Base.state
      type input = Base.initial
      type output = Base.final
      
      type 'a t = 'a * input -> output
      
      fun make f (x, init) =
            let
            val state = Base.start init
            val Hash.S (state, _) = f x state
         in
            Base.stop state
         end 
   end

functor InPlaceHeap(Value : IN_PLACE_ARGUMENT) 
   :> IN_PLACE_HEAP where type Value.t = Value.t =
   struct
      structure Value = Value
       
      type t = Value.t Stack.t
      
      fun new () = Stack.new { nill = Value.nill }
      
      val { fixTooBig, fixTooSmall, ... } =
         makeHeapOps { store = Stack.update, 
                       extract = Stack.sub, 
                       less = Value.< }        
      
      fun pop h =
         case Stack.pop h of
            NONE => NONE
          | (SOME x) =>
               if Stack.length h = 0 then SOME x else
               SOME (Stack.sub (h, 0)) before 
               fixTooBig (h, 0, Stack.length h, x)
       
      fun peek h =
         if Stack.length h = 0 then NONE else SOME (Stack.sub (h, 0))             
       
      fun push (h, x) =
         fixTooSmall (h, Stack.push (h, x), Stack.length h, x)
   end

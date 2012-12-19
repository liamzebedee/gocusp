structure Stack :> RAM_STACK =
   struct
      type 'a t = { stack: 'a array, use: int, nill: 'a } ref
      
      fun new { nill } = 
         ref { stack = (Array.tabulate (4, fn _ => nill)),
               use = 0,
               nill = nill }
      
      fun push (s as ref { stack, use, nill }, x) =
         let
            fun copy i = if i < use then Array.sub (stack, i) else nill
            val stack = if use = Array.length stack
                        then Array.tabulate (Array.length stack * 2, copy)
                        else stack
         in
            Array.update (stack, use, x)
            ; s := { stack = stack, use = use + 1, nill = nill }
            ; use
         end
      
      fun pop (s as ref { stack, use, nill }) =
         if use = 0 then NONE else
         let
            fun copy i = Array.sub (stack, i)
            val stack = if use*4 = Array.length stack
                        then Array.tabulate (use*2, copy)
                        else stack
            val use = use - 1
            val out = Array.sub (stack, use)
         in
            s := { stack = stack, use = use, nill = nill }
            ; Array.update (stack, use, nill)
            ; SOME out
         end
      
      fun length (ref { stack=_, use, nill=_ }) = use
      fun isEmpty (ref { stack=_, use, nill=_ }) = use = 0
      
      fun sub (ref { stack, use=_ , nill=_ }, i) = 
         Array.sub (stack, i)
      
      fun update (ref { stack, use=_, nill=_ }, i, v) = 
         Array.update (stack, i, v)
      
      fun iterator (ref { stack, use, nill=_ }) =
         Iterator.fromArraySlice (ArraySlice.slice (stack, 0, SOME use))
   end

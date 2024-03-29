fun makeHeapOps { store : 'a * int * 'b -> unit, 
                  extract : 'a * int -> 'b, 
                  less : 'b * 'b -> bool } =
   let
      fun fixTooBig (array, hole_index, end_index, record) =
         let
            val left_index = hole_index*2 + 1
            val right_index = left_index + 1
         in
            (* Recursion: two children *)
            if right_index < end_index
            then let val left = extract (array, left_index)
                     val right = extract (array, right_index)
                     val (small_index, small) =
                        if less (left, right)
                        then (left_index, left)
                        else (right_index, right)
                 in  if less (record, small)
                     then store (array, hole_index, record)
                     else (store (array, hole_index, small)
                           ; fixTooBig (array, small_index, end_index, record))
                 end
            (* Base case: one child *)
            else if right_index = end_index
                 then let val left = extract (array, left_index)
                 in  if less (record, left)
                     then store (array, hole_index, record)
                     else (store (array, hole_index, left);
                           store (array, left_index, record))
                 end
            (* Base case: no children *)
            else store (array, hole_index, record)
         end
      
      fun fixTooSmall (array, hole_index, end_index, record) =
         if hole_index = 0 then store (array, hole_index, record) else
         let
            val parent_index = (hole_index-1) div 2
            val parent = extract (array, parent_index)
         in
            if less (parent, record)
            then store (array, hole_index, record)
            else (store (array, hole_index, parent)
                 ; fixTooSmall (array, parent_index, end_index, record))
         end
       
      fun checkInvariant (array, len) =
         let
            fun loop i =
               if i >= len then () else
               let
                  val parent_index = (i-1) div 2
                  val parent = extract (array, parent_index)
                  val child = extract (array, i)
                  val () =
                     if less (child, parent) then raise Fail ("Heap invariant violated at " ^ Int.toString i ^ "/" ^ Int.toString len ^ "\n") else () 
               in
                  loop (i+1)
               end
         in
            loop 1
         end         
   in
      { fixTooBig = fixTooBig, fixTooSmall = fixTooSmall, checkInvariant = checkInvariant }
   end

structure Iterator :> ITERATOR =
   struct
      datatype 'a t = EOF | SKIP of (unit -> 'a t) | VALUE of 'a * (unit -> 'a t)
      
      fun getItem EOF = NONE
        | getItem (SKIP r) = getItem (r ())
        | getItem (VALUE (x, r)) = SOME (x, r ())
      
      fun null x = not (Option.isSome (getItem x))
             
      fun map _ EOF = EOF
        | map f (SKIP r) = SKIP (fn () => map f (r ()))
        | map f (VALUE (x, r)) = VALUE (f x, fn () => map f (r ())) 
      
      fun mapPartialWith _ (EOF, _) = EOF
        | mapPartialWith f (SKIP r, w) = SKIP (fn () => mapPartialWith f (r (), w))
        | mapPartialWith f (VALUE (x, r), w) =
              case f (x, w) of
                 (NONE, w) => SKIP (fn () => mapPartialWith f (r (), w))
               | (SOME y, w) => VALUE (y, fn () => mapPartialWith f (r (), w))
      
      fun mapPartial f i = mapPartialWith (fn (x, ()) => (f x, ())) (i, ())
      fun filter f = mapPartial (fn x => if f x then SOME x else NONE)
      
      fun push (x, r) = VALUE (x, fn () => r)
      
      fun @ (EOF, s) = s
        | @ (SKIP r, s) = SKIP (fn () => r () @ s)
        | @ (VALUE (x, r), s) = VALUE (x, fn () => r () @ s) 
       
      fun concat EOF = EOF
        | concat (SKIP r) = SKIP (fn () => concat (r ()))
        | concat (VALUE (s, r)) =
              let
                 fun concatSub EOF = SKIP (fn () => concat (r ()))
                   | concatSub (SKIP r) = SKIP (fn () => concatSub (r ()))
                   | concatSub (VALUE (x, r)) = VALUE (x, fn () => concatSub (r ()))
              in
                 concatSub s
              end

      fun truncate _ EOF = EOF
        | truncate f (SKIP r) = SKIP (fn () => truncate f (r ()))
        | truncate f (VALUE (x, r)) = 
            if f x then EOF else 
            VALUE (x, fn () => truncate f (r ()))
            
      fun app _ EOF = ()
        | app f (SKIP r) = app f (r ())
        | app f (VALUE (x, r)) = let val () = f x in app f (r ()) end
      
      fun fold _ a EOF = a
        | fold f a (SKIP r) = fold f a (r ())
        | fold f a (VALUE (x, r)) = fold f (f (x, a)) (r ())
      
      fun find _ EOF = NONE
        | find f (SKIP r) = find f (r ())
        | find f (VALUE (x, r)) =
              if f x then SOME x else find f (r ())
      
      fun exists f = isSome o find f
      
      fun collate _ (EOF, EOF) = EQUAL
        | collate f (SKIP r, s) = collate f (r (), s)
        | collate f (r, SKIP s) = collate f (r, s ())
        | collate _ (EOF, _) = LESS 
        | collate _ (_, EOF) = GREATER
        | collate f (VALUE (x, r), VALUE (y, s)) =
              case f (x, y) of
                 EQUAL => collate f (r (), s ())
               | LESS => LESS
               | GREATER => GREATER               
      
      fun length (r, EOF) = r
        | length (x, SKIP r) = length (x, r ())
        | length (x, VALUE (_, r)) = length (x+1, r ())
      val length = fn l => length (0, l)
      
      fun nth (EOF, _) = raise Subscript
        | nth (SKIP r, i) = nth (r (), i)
        | nth (VALUE (x, _), 0) = x
        | nth (VALUE (_, r), i) = nth (r (), i - 1)
      val nth = fn (r, i) =>  if i < 0 then raise Subscript else nth (r, i)
      
      fun take (_, 0) = []
        | take (EOF, _) = raise Subscript
        | take (SKIP r, i) = take (r (), i)
        | take (VALUE (x, r), i) = x :: take (r (), i - 1)
      val take = fn (r, i) => if i < 0 then raise Subscript else take (r, i)
      
      fun drop (r, 0) = r
        | drop (EOF, _) = raise Subscript
        | drop (SKIP r, i) = drop (r (), i)
        | drop (VALUE (_, r), i) = drop (r (), i - 1)
      val drop = fn (r, i) => if i < 0 then raise Subscript else drop (r, i) 
      
      fun fromList [] = EOF
        | fromList (x :: r) = VALUE (x, fn () => fromList r)
      
      fun fromSubstring s =
         case Substring.getc s of
            NONE => EOF
          | SOME (c, s) => VALUE (c, fn () => fromSubstring s) 
      
      fun fromVectorSlice s =
         case VectorSlice.getItem s of
            NONE => EOF
          | SOME (x, s) => VALUE (x, fn () => fromVectorSlice s)         

      fun fromVectorSlicei (s, i) =
         case VectorSlice.getItem s of
            NONE => EOF
          | SOME (x, s) => VALUE ((i, x), fn () => fromVectorSlicei (s, i+1))
      val fromVectorSlicei = fn s => fromVectorSlicei (s, 0)

      fun fromArraySlice s =
         case ArraySlice.getItem s of
            NONE => EOF
          | SOME (x, s) => VALUE (x, fn () => fromArraySlice s)

      fun fromArraySlicei (s, i) =
         case ArraySlice.getItem s of
            NONE => EOF
          | SOME (x, s) => VALUE ((i, x), fn () => fromArraySlicei (s, i+1))
      val fromArraySlicei = fn s => fromArraySlicei (s, 0)

      (* Uses the stack... could have also done List.rev o Iterator.fold *)
      fun toList EOF = []
        | toList (SKIP r) = toList (r ())
        | toList (VALUE (x, r)) = x :: toList (r ())
      
      fun fetch x =
         let
            val y = ref x
         in
            fn _ => 
               case getItem (!y) of
                  SOME (x, r) => (y := r; x)
                | NONE => raise Fail "unreachable EOF in Iterator.fetch"                 
         end
         
      fun toString x = CharVector.tabulate (length x, fetch x)
      fun toVector x = Vector.tabulate (length x, fetch x)
      fun toArray x = Array.tabulate (length x, fetch x)
      
      fun fromInterval { start, stop, step } =
         if start < stop
            then VALUE (start, fn () => fromInterval { start = start + step,
                                                       stop = stop,
                                                       step = step })
         else EOF
   end

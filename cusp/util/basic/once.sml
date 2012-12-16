(* MLton is not multi-threaded *)
structure OncePerThread :> ONCE =
   struct
      type 'a t = 'a
      
      fun new f = f ()
      fun get (x, f) = f x
   end

structure OncePerEntry :> ONCE =
   struct
      type 'a t = 'a option ref * (unit -> 'a)
      
      fun new f = (ref NONE, f)
      
      fun get ((box as ref (SOME x), _), g) = 
            let
               val () = box := NONE
               val out = g x
               val () = box := SOME x
            in
               out
            end
        | get ((box, f), g) =
              let
                 val x = f ()
                 val out = g x
                 val () = box := SOME x
              in
                 out
              end 
   end

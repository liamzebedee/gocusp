structure Signal :> SIGNAL =
   struct
      type 'a t = 'a -> unit
      
      fun new f = f
      fun set f = f
      
      fun newBox x =
         let
            val box = ref x
         in
            (fn x => box := x, box)
         end
      
      fun map g f x = f (g x)
      
      fun combine (f, g) x = 
         let
            val () = f x
         in
            g x
         end
         
      fun all l x = List.app (fn f => f x) l 
      
      fun split (f, c, (ig, ih)) = 
         let
            val z = ref (ig, ih)
            fun report () = f (c (!z))
            val () = report ()
         in
            (fn x => (z := (x, #2 (!z)); report ()), 
             fn x => (z := (#1 (!z), x); report ()))
         end
            
      fun dampen (eq, i) f =
         let
            val x = ref i
            val () = f i
         in
            fn y => if eq (!x, y) then () else (x := y; f y)
         end 
   end

(*
datatype evil = FOO of evil Signal.t
fun handler Signal.OFF = () 
  | handler (Signal.ON (FOO self)) = Signal.setON (self, FOO self)
val x = Signal.new handler
val () = Signal.setON (x, FOO x)
*)

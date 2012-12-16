signature HEAP =
   sig
      structure Key : ORDER
      type 'a t
      
      val new : unit -> 'a t
      
      val push : 'a t * Key.t * 'a -> unit
      val pop  : 'a t -> (Key.t * 'a) option
      val peek : 'a t -> (Key.t * 'a) option
      val size : 'a t -> int
      val isEmpty : 'a t -> bool
      
      (* Only pop the value if the function returns true for it *)
      val popIf : 'a t * (Key.t * 'a -> bool) -> (Key.t * 'a) option
      (* popBounded (x, k) = popIf (x, fn (l, _) => l <= k) *)
      val popBounded : 'a t * Key.t -> (Key.t * 'a) option
   end

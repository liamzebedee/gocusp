signature STACK =
   sig
      type 'a t
      
      val new: { nill : 'a } -> 'a t
      (* returns index of pushed element (equals length () - 1) *)
      val push: 'a t * 'a -> int
      val pop: 'a t -> 'a option
      val length : 'a t -> int
      val isEmpty : 'a t -> bool
      
      (* Walk the stack records from the bottom to the top (ie: backwards) 
       * After the stack is modified, results from the iterator are undefined.
       *)
      val iterator : 'a t -> 'a Iterator.t
   end

signature RAM_STACK =
   sig
      include STACK
      
      val sub : 'a t * int -> 'a
      val update : 'a t * int * 'a -> unit
   end

(* A double-ended queue.
 * You can use it like a queue with pushBottom and pop.
 * However, you can also use it like a stack with pushTop and pop.
 *)
signature QUEUE =
   sig
      type 'a t
      
      val empty: 'a t
      
      val peek: 'a t -> 'a t * 'a option
      val pop: 'a t  -> 'a t * 'a option
      val isEmpty: 'a t -> bool
      
      val pushFront : 'a t * 'a -> 'a t
      val pushBack  : 'a t * 'a -> 'a t
      
      (* Walk a snapshot of the contents of the queue.
       * Further modification of the queue is not reflected by the iterators.
       *)
      
      (* No specific order, but no memory cost *)
      val unordered: 'a t -> 'a Iterator.t
      
      (* Can use time+space proportional to size *)
      val forward:   'a t -> 'a Iterator.t
      val backward:  'a t -> 'a Iterator.t
   end

signature IMPERATIVE_QUEUE =
   sig
      type 'a t
      
      val new: unit -> 'a t
      
      val peek: 'a t -> 'a option
      val pop: 'a t -> 'a option
      val isEmpty: 'a t -> bool
      
      val pushFront : 'a t * 'a -> unit
      val pushBack  : 'a t * 'a -> unit
      
      val unordered: 'a t -> 'a Iterator.t
      val forward:   'a t -> 'a Iterator.t
      val backward:  'a t -> 'a Iterator.t
   end

signature TREE =
   sig
      structure Key : ORDER
      type 'a t
      
      (* This is a functional multimap tree.
       *   Inserts/removes create a new tree with the change.
       *   The original tree remains unchanged.
       *   Multiple values can be stored with the same key.
       *   Remove removes all values with the named key. 
       *)
      
      val empty: 'a t 
      val insert: 'a t * Key.t * 'a -> 'a t
      val find: 'a t * Key.t -> 'a list
      val remove: 'a t * Key.t -> 'a t * (Key.t * 'a) option
      val isEmpty: 'a t -> bool
      
      datatype order = POST_ORDER | PRE_ORDER | IN_ORDER 
      val app: order -> (Key.t * 'a -> unit) -> 'a t -> unit
      val map: order -> (Key.t * 'a -> 'b) -> 'a t -> 'b t
      val fold: order -> (Key.t * 'a * 'b -> 'b) -> 'b -> 'a t -> 'b
      
      val first: 'a t -> (Key.t * 'a) option
       val last: 'a t -> (Key.t * 'a) option
      
      (* Walk a snapshot of the contents of the tree.
       * Further modification of the tree are not reflected by the iterators.
       *)
      
      (* Retrieve an iterator to walk a subset of the tree. *)
      type range = { left: Key.t option, right: Key.t option }
      
      (* Returns [left, right) in ascending order. *)
      val forward: 'a t -> range -> (Key.t * 'a) Iterator.t
      (* Returns [left, right) in descending order. *)
      val backward: 'a t -> range -> (Key.t * 'a) Iterator.t
   end
  
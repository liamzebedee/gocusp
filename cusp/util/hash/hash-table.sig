signature HASH_KEY =
   sig
      type t
      
      val eq : t * t -> bool
      val hash : (t, 'b) Hash.function
   end

signature HASH_TABLE =
   sig
      type 'a t
      structure Key : HASH_KEY
      
      exception KeyExists
      exception KeyDoesNotExist
      
      val new : unit -> 'a t
      val find : 'a t * Key.t -> 'a option
      val size : 'a t -> int
      val isEmpty: 'a t -> bool
      
      val add    : 'a t * Key.t * 'a -> unit (* raises KeyExists *)
      val update : 'a t * Key.t * 'a -> unit (* raises KeyDoesNotExist *)
      val remove : 'a t * Key.t -> unit      (* raises KeyDoesNotExist *) 
      
      (* Update a record if it exists and return the old value.
       * This is mostly useful if the hash function is expensive. *)
      val modify : 'a t * Key.t * ('a -> 'a) -> 'a option
      
      val app : (Key.t * 'a -> unit) -> 'a t -> unit
      val map : (Key.t * 'a -> 'b) -> 'a t -> 'b t
      
      (* Walk the table in an arbitrary order *)
      val iterator : 'a t -> (Key.t * 'a) Iterator.t
   end

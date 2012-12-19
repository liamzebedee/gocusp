
signature ID_BUCKET =
   sig
      type 'a t

      (* Creates a new id-bucket *)
      val new: unit -> 'a t

      (* Retrieve item from given index *)
      val sub : 'a t * int -> 'a option

      (* Add item, return its index *)
      val alloc : 'a t * 'a -> int

      (* Replace an item, raise AlreadyFree if the specified cell is free *)
      val replace : 'a t * int * 'a -> unit

      (* Remove item at given index, raise AlreadyFree if the specified cell is already free *)
      val free : 'a t * int -> unit
      exception AlreadyFree

      (* Walk records in the bucket in no particular order.
       * After the bucket is modified, results from the iterator are undefined.
       *)
      val iterator : 'a t -> (int * 'a) Iterator.t
   end

signature ITERATOR =
   sig
      datatype 'a t = EOF | SKIP of (unit -> 'a t) | VALUE of 'a * (unit -> 'a t)
      
      (* Fetch one item *)
      val getItem: 'a t -> ('a * 'a t) option
      val null: 'a t -> bool
      
      (* Constant time iterator operations *)
      val map: ('a -> 'b) -> 'a t -> 'b t
      val mapPartial: ('a -> 'b option) -> 'a t -> 'b t
      val mapPartialWith: ('a * 'w -> 'b option * 'w) -> 'a t * 'w -> 'b t
      val filter: ('a -> bool) -> 'a t -> 'a t
      
      val @ : 'a t * 'a t -> 'a t
      val concat: 'a t t -> 'a t
      val push: 'a * 'a t -> 'a t
      val truncate: ('a -> bool) -> 'a t -> 'a t
      
      (* Amortized linear time *)
      val app: ('a -> unit) -> 'a t -> unit
      val fold: ('a * 'b -> 'b) -> 'b -> 'a t -> 'b
      val exists: ('a -> bool) -> 'a t -> bool
      val find: ('a -> bool) -> 'a t -> 'a option
      val collate: ('a * 'b -> order) -> 'a t * 'b t -> order 
      
      (* These take linear time (even if the underlying representation is faster) *)
      val length: 'a t -> int
      val nth: 'a t * int -> 'a
      
      (* Cost proportional to second parameter *)
      val take: 'a t * int -> 'a list
      val drop: 'a t * int -> 'a t
      
      (* Conversions between some common data types *)
      val fromList: 'a list -> 'a t
      val fromSubstring: Substring.substring -> char t
      val fromVectorSlice: 'a VectorSlice.slice -> 'a t
      val fromVectorSlicei: 'a VectorSlice.slice -> (int * 'a) t
      val fromArraySlice: 'a ArraySlice.slice -> 'a t
      val fromArraySlicei: 'a ArraySlice.slice -> (int * 'a) t
      
      val toList: 'a t -> 'a list      
      val toString: char t -> string
      val toVector: 'a t -> 'a vector
      val toArray: 'a t -> 'a array
      
      (* Surprisingly useful as a means to make a loop *)
      val fromInterval: { start : int, stop : int, step : int } 
                        -> int t
   end

signature IN_PLACE_ARGUMENT =
   sig
      include ORDER
      val nill : t
   end

signature IN_PLACE_HEAP =
   sig
      structure Value : IN_PLACE_ARGUMENT
      type t
      
      val new : unit -> t
      
      val push : t * Value.t -> unit
      val pop  : t -> Value.t option
      val peek : t -> Value.t option
   end

   
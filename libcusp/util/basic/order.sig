signature ORDER =
   sig
      type t
      val < : t * t -> bool
   end

signature ORDER_EXTENDED =
   sig
      include ORDER
      val min : t * t -> t
      val max : t * t -> t
      val >   : t * t -> bool
      val >=  : t * t -> bool
      val <=  : t * t -> bool
   end

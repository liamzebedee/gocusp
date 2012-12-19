signature SERIALIZABLE =
   sig
      type t
      
      val t : (t, t, unit) Serial.t
      val eq : t * t -> bool
      
      val toString : t -> string
      val hash : (t, 'b) Hash.function
   end

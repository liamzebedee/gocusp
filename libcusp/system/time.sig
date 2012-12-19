signature TIME =
   sig
      include ORDER_EXTENDED
      
      val fromNanoseconds   : int -> t
      val fromMicroseconds  : int -> t
      val fromMilliseconds  : int -> t
      val fromSeconds       : int -> t
      val fromMinutes       : int -> t
      val fromHours         : int -> t
      val fromDays          : int -> t
      val fromSecondsReal32 : Real32.real -> t
      val fromNanoseconds64 : Int64.int -> t
      
      val toNanoseconds   : t -> LargeInt.int
      val toNanoseconds64 : t -> Int64.int
      val toDate          : t -> Date.date
      val toString        : t -> string
      val toMsString      : t -> string
      
      val zero    : t
      val maxTime : t
      
      val + : t * t -> t
      val - : t * t -> t
      
      val *   : t * int -> t
      val div : t * t -> int
      
      val divInt : t * int -> t
      
      (* Be wary of comparing timestamps. You probably shouldn't. *)
      val eq : t * t -> bool   

      (**
       * Returns current system time. You most probably want 
       * Event.time for timestamp of current event instead!
       *)
      val realTime : unit -> t      
      
      val hash: (t, 'a) Hash.function
   end

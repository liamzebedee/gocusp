structure SMLTime = Time (* Keep a backup of the SML idea of time *)

structure Time :> TIME =
   struct
      structure Base =
         struct
            type t = Int64.int
            val op < = Int64.<
         end
      structure Base = Order(Base)
      open Base
      
      val op + = Int64.+
      val op - = Int64.-
      val eq = op =
      
      fun fromNanoseconds   x = Int64.fromInt x
      fun fromMicroseconds  x = Int64.fromInt x * 1000
      fun fromMilliseconds  x = Int64.fromInt x * 1000000
      fun fromSeconds       x = Int64.fromInt x * 1000000000
      fun fromMinutes       x = Int64.fromInt x * 60000000000
      fun fromHours         x = Int64.fromInt x * 3600000000000
      fun fromDays          x = Int64.fromInt x * 86400000000000
      fun fromSecondsReal32 x =
         Int64.fromLarge (Real32.toLargeInt IEEEReal.TO_NEAREST (x * 1000000000.0))
      fun fromNanoseconds64 x = x
      
      val zero : Int64.int = 0
      val maxTime = valOf Int64.maxInt
      
      fun toNanoseconds x = Int64.toLarge x
      fun toNanoseconds64 x = x
      val toDate = Date.fromTimeUniv o Time.fromNanoseconds o toNanoseconds
      fun toString x =
         if x < 0 then ("~" ^ toString (~x)) else
         let
            val (n, x) = (x mod 1000000000, x div 1000000000)
            val (s, x) = (x mod 60, x div 60)
            val (m, x) = (x mod 60, x div 60)
            val (h, x) = (x mod 24, x div 24)
            val d = x
            val str = Int.toString o Int64.toInt
            val (d, h, m, s, n) =
               (str d, str h, str m, str s, str n)
            fun pad (x, i) = CharVector.tabulate (Int.- (i, String.size x), 
                                                  fn _ => #"0")
         in
            String.concat [d, " ", 
                           pad (h, 2), h, ":", 
                           pad (m, 2), m, ":", 
                           pad (s, 2), s, ".", 
                           pad (n, 9), n ]
         end
         
      fun toMsString x = 
         let
            val xUs = Real.fromLargeInt (Int64.toLarge (x div 1000))
            val xMs = xUs / 1000.0
         in
            Real.toString xMs
         end
         
      val realTime = Int64.fromLarge o Time.toNanoseconds o Time.now
      
      fun x * i = Int64.* (x, Int64.fromInt i)
      fun x div y = Int64.toInt (Int64.div (x, y))
      fun divInt (x, i) = Int64.div (x, Int64.fromInt i)
      
      val hash = Hash.int64
   end

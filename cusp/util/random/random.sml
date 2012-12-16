(* Globally used random number generator *)
structure Random = MersenneTwister
val random = 
   let
      val now = Time.now ()
      val now = Time.- (now, Time.fromSeconds (Time.toSeconds now))
      val x1 = Word32.fromInt (LargeInt.toInt (Time.toNanoseconds now))
      val pid = Word32.fromLarge o SysWord.toLarge o Posix.Process.pidToWord 
                o Posix.ProcEnv.getpid
      val x2 = pid ()
      val seed = Word32.orb (x1, 0w1) * x2
   in
      MersenneTwister.new seed
   end

signature FOLD =
   sig
      type ('a0, 'az, 'r) t
      type ('a0, 'ay, 'az, 'r) fold
      type ('a0, 'a1, 'ay, 'az, 'r) step0
      type ('b, 'a0, 'a1, 'ay, 'az, 'r) step1
      type ('b, 'c, 'a0, 'a1, 'ay, 'az, 'r) step2
      
      val fold : ('a0, 'ay, 'az) t -> ('a0, 'ay, 'az, 'r) fold
      val post : ('a0, 'ax, 'ay, 'r) fold * ('ay -> 'az) -> ('a0, 'ax, 'az, 'r) fold
      val step0 : ('a0 -> 'a1) -> ('a0, 'a1, 'ay, 'az, 'r) step0
      val step1 : ('b * 'a0 -> 'a1) -> ('b, 'a0, 'a1, 'ay, 'az, 'r) step1
      val step2 : ('b * 'c * 'a0 -> 'a1) -> ('b, 'c, 'a0, 'a1, 'ay, 'az, 'r) step2
   end

signature FOLDR =
   sig
      type ('a0, 'az, 'r) t
      type ('a0, 'ay, 'az, 'r) fold
      type ('a0, 'ax, 'ay, 'az, 'r) step0
      type ('b, 'ax, 'ay, 'a0, 'az, 'r) step1
      type ('b, 'c, 'ax, 'ay, 'a0, 'az, 'r) step2
      
      val fold : ('a0, 'ay, 'az) t -> ('a0, 'ay, 'az, 'r) fold
      val post : ('a0, 'ax, 'ay, 'r) fold * ('ay -> 'az) -> ('a0, 'ax, 'az, 'r) fold
      val step0 : ('ax -> 'ay) -> ('ax, 'ay, 'a0, 'az, 'r) step0
      val step1 : ('b * 'ax -> 'ay) -> ('b, 'ax, 'ay, 'a0, 'az, 'r) step1
      val step2 : ('b * 'c * 'ax -> 'ay) -> ('b, 'c, 'ax, 'ay, 'a0, 'az, 'r) step2
   end

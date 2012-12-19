(* No signal handling *)
structure SigPoll :> SIGPOLL =
   struct
      fun poll _ = ()
      fun ready _ = false
   end

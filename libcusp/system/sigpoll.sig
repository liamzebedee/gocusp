(* An API to access signal handling *)
signature SIGPOLL =
   sig
      val poll  : Posix.Signal.signal * bool -> unit
      val ready : Posix.Signal.signal -> bool
   end

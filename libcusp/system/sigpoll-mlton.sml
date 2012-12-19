structure SigPoll :> SIGPOLL =
   struct
      val sigpoll   = _import "bs_sigpoll"   public : Word32.word -> unit;
      val sigunpoll = _import "bs_sigunpoll" public : Word32.word -> unit;
      val sigready  = _import "bs_sigready"  public : Word32.word -> Word32.word;
      
      val toWord = Word32.fromLarge o SysWord.toLarge o Posix.Signal.toWord
      
      val poll = fn
         (s, true)  => sigpoll (toWord s)
       | (s, false) => sigunpoll (toWord s)
      
      fun ready s = sigready (toWord s) <> 0w0
   end

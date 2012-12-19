structure Main :> MAIN =
   struct
      structure Event = Event()
      
      (* Catch the clock up to the time the program is loaded *)
      val () = Event.runTill (Time.realTime ())
      
      datatype rehook = UNHOOK | REHOOK

      structure Signal =
         struct
            type t = Posix.Signal.signal
            val eq : t * t -> bool = op =
            fun hash w = (Hash.word32 o Word32.fromLarge o SysWord.toLarge o Posix.Signal.toWord) w
         end
      structure SigMap = HashTable(Signal)
      val sigmap = SigMap.new ()
      
      fun unhook (signal, r) =
         let
            val out = not (Ring.isSolo r)
            val () = Ring.remove r
            val ring = valOf (SigMap.find (sigmap, signal))
            val () = 
               if not (Ring.isSolo ring) then () else
               (SigPoll.poll (signal, false)
                ; SigMap.remove (sigmap, signal))
         in
            out
         end
      
      fun runHandler signal =
         case SigMap.find (sigmap, signal) of
            NONE => ()
          | SOME r =>
            let
               val cbs = Iterator.toList (Ring.iterator r)
               fun exec r =
                  if Ring.isSolo r then () else 
                  case Ring.get r () of
                     REHOOK => ()
                   | UNHOOK => ignore (unhook (signal, r))
            in
               List.app exec cbs
            end
      
      fun signal (signal, handler) =
         let
            val ring =
               case SigMap.find (sigmap, signal) of
                  SOME r => r
                | NONE => 
                  let
                     val ring = Ring.new (fn () => REHOOK)
                     val () = SigPoll.poll (signal, true)
                     val () = SigMap.add (sigmap, signal, ring)
                  in
                     ring
                  end
            
            val r = Ring.add (ring, handler)
         in
            fn () => unhook (signal, r)
         end
      
      val readSockets  = Ring.new (NONE, fn () => REHOOK)
      val writeSockets = Ring.new (NONE, fn () => REHOOK)
      
      fun registerSocketForRead (sock, cb) =
         let
            val r = Ring.add (readSockets, (SOME sock, cb))
         in
            fn () => not (Ring.isSolo r) before Ring.remove r
         end
      
      fun registerSocketForWrite (sock, cb) =
         let
            val r = Ring.add (writeSockets, (SOME sock, cb))
         in
            fn () => not (Ring.isSolo r) before Ring.remove r
         end
      
      fun wait timeout =
         let
            open Iterator
            
            val smlTime = SMLTime.fromNanoseconds o Time.toNanoseconds
            val timeout = Option.map smlTime timeout
            val socks = toList o mapPartial #1 o map Ring.get o Ring.iterator 
            val { rds, wrs, exs=_ } =
               Socket.select { rds = socks readSockets,
                               wrs = socks writeSockets,
                               exs = [],
                               timeout = timeout }
               handle exn as OS.SysErr (_, SOME code) =>
               if code = Posix.Error.intr
               then { rds = [], wrs = [], exs = [] }
               else raise exn
            
            fun pickReady (_, []) = (NONE, [])
              | pickReady (r, ready as head :: tail) =
                  if Ring.isSolo r then (NONE, ready) else
                  let
                     val (sock, _) = Ring.get r
                     fun isHead sock = Socket.sameDesc (sock, head)
                  in
                     if getOpt (Option.map isHead sock, false)
                     then (SOME r, tail)
                     else (NONE, ready)
                  end
            
            fun ready (s, x) = 
               mapPartialWith pickReady 
               ((fromList o toList o Ring.iterator) s, x)
         in
            ready (readSockets, rds) @ ready (writeSockets, wrs)
         end
      
      fun process timeout =
         let
            val active = wait timeout
            
            (* Current wall clock time *)
            val now = Time.realTime ()
            
            (* Catch the clock up to real-time so the packets are processed
             * at the time they were received.
             *)
            val () = Event.runTill now
            fun exec r = 
               case #2 (Ring.get r) () of
                  REHOOK => ()
                | UNHOOK => Ring.remove r
            val () = Iterator.app exec active
            
            (* Process the delivered signals *)
            val signals = SigMap.iterator sigmap
            val signals = Iterator.map #1 signals
            val signals = Iterator.filter SigPoll.ready signals
            val signals = Iterator.toList signals
            val () = List.app runHandler signals
            
            (* Run any events that were queued by the processing of packets.
             * eg. sending out replies.
             *)
            val () = Event.runTill now
         in
            ()
         end
      
      fun poll () = process (SOME Time.zero)
      
      val stopFlagRef = ref false
      val depthRef = ref 0
      
      fun loop () =
         let
            val now = Time.realTime ()
            val next = Event.nextEvent ()
            val sleepTill = Option.map (fn next => Time.max (next, now)) next
            val sleep = Option.map (fn next => Time.- (next, now)) sleepTill
            val () = process sleep
         in
            if !stopFlagRef
            then stopFlagRef := false
            else loop ()
         end
      
      fun run () = 
         let
            val () = depthRef := !depthRef + 1
            val () = loop ()
            val () = depthRef := !depthRef - 1
         in
            ()
         end
      
      fun isRunning () = !depthRef > 0
      
      fun stop () = 
         if isRunning ()
         then stopFlagRef := true
         else raise Fail "Can not stop without a matching run" 
   end

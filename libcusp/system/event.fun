functor Event() :> EVENT_EXTRA =
   struct
      structure Heap = ManagedHeap(Time)
      datatype t = T of callback Heap.record
      withtype callback = t -> unit
      
      val heap = Heap.new ()
      val now = ref Time.zero
      
      fun time () = !now

      fun new callback = T (Heap.wrap (Time.zero, callback)) 
      
      fun execute (T event) = 
         case Heap.sub event of (_, _, f) => f (T event)

      exception PastEventScheduled

(*
      fun debug () =
         Iterator.app 
         (fn record => (case Heap.sub record of (false, _, _) => print "WKLEJRFSLDKJG!!!!\n" | (_, time, _) => print ("In-heap: " ^ Time.toString time ^ "\n")))
         (Heap.iterator heap)
*)
      
      fun schedule (time, callback) =
         let
            val () = if Time.< (time, !now) then raise PastEventScheduled else ()
            val event = Heap.wrap (time, callback)
         in
            Heap.push (heap, event)
            ; T event
         end 
      
      fun timeOfExecution (T event) =
         case Heap.sub event of
            (false, _, _) => NONE
          | (true, time, _) => SOME time
          
      fun timeTillExecution (T event) =
         case Heap.sub event of
            (false, _, _) => NONE
          | (true, time, _) => SOME (Time.- (time, !now))
      
      fun isScheduled (T event) = #1 (Heap.sub event)
      
      fun scheduleIn (time, callback) = 
         schedule (Time.+ (time, !now), callback) 
      
      fun reschedule (T event, time) =
         let
            val () = if Time.< (time, !now) then raise PastEventScheduled else ()
         in
            Heap.update (heap, event, time)
         end
      
      fun rescheduleIn (T event, time) = 
         reschedule (T event, Time.+ (time, !now))
         
      fun cancel (T event) =
         Heap.remove (heap, event)
       
      fun nextEvent () =
         case Heap.peek heap of
            NONE => NONE
          | (SOME e) => case Heap.sub e of (_, time, _) => SOME time

      fun runTill stop =
         case Heap.popBounded (heap, stop) of
            NONE => now := Time.max (stop, !now)
          | (SOME e) => 
               case Heap.sub e of (_, time, callback) =>
               (now := time; callback (T e); runTill stop)

      fun runNext () =
         case Heap.pop heap of
            NONE => false
          | SOME e =>
               case Heap.sub e of (_, time, callback) =>
               (now := time; callback (T e); true)

   end

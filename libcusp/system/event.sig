(**
 * Provides the interface for scheduling future events in an event scheduler.
 * 
 * Authors: Christof Leng, Wesley Terpstra
 *)
signature EVENT =
   sig
      (**
       * The event type. It is a handle returned by the schedule functions.
       * With this handle scheduled events can be canceled.
       *)
      type t
      (**
       * The event handling callback function type.
       *)
      type callback = t -> unit
      
      (**
       * Returns the schedule timestamp of the event currently being handled 
       * (if inside an event handling callback) or the time set by 
       * EVENT_EXTRA.runTill.
       *)
      val time : unit -> Time.t
      (**
       * Creates a new event for the given callback without scheduling the 
       * event.
       *)
      val new : callback -> t
      
      (**
       * Runs the event handler for the given event immediately.
       *)
      val execute : t -> unit

      (**
       * Scheduled timestamp for this event. NONE if unscheduled.
       *)
      val timeOfExecution : t -> Time.t option
      val timeTillExecution : t -> Time.t option
      val isScheduled : t -> bool
      
      (**
       * Exception thrown by schedule/reschedule (if given timestamp is 
       * smaller than EVENT.time) or scheduleIn/rescheduleIn (if given 
       * time offset is negative).  
       *)
      exception PastEventScheduled
      (**
       * Returns an event handle for the given callback scheduled at the given 
       * absolute timestamp.
       *)
      val schedule : Time.t * callback -> t
      (**
       * Returns an event handle for the given callback scheduled at the given 
       * time offset relative to the current EVENT.time.
       *)
      val scheduleIn : Time.t * callback -> t
      (**
       * Changes the execution time of the given event handle to the given 
       * absolute timestamp. If the given event is currently not scheduled this 
       * function is equivalent to EVENT.schedule.
       *)
      val reschedule : t * Time.t -> unit
      (**
       * Changes the execution time of the given event handle to the given 
       * time offset relative to the current EVENT.time. If the given event is  
       * currently not scheduled this function is equivalent to EVENT.schedule.
       *)
      val rescheduleIn : t * Time.t -> unit

      (**
       * Unschedules the given event handle from the scheduler. 
       * Silently succeeds if the event is not scheduled.
       *)
      val cancel : t -> unit
   end

(**
 * Provides the interface for implementing an event scheduler.
 * 
 * Authors: Christof Leng, Wesley Terpstra
 *)
signature EVENT_EXTRA =
   sig
      include EVENT
      (**
       * Returns timestamp of the next event in the scheduler.
       *)
      val nextEvent : unit -> Time.t option
      (**
       * Run all events before the given time.
       * After returning, calls to Event.time give the time specified as a parameter.
       *)
      val runTill : Time.t -> unit
      (**
       * Execute next event from the queue.
       * Returns true if an event was actually executed.
       *)
      val runNext : unit -> bool
   end

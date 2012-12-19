signature MAIN =
   sig
      structure Event : EVENT
      
      (* Run a main event loop that processes sockets and events *)
      val run : unit -> unit
      
      (* Returns true if running (i.e. in the event loop of the run() function),
       * false otherwise
       *)
      val isRunning : unit -> bool
      
      (* Stop the run function soon.
       * Does NOT promise to stop after the current event.
       * Does promise to stop before the run function would sleep again.
       *)
      val stop : unit -> unit
      
      (* Run the event loop only long enough to catch up to real-time *)
      val poll : unit -> unit
      
      (* Callback methods can unhook themselves for convenience *)
      datatype rehook = UNHOOK | REHOOK
      
      (* Hook a signal handler to be run on delivery of a signal.
       * 
       * After the unhook is called, the signal handler is restored.
       * If this is the first unhook, then true is returned, else false.
       *)
      val signal : Posix.Signal.signal * (unit -> rehook) -> (unit -> bool) 
      
      (* Register a socket to be polled, returning an unhook function.
       * Promises to call the callback only if the socket is read/write ready.
       * Promises not to sleep until the callback has been called.
       *
       * After the unhook function is called, poll callback will never be run.
       * If this is the first unhook, then true is returned, else false.
       *)
      val registerSocketForRead  : Socket.sock_desc * (unit -> rehook) -> (unit -> bool)
      val registerSocketForWrite : Socket.sock_desc * (unit -> rehook) -> (unit -> bool)
   end

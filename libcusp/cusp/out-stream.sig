signature OUT_STREAM =
   sig
      type t
      type priority = Real32.real
      
      (* Control the priority of this stream.
       * Higher priority streams transmit before low priority streams.
       * Raises an exception if the priority is not a finite value.
       *
       * The default priority is 0.
       * Negative priority values will not cause the stream to transmit unless
       * there is otherwise unused space in packet being sent to the peer.
       *)
      val getPriority: t -> priority
      val setPriority: t * priority -> unit
      
      (* Query how much data is buffered. *)
      val queuedInflight     : t -> int (* Inflight awaiting acknowledgment *)
      val queuedToRetransmit : t -> int (* Lost and waiting to be retransmit *)
      val bytesSent          : t -> LargeInt.int

      (* Indicate that the stream will transmit no further data to the peer.
       * If there is an incomplete write, RaceCondition will be raised.
       * If a stream is shutdown twice, RaceCondition will be raised.
       * Any subsequent attempt to queue data for transmission will fail.
       * Once all queued data is finally delivered, the callback is invoked
       * with true and the stream is garbage collected.
       * 
       * If the local out-stream is already reset or reset before final
       * delivery, the callback will be invoked with false. If the remote
       * read stream is reset, the callback is invoked with either true/false.
       *
       * Final delivery of data to the remote in-stream does not guarantee
       * delivery of data to the application. The in-stream might be reset
       * before all the remotely buffered data is delivered.
       *)
      val shutdown: t * (bool -> unit) -> unit
      
      (* Forcibly destroy this stream.
       * Prevents further transmission of data.
       * Immediately frees queueToRetransmit; queuedInFlight drains slowly.
       *  Does not retransmit lost segments.
       *  Cancels with RESET any pending local writes.
       * Attempts to signal RESET to the remote in-stream.
       *  If used before shutdown, remote in-stream is guaranteed to see RESET.
       *  If used after  shutdown, remote in-stream may or may not see RESET.
       * Data unreceived by the remote in-stream before reset may be lost.
       *)
      val reset: t -> unit
      
      (* Queue data for transmission to the remote in-stream.
       * The callback is invoked with READY when more data may be queued.
       * If write is called again before completion, RaceCondition is raised.
       * If write is called after shutdown, RaceCondition is raised.
       * 
       * If the local out-stream is reset, the callback is immediately RESET.
       * 
       * If the remote in-stream resets the stream, the callback might also
       * receive RESET, indicating no further writing should be done.
       *)
      datatype status = RESET | READY
      val write : t * Word8Vector.vector * (status -> unit) -> unit
   end

structure InStreamQueue :> IN_STREAM_QUEUE =
   struct
      datatype status = SHUTDOWN | RESET | DATA of Word8ArraySlice.slice
      
      structure Key = 
         struct
            type t = Word32.word
            open Word32
            val b31 = << (0w1, 0w31)
            fun a < b = (a-b) >= b31 (* a-b < 0 *)
         end
      structure Heap = Heap(Key)
      structure Key = Order(Key)
      
      (* Invariants:
       *   queueBytes = sum length of slices in queue
       *   readyBytes = sum length of slices in ready
       *   buffer = NONE or Queue.isEmpty ready
       *   the first byte not in ready has offset offset
       *   no slice in queue overlaps or precedes offset
       *   
       * Warning: The queue may contain overlapping slices 
       *)
      
      (* Stream control is managed with a write barrier.
       * The sender is not allowed to exceed this barrier.
       * We update the sender's barrier when it increased by more than 
       * minimum window / 2.
       *    barrier >= reader_offset + window 
       *    (read_offset = offset - readyBytes)
       * The window size is calculated as the change in offset between
       * transmission of a barrier update and its acknowledgement * 2.
       *)
      val minimumWindow = 0w21568 (* (1380-32)*16 --> ie: every 8th packet *)
      val barrierIncrement = minimumWindow div 0w4
      
      (* When we are done receiving data, we become UNASSIGNED.
       * Once all buffered data has been given to user, we become COMPLETE.
       * If we are reset remotely, we become UNASSIGNED+COMPLETE immediately.
       * If we are locally reset, we stay assigned until either
       *  1. we receive last of data -> UNASSIGNED+COMPLETE immediately.
       *  2. our reset is ackd -> UNASSIGNED+COMPLETE immediately.
       *)
      datatype event = 
         RTS of Real32.real
       | BECAME_UNASSIGNED
       | BECAME_COMPLETE
       | BECAME_RESET
       | UNREAD_BYTES of int 
       | OUT_OF_ORDER_BYTES of int
      datatype state = AM_CONNECTED | AM_SHUTDOWN | AM_RESET | AM_RESET_DOWN
      datatype fields = T of 
         { callback      : event -> unit,
           state         : state,
           barrier       : Word32.word,
           lastBarrier   : Word32.word,
           window        : Word32.word,
           queue         : Word8ArraySlice.slice Heap.t,
           queuedBytes   : int,
           ready         : Word8ArraySlice.slice Queue.t,
           readyBytes    : int,
           bytesReceived : Counter.int,
           offset        : Word32.word, 
           reader        : status -> unit,
           bufferSize    : int }
      withtype t' = fields ref
      type t = t'
      
      (* There is a vulnerability in this implementation.
       * We use a heap for the out-of-order segments.
       * This allows resending an out of order segment repeatedly to DoS RAM.
       * We should be using an interval tree or something to eliminate duplicates.
       *)
      
      open FunctionalRecordUpdate
      fun get f (ref (T fields)) = f fields
      fun update (this as ref (T fields)) =
         let
            fun from v1 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 =
               {callback=v1,state=v3,barrier=v4,lastBarrier=v5,
                window=v6,queue=v7,queuedBytes=v8,ready=v9,readyBytes=v10,
                bytesReceived=v11,offset=v12,reader=v13,bufferSize=v14}
            fun to f
               {callback=v1,state=v3,barrier=v4,lastBarrier=v5,
                window=v6,queue=v7,queuedBytes=v8,ready=v9,readyBytes=v10,
                bytesReceived=v11,offset=v12,reader=v13,bufferSize=v14} =
               f v1 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14
         in
            Fold.post (makeUpdate13 (from, from, to) fields, 
                       fn z => this := T z)
         end
      
      val queuedUnread     = get#readyBytes
      val queuedOutOfOrder = get#queuedBytes
      val bytesReceived    = Counter.toLarge o get#bytesReceived
      
      val rtsON  = RTS Real32.posInf
      val rtsOFF = RTS Real32.negInf
      
      val noBuffer = ~2
      
      fun fireEvent this =
         case get#state this of
            AM_SHUTDOWN => 
               if Heap.isEmpty (get#queue this)
               then (get#callback this) BECAME_UNASSIGNED 
               else ()
          | AM_RESET => ()
          | AM_RESET_DOWN => 
               if Heap.isEmpty (get#queue this) 
               then (get#callback this) BECAME_COMPLETE 
               else ()
          | AM_CONNECTED =>
            let
               val rts =
                  (get#barrier this) - (get#lastBarrier this)
                  >= barrierIncrement
            in
               (get#callback this) (if rts then rtsON else rtsOFF)
            end
      
      fun read (this, bufferSize, reader) =
         if get#state this = AM_RESET      then reader RESET else
         if get#state this = AM_RESET_DOWN then reader RESET else
         let
            (* Detect race *)
            val () = 
               if get#bufferSize this <> noBuffer 
               then raise RaceCondition else ()
            
            (* Values under ~1 are bad *)
            val () = 
               if bufferSize < ~1 then raise Domain else ()
            
            (* Two main cases:
             *  1. nothing ready -> put buffer and reader into wait state
             *  2. something ready ->
             *     dequeue it, trim it, process it
             *)
            val (ready, slice) = Queue.pop (get#ready this)
            val (ready, bufferSize, reader, readerHook, procBytes) =
               case slice of
                  NONE => 
                     if get#state this = AM_SHUTDOWN andalso
                        Heap.isEmpty (get#queue this)
                     then ((get#callback this) BECAME_COMPLETE
                           ; (ready, 
                              noBuffer, 
                              fn _ => (), 
                              fn () => reader SHUTDOWN, 
                              0))
                     else (ready, bufferSize, reader, fn () => (), 0)
                | SOME slice =>
                     let
                        val len = Word8ArraySlice.length slice
                        val (ready, report) = 
                           if bufferSize = ~1 orelse bufferSize >= len
                              then (ready, slice)
                              else (Queue.pushFront (ready, Word8ArraySlice.subslice (slice, bufferSize, NONE)),
                                    Word8ArraySlice.subslice (slice, 0, SOME bufferSize))
                     in
                        (ready, 
                         noBuffer, 
                         fn _ => (), 
                         fn () => reader (DATA report),
                         Word8ArraySlice.length report)
                     end
            
            val readyBytes = get#readyBytes this - procBytes
            
            (* Ensure that there is always a minimum window available *)
            val reader_offset = get#offset this - Word32.fromInt readyBytes
            val barrier = Key.max (get#barrier this, reader_offset + get#window this)
         in
            update this
               set#ready         ready
               set#readyBytes    readyBytes
               upd#bytesReceived (fn x => x + Counter.fromInt procBytes)
               set#reader        reader
               set#barrier       barrier
               set#bufferSize    bufferSize $
            ; (get#callback this) (UNREAD_BYTES (~procBytes))
            ; fireEvent this (* AM_RESET never reaches here *)
            ; readerHook ()
         end
      
      fun dupSlice s =
         Word8ArraySlice.full 
         (Word8Array.tabulate 
          (Word8ArraySlice.length s,
           fn i => Word8ArraySlice.sub (s, i)))
      
      (* The queue can be in two states:
       *  1. waiting for data -> offset = position of pending reader
       *  2. buffering data   -> offset = position needed to append to ready
       *
       * We break the recv method into phases:
       * 1. Trim anything that precedes the offset, if data remains continue
       * 2. If read offset != ready offset, put in queue else continue
       * 3. If reader attached, setup a hook to process some of the data
       * 4. update offset to point past the data
       *    transfer slices <= offset from queue to ready
       *)
      fun recvData (this, offset, data) =
         let
            (* Clip the front of the data if it precedes our offset *)
            val delta = get#offset this - offset
            val len = Word8ArraySlice.length data
            val eop = offset + Word32.fromInt len
         in
            (* If they exceed the barrier, drop the whole packet! 
             * This should only happen if their client is buggy.
             *)
            if Key.> (eop, get#barrier this) then false else
            if len = 0 then true else
            if Key.>= (delta, 0w0)
            then
                if Word32.toInt delta >= len then true else
                feedReader
                (this, 
                 Word8ArraySlice.subslice (data, Word32.toInt delta, NONE))
            else outOfOrder (this, offset, data)
         end
      and outOfOrder (this, offset, data) =
         let
            val () = Heap.push (get#queue this, offset, dupSlice data)
            val len = Word8ArraySlice.length data
         in
            update this upd#queuedBytes (fn x => x + len) $
            ; (get#callback this) (OUT_OF_ORDER_BYTES len)
            ; true
         end
      and feedReader (this, data) =
         if get#bufferSize this = noBuffer
            then transferQueue (this, SOME data, 0, fn _ => ())
            else
               let
                  val bufferSize = get#bufferSize this
                  (* assert: Queue.isEmpty ready *)
                  val len = Word8ArraySlice.length data
                  val (report, tail) =
                     if bufferSize = ~1 orelse bufferSize >= len
                        then (data, NONE)
                        else (Word8ArraySlice.subslice (data, 0, SOME bufferSize),
                              SOME (dupSlice (Word8ArraySlice.subslice (data, bufferSize, NONE))))
                  val reader = get#reader this
                  fun readerHook () = reader (DATA report)
                  val reportLen = Word8ArraySlice.length report
               in
                  transferQueue (this, tail, reportLen, readerHook)
               end
      and transferQueue (this, data, recvd, readerHook) =
         let
            (* prepend the unread portion *)
            val (ready, len) = 
               case data of
                  NONE => (get#ready this, 0w0)
                | SOME slice => 
                     (Queue.pushFront (get#ready this, slice),
                      Word32.fromInt (Word8ArraySlice.length slice))
            
            fun process (offset, ate, ready) =
               case Heap.popBounded (get#queue this, offset) of
                  NONE => (offset, ate, ready)
                | SOME (sliceoffset, slice) =>
                     let
                        val trim = Word32.toInt (offset - sliceoffset)
                        val add = Word8ArraySlice.subslice (slice, trim, NONE)
                        val ready = Queue.pushBack (ready, add)
                        val addLen = Word8ArraySlice.length add
                        val sliceLen = Word8ArraySlice.length slice
                     in
                        process (offset + Word32.fromInt addLen,
                                 ate + sliceLen,
                                 ready)
                     end
            
            (* now transfer all ready data from queue *)
            val oldOffset = get#offset this
            val readyOffset = oldOffset + Word32.fromInt recvd
            val (newOffset, lostQueueBytes, ready) = 
               process (readyOffset + len, 0, ready)
            val newReadyBytes = Word32.toInt (newOffset - readyOffset)
            val (newReadyBytes, ready) =
               if get#state this = AM_RESET orelse get#state this = AM_RESET_DOWN
               then (0, Queue.empty)
               else (newReadyBytes, ready)

            (* Ensure that there is always a minimum window available *)
            val readyBytes = get#readyBytes this + newReadyBytes
            val reader_offset = newOffset - Word32.fromInt readyBytes
            val barrier = Key.max (get#barrier this, reader_offset + get#window this)
            
            val () = 
               update this
                  upd#queuedBytes   (fn x => x - lostQueueBytes)
                  set#ready         ready
                  set#readyBytes    readyBytes
                  set#barrier       barrier
                  upd#bytesReceived (fn x => x + Counter.fromInt recvd)
                  set#reader        (fn _ => ())
                  set#bufferSize    noBuffer
                  set#offset        newOffset $
            val () = (get#callback this) (OUT_OF_ORDER_BYTES (~lostQueueBytes))
            val () = (get#callback this) (UNREAD_BYTES newReadyBytes)
            
            val () = fireEvent this
            val () = readerHook ()
         in
            true
         end
      
      fun shutdown this =
          (if get#state this = AM_CONNECTED then get#callback this rtsOFF else ()
           ; update this upd#state (fn AM_CONNECTED => AM_SHUTDOWN
                                     | AM_RESET => AM_RESET_DOWN
                                     | x => x) $
           ; fireEvent this
           ; if Heap.isEmpty (get#queue this) andalso
                Queue.isEmpty (get#ready this) andalso
                get#bufferSize this <> noBuffer
             then 
                let 
                   val reader = get#reader this
                   val () = (get#callback this) BECAME_COMPLETE
                   val () =
                      update this 
                         set#reader (fn _ => ())
                         set#bufferSize noBuffer $
                in
                   reader SHUTDOWN
                end
             else ())
      
      fun reset this =
         let
            val () = (get#callback this) (UNREAD_BYTES (~ (get#readyBytes this)))
            val reader = get#reader this
            val () = 
               update this
                  upd#state       (fn AM_CONNECTED => AM_RESET
                                    | AM_SHUTDOWN => AM_RESET_DOWN
                                    | x => x)
                  set#ready       Queue.empty
                  set#readyBytes  0
                  set#reader      (fn _ => ())
                  set#bufferSize  noBuffer $
            val () = (get#callback this) rtsON
            val () = (get#callback this) BECAME_RESET
            val () = fireEvent this
            val () = reader RESET
         in
            ()
         end
      
      local
         open PacketFormat
         val { parseSlice, writeSlice, ... } = Serial.methods Serial.word32b
         val parser = fn d => 
            parseSlice (Word8ArraySlice.subslice (d, 4, SOME 4))
         val writer = fn (d, x) =>
            writeSlice (Word8ArraySlice.subslice (d, 4, SOME 4), x)
      in
      fun recv (this, data, x) = case x of
         READER_CTL WRITER_RESETS => 
             ((get#callback this) (UNREAD_BYTES (~ (get#readyBytes this)))
             ; update this 
                  set#state      AM_SHUTDOWN
                  set#ready      Queue.empty
                  set#readyBytes 0  $
             ; reset this
             ; 4)
       | DATA { eof, offset, length } =>
            let
               val begin = if offset then 8 else 4
               val need = align length + begin
            in
               (* check for a corrupt packet to prevent subscript error *)
               if Word8ArraySlice.length data < need 
               then (PacketFormat.bad "short DATA"; ~1) else 
               let
                  val offset = if offset then parser data else 0w0
                  val data = Word8ArraySlice.subslice (data, begin, SOME length)
                  val ok = recvData (this, offset, data)
               in
                  if eof then shutdown this else ()
                  ; if ok then need else ~1
               end
            end

      fun pull (this, id, seq, data) =
         case get#state this of
            AM_SHUTDOWN => raise Fail "unreachable"
          | AM_CONNECTED =>
            let
               (* The reader was at this point: *)
               val oldOffset = 
                  get#offset this - Word32.fromInt (get#readyBytes this)
               val barrier = get#barrier this
               val lastBarrier = get#lastBarrier this
               val () = update this set#lastBarrier barrier $
               val () = (get#callback this) rtsOFF
               
               fun ackd true =
                  let
                     (* The new reader offset: *)
                     val newOffset =
                        get#offset this - Word32.fromInt (get#readyBytes this)
                     
                     (* Upon receiving a segment, we can still see packets
                      * up to 15 sequence numbers old. The offsets for
                      * segments in these packets must not be allowed to
                      * confuse us later. Since the stream moves at most one
                      * MTU of data per sequence number, if we leave a 16*MTU
                      * gap between the write edge, by the time we hit the
                      * point where confusion could happen, any delayed
                      * retransmissions will be dropped.
                      *)
                      
                     (* We don't know the actual MTU, but assume for safety
                      * that it is <= 1Mb.  *)
                     val safetyMargin = 0w1024*0w1024*0w16
                     val window = (newOffset - oldOffset) * 0w2
                     (* Not Key.min/max because these are absolute values *)
                     val window = Word32.min (window, 0wx7fffffff-safetyMargin)
                     val window = Word32.max (window, minimumWindow)
                     
                     (*
                     val () = print "old:\n"
                     val () = print ("  offset:  " ^ Word32.toString oldOffset ^ "\n")
                     val () = print ("  barrier: " ^ Word32.toString barrier ^ "\n")
                     val () = print ("  lastBar: " ^ Word32.toString lastBarrier ^ "\n")
                     *)
                     val barrier = get#barrier this
                     val barrier = Key.max (newOffset + window, barrier)
                     
                     (*
                     val () = print "new:\n"
                     val () = print ("  offset:  " ^ Word32.toString newOffset ^ "\n")
                     val () = print ("  barrier: " ^ Word32.toString barrier ^ "\n")
                     val () = print ("  lastBar: " ^ Word32.toString (get#lastBarrier this) ^ "\n")
                     val () = print ("  Window:  " ^ Word32.toString window ^ "\n")
                     *)
                     
                     val () = 
                       update this 
                         set#barrier barrier 
                         set#window  window $
                  in
                     fireEvent this
                  end
                | ackd false =
                  if get#lastBarrier this <> barrier then () else
                  (update this set#lastBarrier lastBarrier $
                   ; fireEvent this)
               
               val msg = WRITER (WRITER_CTL READER_BARRIER, { id = id, seq = seq })
               val () = PacketFormat.write (data, msg)
               val () = writer (data, barrier)
            in
               (8, ackd)
            end
          | _ => (* AM_REST or AM_RESET_DOWN *)
            let
               fun ackd true  = (get#callback this) BECAME_COMPLETE
                 | ackd false = (get#callback this) rtsON
               val () = (get#callback this) rtsOFF
               val msg = WRITER (WRITER_CTL READER_RESETS, { id = id, seq = seq })
               val () = PacketFormat.write (data, msg)
            in
               (4, ackd)
            end
      end
      
      fun isReset this =
         get#state this = AM_RESET orelse 
         get#state this = AM_RESET_DOWN
      
      fun new cb =
         ref (T { callback      = cb,
                  state         = AM_CONNECTED,
                  barrier       = minimumWindow,
                  lastBarrier   = minimumWindow,
                  window        = minimumWindow,
                  queue         = Heap.new (),
                  queuedBytes   = 0,
                  ready         = Queue.empty,
                  readyBytes    = 0,
                  bytesReceived = 0,
                  offset        = 0w0,
                  reader        = fn _ => (),
                  bufferSize    = noBuffer })
      
      (* Convenience function *)
      fun readFully (sock, buffer, cb) =
         let
            open Word8ArraySlice
               
            fun readPart tail = read (sock, length tail, readSome tail)
            and readSome tail = fn 
               RESET => cb false
             | SHUTDOWN => cb false
             | DATA got =>
                let
                   val (base, off, _) = base tail
                   val () = copy { src = got, dst = base, di = off }
                   val tail = subslice (tail, length got, NONE)
                in
                   if isEmpty tail
                      then cb true
                      else readPart tail
                end
         in
            if isEmpty buffer
               then cb true
               else readPart buffer
         end
      
      fun readShutdown (sock, cb) =
         let
            val rec go = fn
               () => read (sock, 0, done)
            and done = fn
               RESET => cb false
             | SHUTDOWN => cb true
             | DATA _ => (reset sock; cb false)
         in
           go ()
         end 
   end

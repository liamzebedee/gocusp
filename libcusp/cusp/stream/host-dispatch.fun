(* Streams in the heap can be in one of three states:
 *  1. Unassigned  - not attached: has no id.
 *                 - write streams start this way until pulled
 *                 - read streams become unassigned upon receipt completion
 *                   while waiting for the user to read buffered data
 *  2. Established - is attached: has an id.
 *                 - write streams enter this state from unassigned on a pull
 *                 - read streams enter this state on first receive
 *  3. Reset       - just like established: has an id.
 *                 - stream is trying to xmit reset to peer
 *                 - should not be included stream iteration
 *)
functor HostDispatch(structure Event   : EVENT
                     structure Address : ADDRESS)
   : HOST_DISPATCH =
   struct
      structure HeapKey =
         struct
            type t = { priority : Real32.real, lastSent : Time.t }
            fun { priority=ap, lastSent=al } < 
                { priority=bp, lastSent=bl } =
               case Real32.compareReal (ap, bp) of
                  IEEEReal.LESS => false
                | IEEEReal.EQUAL => Time.< (al, bl)
                | IEEEReal.GREATER => true
                | IEEEReal.UNORDERED => raise Fail "bad priority"
         end
      structure Heap = ManagedHeap(HeapKey)
      structure HashKey =
         struct
            type t = Word16.word
            val eq = op =
            val hash = Hash.word16
         end
      structure Hash = HashTable(HashKey)
      
      datatype stream =
         IN_STREAM of InStreamQueue.t
       | OUT_STREAM of OutStreamQueue.t
       | NO_STREAM
      type stream_record = {
         stream : stream,
         id     : Word16.word,
         prefix : Word16.word }
      type record = stream_record Heap.record
      datatype fields = T of
         { key                : publickey,
           queuedOutOfOrder   : int,
           queuedUnread       : int,
           queuedInFlight     : int,
           queuedToRetransmit : int,
           bytesReceived      : Counter.int,
           bytesSent          : Counter.int,
           listen             : (Word16.word * instream -> unit) Hash.t,
           global             : Word16.word -> (t * instream -> unit) option,
           ready              : (Real32.real -> unit) option,
           heap               : stream_record Heap.t,
           inStreams          : record option array,
           outStreams         : alloc array,
           writeFree          : Word16.word,
           cooldownIndex      : int,
           cooldowns          : Word16Array.array,
           seqNums            : Word8Array.array,
           lastSend           : Time.t,
           lastReceive        : Time.t,
           address            : address,
           disconnect         : Event.t,
           poked              : Event.t option,
           reconnect          : address -> unit,
           keepAlive          : (unit -> int) Ring.t option
           }
      and alloc =
         ALLOC of record
       | FREE of Word16.word
      withtype t = fields ref
      and instream  = InStreamQueue.t
      and outstream = OutStreamQueue.t
      and publickey = Crypto.PublicKey.t
      and address = Address.t
      
      type service = Word16.word
      
      open FunctionalRecordUpdate
      fun get f (ref (T fields)) = f fields
      fun update (this as ref (T fields)) =
         let
            fun from
               v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16 v17 v18 v19 v20 v21 v22 v23 v24 =
               {key=v1,global=v2,queuedOutOfOrder=v3,queuedUnread=v4,
                queuedInFlight=v5,queuedToRetransmit=v6,bytesReceived=v7,
                bytesSent=v8,heap=v9,inStreams=v10,outStreams=v11,
                writeFree=v12,listen=v13,ready=v14,cooldownIndex=v15,
                cooldowns=v16,seqNums=v17,lastSend=v18,lastReceive=v19,
                address=v20,disconnect=v21,reconnect=v22,keepAlive=v23,
                poked=v24}
            fun to f
               {key=v1,global=v2,queuedOutOfOrder=v3,queuedUnread=v4,
                queuedInFlight=v5,queuedToRetransmit=v6,bytesReceived=v7,
                bytesSent=v8,heap=v9,inStreams=v10,outStreams=v11,
                writeFree=v12,listen=v13,ready=v14,cooldownIndex=v15,
                cooldowns=v16,seqNums=v17,lastSend=v18,lastReceive=v19,
                address=v20,disconnect=v21,reconnect=v22,keepAlive=v23,
                poked=v24} =
               f v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16 v17 v18 v19 v20 v21 v22 v23 v24
         in
            Fold.post (makeUpdate24 (from, from, to) fields,
                       fn z => this := T z)
         end
      
      val nill = 0wxffff
      
      val queuedOutOfOrder   = get#queuedOutOfOrder
      val queuedUnread       = get#queuedUnread
      val queuedInflight     = get#queuedInFlight
      val queuedToRetransmit = get#queuedToRetransmit
      val bytesReceived      = Counter.toLarge o get#bytesReceived
      val bytesSent          = Counter.toLarge o get#bytesSent
      val lastReceive        = get#lastReceive
      val lastSend           = get#lastSend
      val key                = get#key
      
      fun outStreams this =
         let
            val alive = fn
               OUT_STREAM f => 
                  if OutStreamQueue.isReset f then NONE else SOME f
             | _ => NONE
            open Iterator
         in
            mapPartial 
               (alive o #stream o #3 o Heap.sub) 
               (Heap.iterator (get#heap this))
         end
      
      fun inStreams this =
         let
            val alive = fn
               IN_STREAM f => 
                  if InStreamQueue.isReset f then NONE else SOME f
             | _ => NONE
            open Iterator
         in
            mapPartial 
               (alive o #stream o #3 o Heap.sub) 
               (Heap.iterator (get#heap this))
         end
      
      fun streams this =
         let
            val alive = fn
               IN_STREAM  f => not (InStreamQueue.isReset f)
             | OUT_STREAM f => not (OutStreamQueue.isReset f)
             | NO_STREAM => false
            open Iterator
         in
            filter alive 
            (map (#stream o #3 o Heap.sub) (Heap.iterator (get#heap this)))
         end
      
      fun isZombie this = Iterator.null (streams this)
      fun isDying this = Event.isScheduled (get#disconnect this)
      
      (* We need to trick the compiler to keep a reference.
       * Getting the unread bytes forces the host alive.
       *)
      val keptAlive = Ring.new (fn () => 0)
      fun noop this () = get#queuedUnread this
         
      fun keepAlive this =
         if isSome (get#keepAlive this) then () else
         update this set#keepAlive (SOME (Ring.add (keptAlive, noop this))) $
      fun loseAlive this =
         if Hash.isEmpty (get#listen this) andalso isZombie this
         then 
            case get#keepAlive this of NONE => () | SOME ka =>
            (Ring.remove ka; update this set#keepAlive NONE $)
         else ()
      
      (* Force the Ring's functions to be used *)
      val tenYears = Time.fromSeconds (60*60*25*365*10)
      fun keepRingAlive e =
         let
            val offset = 
               Iterator.fold 
               (fn (r, x) => Ring.get r () + x)
               0
               (Ring.iterator keptAlive)
         in
            Event.rescheduleIn (e, Time.+ (tenYears, Time.fromSeconds offset))
         end
      val _ = Event.scheduleIn (tenYears, keepRingAlive)
      
      fun listen (this, cb) =
         if Hash.size (get#listen this) = 16384 then raise AddressInUse else
         let
            val high = Word16.<< (0w1, 0w15)
            val id = Word16.orb (Random.word16 (random, NONE), high)
         in
            case Hash.find (get#listen this, id) of
               SOME _ => listen (this, cb)
             | NONE => (keepAlive this
                        ; Hash.add (get#listen this, id, cb)
                        ; id)
         end
      
      fun unlisten (this, port) =
         (Hash.remove (get#listen this, port); loseAlive this)
      
      fun sendRTS this =
         let
            (* Anything with priority below 0 -> not ready to send *)
            val bound = { priority = 0.0, lastSent = Time.maxTime }
            val prio = 
               Option.map 
               (#priority o #2 o Heap.sub) 
               (Heap.peekBounded (get#heap this, bound))
         in
            case get#ready this of
               NONE => ()
             | SOME f => f (getOpt (prio, Real32.negInf))
         end
      
      fun isBound this = isSome (get#ready this)

      (* Unbind happens when our channel changes hosts or dies.
       * We take almost no action because it's possible it will reconnect.
       *)
      fun unbind this = 
         (Event.cancel (get#disconnect this)
          ; update this set#ready NONE $)
      
      fun checkZombie this =
         if not (isBound this) then () else
         case (isZombie this, isDying this) of
            (false, false) => ()
          | (false, true)  => Event.cancel (get#disconnect this)
          | (true,  true)  => ()
          | (true,  false) =>
               Event.rescheduleIn (get#disconnect this, Time.fromSeconds 240)
      
      (* Bind happens when a channel has proven it connects to this host.
       * We need to destroy any existing channel that lingers connected to us.
       *)
      val destroyIt = Real32.posInf * 0.0 (* NaN *)
      fun bind (this, cb) =
         (Option.app (fn f => f destroyIt) (get#ready this)
          ; update this set#ready (SOME cb) $
          ; sendRTS this
          ; checkZombie this)
      
      fun address this = if isBound this then SOME (get#address this) else NONE
      fun updateAddress (this, x) = update this set#address x $
      
      fun tickWriterSeq (seqNums, i) = 
         let
            val seq = Word8Array.sub (seqNums, i)
            val seq = seq + 0wx10
         in
            Word8Array.update (seqNums, i, seq)
         end
      fun tickReaderSeq (seqNums, i) = 
         let
            val seq = Word8Array.sub (seqNums, i)
            val seq =
               Word8.orb (Word8.andb (seq, 0wxf0),
                          Word8.andb (seq+0w1, 0wx0f))
         in
            Word8Array.update (seqNums, i, seq)
         end
      fun getWriterSeq (seqNums, i) = 
         if i >= Word8Array.length seqNums then 0 else
         Word8.toInt (Word8.>> (Word8Array.sub (seqNums, i), 0w4))
      fun getReaderSeq (seqNums, i) = 
         if i >= Word8Array.length seqNums then 0 else
         Word8.toInt (Word8.andb (Word8Array.sub (seqNums, i), 0wxf))

      fun tickCooldown this =
         let
            val index = get#cooldownIndex this
            val index = if index = 15 then 0 else (index + 1)
            val streams = get#outStreams this
            fun loop (id, tail) =
               if id = nill then tail else
               let
                  val id' = Word16.toInt id
                  val next = 
                     case Array.sub (streams, id') of
                        FREE next => next
                      | _ => raise Fail "Corrupt stream free list"
                  val () = Array.update (streams, id', FREE tail)
               in
                  loop (next, id)
               end
            val free = get#writeFree this
            val free = loop (Word16Array.sub (get#cooldowns this, index), free)
            val () =
               Word16Array.update (get#cooldowns this, index, nill)
         in
            update this
               set#writeFree     free
               set#cooldownIndex index $
         end
      
      fun pushCooldown (this, id) =
         let
            val index = get#cooldownIndex this
            val head = Word16Array.sub (get#cooldowns this, index)
         in
            Array.update (get#outStreams this, Word16.toInt id, FREE head)
            ; Word16Array.update (get#cooldowns this, index, id)
         end
      
      (* The callback for out-streams. *)
      fun outStreamCallback (this, record) event =
         case event of
            OutStreamQueue.RTS prio => 
               let
                  val (inHeap, { priority=_, lastSent }, _) = Heap.sub record
                  val key = { priority = prio, lastSent = lastSent }
               in
                  if not inHeap then () else
                  (Heap.update (get#heap this, record, key)
                   ; sendRTS this)
               end
          | OutStreamQueue.BECAME_COMPLETE => 
               let
                  val (inHeap, _, { id, stream, prefix }) = Heap.sub record
                  val () = 
                     Heap.updateValue (record,
                     { id = nill, stream = stream, prefix = prefix })
                  val () =
                     if id = nill then () else
                     (tickWriterSeq (get#seqNums this, Word16.toInt id)
                      ; pushCooldown (this, id))
                  val () = 
                     if not inHeap then () else
                     Heap.remove (get#heap this, record)
                  val () = checkZombie this
                  val () = loseAlive this
               in
                  sendRTS this
               end
          | OutStreamQueue.BECAME_RESET =>
               (checkZombie this; loseAlive this)
          | OutStreamQueue.INFLIGHT_BYTES x => 
               update this
                  upd#queuedInFlight (fn z => z + x) $
          | OutStreamQueue.RETRANSMIT_BYTES x =>
               update this
                  upd#queuedToRetransmit (fn z => z + x) $
      
      fun inStreamCallback (this, record) event =
         case event of
            InStreamQueue.RTS prio => 
               let
                  val (inHeap, { priority=_, lastSent }, _) = Heap.sub record
                  val key = { priority = prio, lastSent = lastSent }
               in
                  if not inHeap then () else
                  (Heap.update (get#heap this, record, key)
                   ; sendRTS this)
               end
          | InStreamQueue.BECAME_UNASSIGNED => 
               let
                  val (_, _, { id, stream, prefix }) = Heap.sub record
                  val () = 
                     Heap.updateValue (record,
                     { id = nill, stream = stream, prefix = prefix })
               in
                  if id = nill then () else
                  (tickReaderSeq (get#seqNums this, Word16.toInt id)
                   ; Array.update (get#inStreams this, Word16.toInt id, NONE))
               end
          | InStreamQueue.BECAME_COMPLETE => 
               let
                  val (inHeap, _, { id, stream, prefix }) = Heap.sub record
                  val () = 
                     Heap.updateValue (record,
                     { id = nill, stream = stream, prefix = prefix })
                  val () =
                     if id = nill then () else
                     (tickReaderSeq (get#seqNums this, Word16.toInt id)
                      ; Array.update (get#inStreams this, Word16.toInt id, NONE))
                  val () = 
                     if not inHeap then () else
                     Heap.remove (get#heap this, record)
                  val () = checkZombie this
                  val () = loseAlive this
               in
                  sendRTS this
               end
          | InStreamQueue.BECAME_RESET =>
               (checkZombie this; loseAlive this)
          | InStreamQueue.UNREAD_BYTES x => 
               update this 
                  upd#queuedUnread (fn z => z + x) $
          | InStreamQueue.OUT_OF_ORDER_BYTES x =>
               update this
                  upd#queuedOutOfOrder (fn z => z + x) $
      
      fun expand (this, newLen) =
         let
            val oldLen = Array.length (get#inStreams this)
            
            val seqNums = get#seqNums this
            val seqNums = 
               Word8Array.tabulate (newLen, fn i => 
                  if i < oldLen then Word8Array.sub (seqNums, i) else 0w0)
            
            val inStreams = get#inStreams this
            val inStreams = 
               Array.tabulate (newLen, fn i =>
                  if i < oldLen then Array.sub (inStreams, i) else NONE)
            
            val writeFree = get#writeFree this
            val outStreams = get#outStreams this
            val outStreams =
               Array.tabulate (newLen, fn i =>
                  if i < oldLen then Array.sub (outStreams, i) else
                  FREE (if i = newLen-1 then writeFree else Word16.fromInt (i+1)))
            val writeFree = Word16.fromInt oldLen
         in
            update this
               set#inStreams  inStreams
               set#outStreams outStreams
               set#writeFree  writeFree
               set#seqNums    seqNums $
         end
      
      fun noExpandSubReader (a, i) = 
         let
            val i = Word16.toInt i
            val len = Array.length a
         in
            if i >= len then NONE else Array.sub (a, i)
         end
      
      fun noExpandSubWriter (a, i) = 
         let
            val i = Word16.toInt i
            val len = Array.length a
         in
            if i >= len then FREE nill else Array.sub (a, i)
         end
      
      fun expandSubReader (this, i') =
         let
            val i = Word16.toInt i'
            val len = Array.length (get#inStreams this)
            
            fun slide i w = Word16.orb (w, Word16.>> (w, i))
            val contain = slide 0w8 o slide 0w4 o slide 0w2 o slide 0w1
            fun newLen () = Word16.toInt (contain i') + 1
            
            val () = if i >= len then expand (this, newLen ()) else ()
         in
            Array.sub (get#inStreams this, i)
         end
      
      (* !!! should bail if out of IDs *)
      fun allocId this =
         let
            val id =
               if get#writeFree this = nill
               then (expand  (this, Array.length (get#inStreams this) * 2)
                     ; get#writeFree this)
               else (get#writeFree this)
            val next =
               case Array.sub (get#outStreams this, Word16.toInt id) of
                  FREE x => x
                | ALLOC _ => raise Fail "Impossible. Free id is allocated."
            val () =
               update this set#writeFree next $
         in
            id
         end

      fun connect (this, port) =
         let
            val needReconnect = not (isBound this) andalso isZombie this
            
            val record = 
               Heap.wrap ({ priority = Real32.negInf, lastSent = Event.time () },
                          { stream = NO_STREAM, id = nill, prefix = port })
            val stream = OutStreamQueue.new (outStreamCallback (this, record))
            val () = Heap.updateValue (record, 
                     { stream = OUT_STREAM stream, id = nill, prefix = port })
            val () = Heap.push (get#heap this, record)
            
            val () = checkZombie this
            val () = keepAlive this
            val () = if not needReconnect then () else
                     (get#reconnect this) (get#address this)
         in
            stream
         end
      
      fun gotConnection (this, id, service) =
         let
            val record = 
               Heap.wrap ({ priority = Real32.negInf, lastSent = Event.time () },
                          { stream = NO_STREAM, id = id, prefix = 0w0 })
            val stream = InStreamQueue.new (inStreamCallback (this, record))
            val () = Heap.updateValue (record,
                     { stream = IN_STREAM stream, id = id, prefix = 0w0 })
            val () = Heap.push (get#heap this, record)
            val () =
               Array.update (get#inStreams this, Word16.toInt id, SOME record)
         in
            case Hash.find (get#listen this, service) of
               SOME cb => (checkZombie this; cb (service, stream))
             | NONE => 
               (case (get#global this) service of
                   SOME cb => 
                      (keepAlive this; checkZombie this; cb (this, stream))
                 | NONE => InStreamQueue.reset stream) (* reset immediately *)
         end
      
      local
         open PacketFormat
      in
      fun skipReader data = fn
         READER_CTL _ => 4
       | DATA { eof=_, offset, length } =>
            let
               val begin = if offset then 8 else 4
               val need = align length + begin
            in
               if Word8ArraySlice.length data < need
               then (PacketFormat.bad "short skipped DATA"; ~1) else
               need
            end
      val skipWriter = fn
         WRITER_CTL READER_RESETS => 4
       | WRITER_CTL READER_BARRIER => 8
      fun recvSegment (this, data) =
         case PacketFormat.parse data of
            CORRUPT => 
               (PacketFormat.bad "corrupt stream header"; ~1)
          | READER (msg, { id }) => 
               (case noExpandSubReader (get#inStreams this, id) of
                   NONE => skipReader data msg
                 | SOME record => 
                      (case (#stream o #3 o Heap.sub) record of
                          IN_STREAM stream => 
                             InStreamQueue.recv (stream, data, msg)
                        | _ => raise Fail "corrupt inStreams"))
          | WRITER (msg, { id, seq }) =>
               if seq <> getWriterSeq (get#seqNums this, Word16.toInt id)
               then skipWriter msg else
               (case noExpandSubWriter (get#outStreams this, id) of
                   FREE _ => skipWriter msg
                 | ALLOC record =>
                     (case (#stream o #3 o Heap.sub) record of
                         OUT_STREAM stream => 
                            OutStreamQueue.recv (stream, data, msg)
                       | _ => raise Fail "corrupt outStreams"))
          | CREATE (CONNECT, { service, seq }) => 
               let
                  val subdata = Word8ArraySlice.subslice (data, 4, NONE)
                  val next = PacketFormat.parse subdata
               in
                  case next of
                     READER (msg, { id }) =>
                        if seq <> getReaderSeq (get#seqNums this, Word16.toInt id)
                        then 
                        (case skipReader subdata msg of
                            ~1 => ~1
                          |  x => x + 4)
                        else
                        (case expandSubReader (this, id) of
                            NONE => (gotConnection (this, id, service); 4)
                          | SOME _ => 4)
                   | _ => (PacketFormat.bad "attach has no reader header"; ~1)
               end
               
      val pullBound = { priority = ~Real32.maxFinite, lastSent = Time.maxTime }
      fun pullSegment (this, data) = 
         if Word8ArraySlice.length data < 32 then (0, fn _ => ()) else
         case Heap.peekBounded (get#heap this, pullBound) of
            NONE => (0, fn _ => ())
          | SOME record =>
               let
                  val (_, { priority, lastSent=_ }, 
                          { stream, id, prefix }) = Heap.sub record
                  val () = (* load balance *)
                     Heap.update (get#heap this, record, 
                                  { priority = priority, 
                                    lastSent = Event.time () })
                  (* If stream was pulled for the first time, allocate an id *)
                  val id = 
                     if id <> nill then id else
                     let
                        val id = allocId this
                        val () = Heap.updateValue (record,
                                 { stream = stream, id = id, prefix = prefix })
                        val () = Array.update (get#outStreams this, 
                                               Word16.toInt id, ALLOC record)
                     in
                        id
                     end
                  val (prefixUse, data) = 
                     if prefix = 0w0 then (0, data) else
                     (PacketFormat.write (data, CREATE (CONNECT, 
                       { seq = getWriterSeq (get#seqNums this, Word16.toInt id),
                         service = prefix }))
                      ; (4, Word8ArraySlice.subslice (data, 4, NONE)))
                  val (use, ack) =
                     case stream of
                        NO_STREAM => raise Fail "Pulling no stream?! impossible"
                      | OUT_STREAM w =>
                           OutStreamQueue.pull (w, id, data)
                      | IN_STREAM r => 
                           InStreamQueue.pull 
                           (r, id, 
                            getReaderSeq (get#seqNums this, Word16.toInt id), 
                            data)
                  fun clearPrefix () =
                     let
                        val (_, _, { stream, id, prefix=_ }) = Heap.sub record
                     in
                        Heap.updateValue 
                        (record, { stream = stream, id = id, prefix = 0w0 })
                     end
                  val tail = Word8ArraySlice.subslice (data, use, NONE)
                  val (subUse, subAck) = pullSegment (this, tail)
               in
                  (prefixUse + use + subUse, 
                   fn x => (if x then clearPrefix () else (); ack x; subAck x))
               end
      end
      
      fun recvPacket (this, data) =
         if Word8ArraySlice.length data = 0 then true else
         case recvSegment (this, data) of
            ~1 => false
          | len => recvPacket (this, Word8ArraySlice.subslice (data, len, NONE))
      
      fun recv (this, data) =
         let
            val ok = recvPacket (this, data)
            val len = Word8ArraySlice.length data
            val () = 
               if not ok then () else
               update this 
                  upd#bytesReceived (fn x => x + Counter.fromInt len) 
                  set#lastReceive   (Event.time ()) $
         in
            ok
         end
      
      fun pull (this, data) =
         let
            val () = tickCooldown this
            val (used, ack) = pullSegment (this, data)
            val () = 
               update this 
                  upd#bytesSent (fn x => x + Counter.fromInt used) 
                  set#lastSend  (Event.time ()) $
         in
            (used, ack)
         end
      
      fun killChannel this =
         case get#ready this of
            NONE => ()
          | SOME rts => rts destroyIt
      
      (* Erase all state needed for a resume (cooldowns and seqnums).
       * We recover any instreams; they are all reset.
       * Any outstream that was inprogress is also lost.
       * An outstream which has not been ackd yet, however, can resume.
       *
       * The reasoning we keep these outstreams alive is they may have
       * been created after contact was disrupted and caused a reconnect.
       *)
      fun wipeState this =
         let
            val recover = ref []
            val destroy = fn NONE => () | SOME record =>
               let
                  val (_, _, { stream, id=_, prefix }) = Heap.sub record
                  val () = Heap.updateValue (record, 
                           { stream = stream, id = nill, prefix = prefix }) 
               in
                  case stream of
                     IN_STREAM x => InStreamQueue.reset x
                   | OUT_STREAM x => 
                        if prefix = 0w0 then OutStreamQueue.reset x else
                        recover := record :: !recover
                   | NO_STREAM => () (* shouldn't happen really *)
               end
            
            val () =
               while not (Heap.isEmpty (get#heap this))
               do destroy (Heap.pop (get#heap this))
            
            fun restore record =
               let
                  val (_, _, { stream, id=_, prefix }) = Heap.sub record
                  val value = { stream=stream, id=nill, prefix=prefix }
                  val () = Heap.updateValue (record, value)
                  val stream = case stream of
                     OUT_STREAM x => x | _ => raise Fail "impossible case"
                  val key = { priority = Real32.maxFinite, lastSent = Time.fromSeconds 0 }
               in
                  if OutStreamQueue.isReset stream then () else
                  Heap.update (get#heap this, record, key)
               end
            
            val () = List.app restore (!recover)
            val () = Word16Array.modify (fn _ => nill) (get#cooldowns this)
         in
            update this
               set#seqNums            (Word8Array.tabulate (1, fn _ => 0w0))
               set#cooldownIndex      0
               set#inStreams          (Array.tabulate (1, fn _ => NONE))
               set#outStreams         (Array.tabulate (1, fn _ => FREE nill))
               set#writeFree          0w0 $
         end
         
      (* Keep the Host alive for up to 240 seconds during a reconnect.
       * A successful reconnect doesn't remove the poke, because
       * multi-homed multi-contact scenarios could then cause a wipe.
       *)
      fun poke this =
         case get#poked this of
            SOME e => Event.rescheduleIn (e, Time.fromSeconds 240)
          | NONE =>
            let
               fun unset _ = update this set#poked NONE $
               val e = Event.scheduleIn (Time.fromSeconds 240, unset)
            in
               update this set#poked (SOME e) $
            end
      
      fun destroy this =
         let
            val destroy = fn NONE => () | SOME record =>
               let
                  val (_, _, { stream, id=_, prefix }) = Heap.sub record
                  val () = Heap.updateValue (record, 
                           { stream = stream, id = nill, prefix = prefix }) 
               in
                  case stream of
                     IN_STREAM x => InStreamQueue.reset x
                   | OUT_STREAM x => OutStreamQueue.reset x
                   | NO_STREAM => () (* shouldn't happen really *)
               end
            
            val () =
               while not (Heap.isEmpty (get#heap this))
               do destroy (Heap.pop (get#heap this))
            
            val () = Event.execute (get#disconnect this)
            val () = Event.cancel  (get#disconnect this)
            val () = Option.app Event.cancel (get#poked this)
            val () = Option.app Ring.remove  (get#keepAlive this)
            val () = Word16Array.modify (fn _ => nill) (get#cooldowns this)
         in
            update this
               set#listen        (Hash.new ())
               set#ready         NONE
               set#heap          (Heap.new ())
               set#inStreams     (Array.tabulate (1, fn _ => NONE))
               set#outStreams    (Array.tabulate (1, fn _ => FREE nill))
               set#writeFree     0w0
               set#cooldownIndex 0
               set#seqNums       (Word8Array.tabulate (1, fn _ => 0w0))
               set#keepAlive     NONE
               set#poked         NONE
               set#reconnect     (fn _ => ())
               $
         end
         
      fun new { key, address, global, reconnect } =
         let
            val this = ref (T {
               key                = key,
               queuedOutOfOrder   = 0,
               queuedUnread       = 0,
               queuedInFlight     = 0,
               queuedToRetransmit = 0,
               bytesReceived      = 0,
               bytesSent          = 0,
               listen             = Hash.new (),
               global             = global,
               ready              = NONE,
               heap               = Heap.new (),
               inStreams          = Array.tabulate (1, fn _ => NONE),
               outStreams         = Array.tabulate (1, fn _ => FREE nill),
               writeFree          = 0w0,
               cooldownIndex      = 0,
               cooldowns          = Word16Array.tabulate (16, fn _ => nill),
               seqNums            = Word8Array.tabulate (1, fn _ => 0w0),
               lastSend           = Event.time (),
               lastReceive        = Event.time (),
               address            = address,
               disconnect         = Event.new (fn _ => ()),
               poked              = NONE,
               reconnect          = reconnect,
               keepAlive          = NONE })
            val () = 
               update this 
                  set#disconnect (Event.new (fn _ => killChannel this)) $
         in
            this
         end
   end


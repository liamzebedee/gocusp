(* SML glue code for CUSP c-bindings *)

(* -------------------- *
 *  Definitions, setup  *
 * -------------------- *)

type ptr = MLton.Pointer.t

(* CUSP structure comes from external configuration, e.g. realnetwork.sml *)
open CUSP

(* Handle buckets *)
val addressBucket : Address.t IdBucket.t = IdBucket.new()
val endpointBucket : EndPoint.t IdBucket.t = IdBucket.new()
val hostBucket : Host.t IdBucket.t = IdBucket.new()
val hostIteratorBucket : Host.t Iterator.t IdBucket.t = IdBucket.new()
val channelIteratorBucket : (Address.t * Host.t option) Iterator.t IdBucket.t = IdBucket.new()
val instreamBucket : InStream.t IdBucket.t = IdBucket.new()
val instreamIteratorBucket : InStream.t Iterator.t IdBucket.t = IdBucket.new()
val outstreamBucket : OutStream.t IdBucket.t = IdBucket.new()
val outstreamIteratorBucket : OutStream.t Iterator.t IdBucket.t = IdBucket.new()
val eventBucket : Event.t IdBucket.t = IdBucket.new()
val abortableBucket : (unit -> unit) IdBucket.t = IdBucket.new()
val publickeyBucket : Crypto.PublicKey.t IdBucket.t = IdBucket.new()
val privatekeyBucket : Crypto.PrivateKey.t IdBucket.t = IdBucket.new()

fun bucketOps bucket =
	let
		fun dup id =
			case IdBucket.sub (bucket, id) of
				SOME x => IdBucket.alloc (bucket, x)
				| NONE => ~1
		fun free id =
			(IdBucket.free (bucket, id); true) handle
				IdBucket.AlreadyFree => false
	in
		(dup, free)
	end

fun returnString (str : string, strLen : ptr) : string =
	let
		val () = MLton.Pointer.setInt32 (strLen, 0, Int32.fromInt (String.size str))
	in
		str
	end


(* -------------------- *
 *  Exported functions  *
 * -------------------- *)

fun main () =
	Main.run ()

(* Main loop with SIGINT handler *)
fun mainSigInt () =
	let
		fun sigIntHandler () = Main.stop ()
		val oldHandler = MLton.Signal.getHandler (Posix.Signal.int)
	in
		MLton.Signal.setHandler (Posix.Signal.int, MLton.Signal.Handler.simple (sigIntHandler))
		; Main.run ()
		; MLton.Signal.setHandler (Posix.Signal.int, oldHandler)
	end

fun mainIsRunning () =
	Main.isRunning ()

fun mainStop () =
	Main.stop ()

fun processEvents () =
	Main.poll ()


(* --- EndPoint --- *)

fun endpointNew (port : int, keyHandle : int, encrypt : bool, publicKeySuites : Word16.word,
		symmetricSuites: Word16.word) : int =
	let
		(* Exception handler *) (* TODO: pass errors to C *)
		fun handler exn =
			let
				fun fmtcode c = " (" ^ OS.errorName c ^ ")"
				fun fmt (msg, code) = msg ^ getOpt (Option.map fmtcode code, "")
			in
				case exn of
					OS.SysErr syserr => print ("Exception: " ^ fmt syserr ^ "\n")
				| _ => (print "Unknown exception!\n"; raise exn)
			end
		val options =
			SOME {
				encrypt   = encrypt,
				publickey = Suite.PublicKey.fromMask(publicKeySuites),
				symmetric = Suite.Symmetric.fromMask(symmetricSuites)
			}
	in
		case IdBucket.sub (privatekeyBucket, keyHandle) of
			SOME key => (IdBucket.alloc (endpointBucket,
				EndPoint.new { port = SOME port, key = key,
					handler = handler, entropy = Entropy.get, options = options }
				) handle _ => ~2)
			| NONE => ~1
	end


fun endpointDestroy (epHandle : int) : bool =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => (EndPoint.destroy ep; true)
		| NONE => false


fun endpointWhenSafeToDestroy (epHandle : int, cb : ptr, cbData : ptr) : int =
	let
		fun safeToDestroyCallback () =
			let
				val safeToDestroyCallbackP = _import * : ptr -> ptr -> unit;
			in
				(safeToDestroyCallbackP cb) (cbData)
			end
	in
		case IdBucket.sub (endpointBucket, epHandle) of
			SOME ep => IdBucket.alloc (abortableBucket,
				EndPoint.whenSafeToDestroy (ep, safeToDestroyCallback))
			| NONE => ~1
	end


fun endpointSetRate (epHandle : int, rate : int) : bool =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => (EndPoint.setRate (ep, rate); true)
		| NONE => false


fun endpointKey (epHandle : int) : int =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => IdBucket.alloc (privatekeyBucket, EndPoint.key ep)
		| NONE => ~1


fun endpointPublickeyStr (epHandle : int, suite : Word16.word, strLen : ptr) : string =
	let
		val pkSuite = Suite.PublicKey.fromValue(suite)
		val str = case IdBucket.sub (endpointBucket, epHandle) of
			SOME ep => Crypto.PublicKey.toString (Crypto.PrivateKey.pubkey (EndPoint.key ep, pkSuite ))
			| NONE => ""
	in
		returnString (str, strLen)
	end


fun endpointBytesSent (epHandle : int) : Int64.int =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => Int64.fromLarge (EndPoint.bytesSent(ep))
		| NONE => ~1


fun endpointBytesReceived (epHandle : int) : Int64.int =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => Int64.fromLarge(EndPoint.bytesReceived ep)
		| NONE => ~1


fun endpointContact (epHandle : int, addrHandle : int, service : Word16.word, cb : ptr, cbData : ptr) : int =
	let
		fun contactCallback (hs : (Host.t * OutStream.t) option) =
			let
				val contactCallbackP = _import * : ptr -> int * int * ptr -> unit;
				val hostHandle = case hs of
					SOME (h, _) => IdBucket.alloc (hostBucket, h)
					| NONE => ~1
				val osHandle = case hs of
					SOME (_, os) => IdBucket.alloc (outstreamBucket, os)
					| NONE => ~1
			in
				(contactCallbackP cb) (hostHandle, osHandle, cbData)
			end
	in
		case IdBucket.sub (endpointBucket, epHandle) of
			SOME ep =>
				(case IdBucket.sub (addressBucket, addrHandle) of
					SOME addr => IdBucket.alloc (abortableBucket,
						EndPoint.contact (ep, addr, service, contactCallback))
					| NONE => ~1
				)
			| NONE => ~1
	end


fun endpointHosts (epHandle : int) : int =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => IdBucket.alloc (hostIteratorBucket, EndPoint.hosts ep)
		| NONE => ~1


fun endpointChannels (epHandle : int) : int =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => IdBucket.alloc (channelIteratorBucket, EndPoint.channels ep)
		| NONE => ~1


fun endpointAdvertise (epHandle : int, service : Word16.word, cb : ptr, cbData : ptr) : bool =
	let
		val advertiseCallbackP = _import * : ptr -> int * int * ptr -> unit;
		fun advertiseCallback (host : Host.t, _ : Word16.word, stream : InStream.t) =
			let
				val hostHandle = IdBucket.alloc (hostBucket, host)
				val streamHandle = IdBucket.alloc (instreamBucket, stream)
			in
				(advertiseCallbackP cb) (hostHandle, streamHandle, cbData)
			end
	in
		case IdBucket.sub (endpointBucket, epHandle) of
			SOME ep => (ignore (EndPoint.advertise (ep, SOME service, advertiseCallback)); true)
			| NONE => false
	end


fun endpointUnadvertise (epHandle : int, service : Word16.word) : bool =
	case IdBucket.sub (endpointBucket, epHandle) of
		SOME ep => (EndPoint.unadvertise (ep, service); true)
		| NONE => false


val (endpointDup, endpointFree) = bucketOps endpointBucket


(* --- Address --- *)

fun addressFromString (str : string) =
	case Address.fromString(str) of
		SOME addr => IdBucket.alloc (addressBucket, addr)
		| NONE => ~2


fun addressToString (addrHandle : int, strLen : ptr) =
	let
		val str = case IdBucket.sub (addressBucket, addrHandle) of
			SOME addr => Address.toString addr
			| NONE => ""
	in
		returnString (str, strLen)
	end


val (addressDup, addressFree) = bucketOps addressBucket


(* --- Host --- *)

fun hostConnect (hostHandle : int, service : Word16.word) =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => IdBucket.alloc (outstreamBucket, Host.connect (host, service))
		| NONE => ~1


fun hostListen (hostHandle : int, cb : ptr, cbData : ptr) =
	let
		val listenCallbackP = _import * : ptr -> Word16.word * int * ptr -> unit;
		fun listenCallback (service : Word16.word, instream : InStream.t) =
			let
				val isHandle = IdBucket.alloc (instreamBucket, instream)
			in
				(listenCallbackP cb) (service, isHandle, cbData)
			end
	in
		case IdBucket.sub (hostBucket, hostHandle) of
			SOME host => Host.listen (host, listenCallback)
			| NONE => Word16.fromInt 0
	end


fun hostUnlisten (hostHandle : int, service : Word16.word) =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => (Host.unlisten (host, service); true)
		| NONE => false


fun hostKey (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => IdBucket.alloc (publickeyBucket, Host.key (host))
		| NONE => ~1


fun hostKeyStr (hostHandle : int, strLen : ptr) : string =
	let
		val str = case IdBucket.sub (hostBucket, hostHandle) of
			SOME host => Crypto.PublicKey.toString (Host.key (host))
			| NONE => ""
	in
		returnString (str, strLen)
	end


fun hostAddress (hostHandle : int) =
	let
		val address = case IdBucket.sub (hostBucket, hostHandle) of
			SOME host => Host.address (host)
			| NONE => NONE
	in
		case address of
			SOME a => IdBucket.alloc (addressBucket, a)
			| NONE => ~1
	end


fun hostToString (hostHandle : int, strLen : ptr) =
	let
		val host = IdBucket.sub (hostBucket, hostHandle)
		val addr = case host of
			SOME h => Host.address h
			| NONE => NONE
		val str = case host of
			SOME h => concat [ Crypto.PublicKey.toString (Host.key h),
				" <", getOpt (Option.map Address.toString addr, "*"), ">" ]
			| NONE => ""
	in
		returnString (str, strLen)
	end


fun hostInstreams (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => IdBucket.alloc (instreamIteratorBucket, Host.inStreams host)
		| NONE => ~1


fun hostOutstreams (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => IdBucket.alloc (outstreamIteratorBucket, Host.outStreams host)
		| NONE => ~1


fun hostQueuedOutOfOrder (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Host.queuedOutOfOrder host
		| NONE => ~1


fun hostQueuedUnread (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Host.queuedUnread host
		| NONE => ~1


fun hostQueuedInflight (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Host.queuedInflight host
		| NONE => ~1


fun hostQueuedToRetransmit (hostHandle : int) : int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Host.queuedToRetransmit host
		| NONE => ~1


fun hostBytesReceived (hostHandle : int) : Int64.int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Int64.fromLarge (Host.bytesReceived host)
		| NONE => ~1


fun hostBytesSent (hostHandle : int) : Int64.int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Int64.fromLarge (Host.bytesSent host)
		| NONE => ~1


fun hostLastReceive (hostHandle : int) : Int64.int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Time.toNanoseconds64 (Host.lastReceive host)
		| NONE => ~1


fun hostLastSend (hostHandle : int) : Int64.int =
	case IdBucket.sub (hostBucket, hostHandle) of
		SOME host => Time.toNanoseconds64 (Host.lastSend host)
		| NONE => ~1


val (hostDup, hostFree) = bucketOps hostBucket


(* --- Host::Iterator --- *)

fun hostIteratorHasNext (hostIteratorHandle : int) : bool =
	case IdBucket.sub (hostIteratorBucket, hostIteratorHandle) of
		SOME it => not (Iterator.null it)
		| NONE => false


fun hostIteratorNext (hostIteratorHandle : int) : int =
	case Option.mapPartial Iterator.getItem 
			(IdBucket.sub (hostIteratorBucket, hostIteratorHandle)) of
		SOME (h, it) =>
			(IdBucket.replace (hostIteratorBucket, hostIteratorHandle, it);
			IdBucket.alloc (hostBucket, h))
		| NONE => ~1


val (hostIteratorDup, hostIteratorFree) = bucketOps hostIteratorBucket


(* --- Channel::Iterator --- *)

fun channelIteratorHasNext (channelIteratorHandle : int) : bool =
	case IdBucket.sub (channelIteratorBucket, channelIteratorHandle) of
		SOME it => not (Iterator.null it)
		| NONE => false


fun channelIteratorNext (channelIteratorHandle : int, hostHandle : ptr) : int =
	case Option.mapPartial Iterator.getItem
			(IdBucket.sub (channelIteratorBucket, channelIteratorHandle)) of
		SOME ((addr, SOME h), it) =>
			(IdBucket.replace (channelIteratorBucket, channelIteratorHandle, it)
			; MLton.Pointer.setInt32 (hostHandle, 0, Int32.fromInt (IdBucket.alloc (hostBucket, h)))
			; IdBucket.alloc (addressBucket, addr))
		| SOME ((addr, NONE), it) =>
			(IdBucket.replace (channelIteratorBucket, channelIteratorHandle, it)
			; MLton.Pointer.setInt32 (hostHandle, 0, Int32.fromInt ~1)
			; IdBucket.alloc (addressBucket, addr))
		| NONE => ~1


val (channelIteratorDup, channelIteratorFree) = bucketOps channelIteratorBucket


(* --- InStream --- *)

fun instreamRead (streamHandle : int, maxCount : int, cb : ptr, cbData : ptr) =
	let
		val nullData = Array.tabulate (0, fn _ => 0w0)
		val readCallbackP = _import * : ptr -> int * int * Word8.word array * ptr -> unit;
		fun readCallback (status : InStream.status) =
			let
				val (arr, ofs, len) =
					case status of
						InStream.DATA data => Word8ArraySlice.base (data)
						| InStream.SHUTDOWN => (nullData, 0, ~2)
						| InStream.RESET => (nullData, 0, ~1)
			in
				(readCallbackP cb) (len, ofs, arr, cbData)
			end
	in
		case IdBucket.sub (instreamBucket, streamHandle) of
			SOME stream => (InStream.read (stream, maxCount, readCallback); true)
			| NONE => false
	end


fun instreamReset (streamHandle : int) =
	case IdBucket.sub (instreamBucket, streamHandle) of
		SOME stream => (InStream.reset stream; true)
		| NONE => false


fun instreamQueuedOutOfOrder (streamHandle : int) : int =
	case IdBucket.sub (instreamBucket, streamHandle) of
		SOME stream => InStream.queuedOutOfOrder stream
		| NONE => ~1


fun instreamQueuedUnread (streamHandle : int) : int =
	case IdBucket.sub (instreamBucket, streamHandle) of
		SOME stream => InStream.queuedUnread stream
		| NONE => ~1


fun instreamBytesReceived (streamHandle : int) : Int64.int =
	case IdBucket.sub (instreamBucket, streamHandle) of
		SOME stream => Int64.fromLarge (InStream.bytesReceived stream)
		| NONE => ~1


val (instreamDup, instreamFree) = bucketOps instreamBucket


(* --- InStream::Iterator --- *)

fun instreamIteratorHasNext (instreamIteratorHandle : int) : bool =
	case IdBucket.sub (instreamIteratorBucket, instreamIteratorHandle) of
		SOME it => not (Iterator.null it)
		| NONE => false


fun instreamIteratorNext (instreamIteratorHandle : int) : int =
	case Option.mapPartial Iterator.getItem 
			(IdBucket.sub (instreamIteratorBucket, instreamIteratorHandle)) of
		SOME (is, it) =>
			(IdBucket.replace (instreamIteratorBucket, instreamIteratorHandle, it);
			IdBucket.alloc (instreamBucket, is))
		| NONE => ~1


val (instreamIteratorDup, instreamIteratorFree) = bucketOps instreamIteratorBucket


(* --- OutStream --- *)

fun outstreamGetPriority (streamHandle : int) =
	case IdBucket.sub (outstreamBucket, streamHandle) of
		SOME stream => OutStream.getPriority (stream)
		| NONE => 0.0/0.0


fun outstreamSetPriority (streamHandle : int, prio : Real32.real) =
	case IdBucket.sub (outstreamBucket, streamHandle) of
		SOME stream => (OutStream.setPriority (stream, prio); true)
		| NONE => false


fun outstreamWrite (streamHandle : int, data : ptr, dataLen : int, cb : ptr, cbData : ptr) =
	let
		val dataVector = Word8Vector.tabulate (dataLen,
				fn i => MLton.Pointer.getWord8 (data, i))
		val readCallbackP = _import * : ptr -> int * ptr -> unit;
		fun writeCallback (status : OutStream.status) =
			let
				val statusInt = case status of
					OutStream.READY => 0
					| OutStream.RESET => ~1
			in
				(readCallbackP cb) (statusInt, cbData)
			end
	in
		case IdBucket.sub (outstreamBucket, streamHandle) of
			SOME stream => (OutStream.write (stream, dataVector, writeCallback); true)
			| NONE => false
	end


fun outstreamShutdown (streamHandle : int, cb : ptr, cbData : ptr) =
	let
		val shutdownCallbackP = _import * : ptr -> bool * ptr -> unit;
		fun shutdownCallback (success : bool) =
			(shutdownCallbackP cb) (success, cbData)
	in
		case IdBucket.sub (outstreamBucket, streamHandle) of
			SOME stream => (OutStream.shutdown (stream, shutdownCallback); true)
			| NONE => false
	end


fun outstreamReset (streamHandle : int) =
	case IdBucket.sub (outstreamBucket, streamHandle) of
		SOME stream => (OutStream.reset stream; true)
		| NONE => false


fun outstreamQueuedInflight (streamHandle : int) : int =
	case IdBucket.sub (outstreamBucket, streamHandle) of
		SOME stream => OutStream.queuedInflight stream
		| NONE => ~1


fun outstreamQueuedToRetransmit (streamHandle : int) : int =
	case IdBucket.sub (outstreamBucket, streamHandle) of
		SOME stream => OutStream.queuedToRetransmit stream
		| NONE => ~1


fun outstreamBytesSent (streamHandle : int) : Int64.int =
	case IdBucket.sub (outstreamBucket, streamHandle) of
		SOME stream => Int64.fromLarge (OutStream.bytesSent stream)
		| NONE => ~1


val (outstreamDup, outstreamFree) = bucketOps outstreamBucket


(* --- OutStream::Iterator --- *)

fun outstreamIteratorHasNext (outstreamIteratorHandle : int) : bool =
	case IdBucket.sub (outstreamIteratorBucket, outstreamIteratorHandle) of
		SOME it => not (Iterator.null it)
		| NONE => false


fun outstreamIteratorNext (outstreamIteratorHandle : int) : int =
	case Option.mapPartial Iterator.getItem
			(IdBucket.sub (outstreamIteratorBucket, outstreamIteratorHandle)) of
		SOME (os, it) =>
			(IdBucket.replace (outstreamIteratorBucket, outstreamIteratorHandle, it);
			IdBucket.alloc (outstreamBucket, os))
		| NONE => ~1


val (outstreamIteratorDup, outstreamIteratorFree) = bucketOps outstreamIteratorBucket


(* --- Event --- *)

fun eventTime () =
	Time.toNanoseconds64 (Event.time ())


val eventCallbackP = _import * : ptr -> int * ptr -> unit;

fun eventNew (cb : ptr, cbData : ptr) =
	let
		fun eventCallback (evt : Event.t) =
			(eventCallbackP cb) (IdBucket.alloc (eventBucket, evt), cbData)
	in
		IdBucket.alloc (eventBucket, Event.new (eventCallback))
	end


fun eventSchedule (time : Int64.int, cb : ptr, cbData : ptr) =
	let
		val t = Time.fromNanoseconds64 time;
		fun eventCallback (evt : Event.t) =
			(eventCallbackP cb) (IdBucket.alloc (eventBucket, evt), cbData)
	in
		IdBucket.alloc (eventBucket, Event.schedule (t, eventCallback))
	end


fun eventScheduleIn (time : Int64.int, cb : ptr, cbData : ptr) =
	let
		val t = Time.fromNanoseconds64 time;
		fun eventCallback (evt : Event.t) =
			(eventCallbackP cb) (IdBucket.alloc (eventBucket, evt), cbData)
	in
		IdBucket.alloc (eventBucket, Event.scheduleIn (t, eventCallback))
	end


fun eventReschedule (eventHandle : int, time : Int64.int) =
	let
		val t = Time.fromNanoseconds64 time;
	in
		case IdBucket.sub (eventBucket, eventHandle) of
			SOME event => (Event.reschedule (event, t); true)
			| NONE => false
	end


fun eventRescheduleIn (eventHandle : int, time : Int64.int) =
	let
		val t = Time.fromNanoseconds64 time;
	in
		case IdBucket.sub (eventBucket, eventHandle) of
			SOME event => (Event.rescheduleIn (event, t); true)
			| NONE => false
	end


fun eventCancel (eventHandle : int) =
	case IdBucket.sub (eventBucket, eventHandle) of
		SOME event => (Event.cancel (event); true)
		| NONE => false


fun eventTimeOfExecution (eventHandle : int) =
	case IdBucket.sub (eventBucket, eventHandle) of
		SOME event =>
			(case Event.timeOfExecution (event) of
				SOME time => Time.toNanoseconds64 (time)
				| NONE => Int64.fromInt (~1)
			)
		| NONE => Int64.fromInt (~2)


fun eventTimeTillExecution (eventHandle : int) =
	case IdBucket.sub (eventBucket, eventHandle) of
		SOME event =>
			(case Event.timeTillExecution (event) of
				SOME time => Time.toNanoseconds64 (time)
				| NONE => Int64.fromInt (~1)
			)
		| NONE => Int64.fromInt (~2)


fun eventIsScheduled (eventHandle : int) : bool =
	case IdBucket.sub (eventBucket, eventHandle) of
		SOME event => Event.isScheduled event
		| NONE => false


val (eventDup, eventFree) = bucketOps eventBucket


(* --- Abortable --- *)

fun abortableAbort (abortableHandle : int) : bool =
	case IdBucket.sub (abortableBucket, abortableHandle) of
		SOME abortable => (abortable (); true)
		| NONE => false


val (abortableDup, abortableFree) = bucketOps abortableBucket


(* --- SuiteSet --- *)

fun suitesetPublickeyAll () : Word16.word =
	Suite.PublicKey.toMask Suite.PublicKey.all

fun suitesetPublickeyDefaults () : Word16.word =
	Suite.PublicKey.toMask Suite.PublicKey.defaults

fun suitesetPublickeyCheapest (set : Word16.word) : Word16.word =
	case Suite.PublicKey.cheapest (Suite.PublicKey.fromMask set) of
		SOME suite => Suite.PublicKey.toValue suite
		| NONE => 0w0

fun suitesetSymmetricAll () : Word16.word =
	Suite.Symmetric.toMask Suite.Symmetric.all

fun suitesetSymmetricDefaults () : Word16.word =
	Suite.Symmetric.toMask Suite.Symmetric.defaults

fun suitesetSymmetricCheapest (set : Word16.word) : Word16.word =
	case Suite.Symmetric.cheapest (Suite.Symmetric.fromMask set) of
		SOME suite => Suite.Symmetric.toValue suite
		| NONE => 0w0


(* --- Suite --- *)

fun suitePublickeyName (value : Word16.word, strLen : ptr) : string =
	returnString (Suite.PublicKey.name (Suite.PublicKey.fromValue value), strLen)


fun suitePublickeyCost (value : Word16.word) : Real32.real =
	Suite.PublicKey.cost (Suite.PublicKey.fromValue value)


fun suiteSymmetricName (value : Word16.word, strLen : ptr) : string =
	returnString (Suite.Symmetric.name (Suite.Symmetric.fromValue value), strLen)


fun suiteSymmetricCost (value : Word16.word) : Real32.real =
	Suite.Symmetric.cost (Suite.Symmetric.fromValue value)


(* --- PublicKey --- *)

fun publickeyToString (pkHandle : int, strLen : ptr) : string =
	let
		val str = case IdBucket.sub (publickeyBucket, pkHandle) of
			SOME pk => Crypto.PublicKey.toString pk
			| NONE => ""
	in
		returnString (str, strLen)
	end


fun publickeySuite (pkHandle : int) : Word16.word =
	case IdBucket.sub (publickeyBucket, pkHandle) of
		SOME pk => Suite.PublicKey.toValue (Crypto.PublicKey.suite pk)
		| NONE => 0w0


val (publickeyDup, publickeyFree) = bucketOps publickeyBucket


(* --- PrivateKey --- *)

fun privatekeyNew () : int =
	IdBucket.alloc (privatekeyBucket, Crypto.PrivateKey.new { entropy = Entropy.get })


fun privatekeySave (pkHandle : int, password : string, strLen : ptr) : string =
	let
		val str = case IdBucket.sub (privatekeyBucket, pkHandle) of
			SOME pk => Crypto.PrivateKey.save (pk, { password = password })
			| NONE => ""
	in
		returnString (str, strLen)
	end


fun privatekeyLoad (key : string, password : string) : int =
	case Crypto.PrivateKey.load {password = password, key = key} of
		SOME pk => IdBucket.alloc (privatekeyBucket, pk)
		| NONE => ~1


fun privatekeyPubkey (pkHandle : int, sVal : Word16.word) : int =
	let
		val suite = Suite.PublicKey.fromValue sVal
	in
		case IdBucket.sub (privatekeyBucket, pkHandle) of
			SOME pk => IdBucket.alloc (publickeyBucket, Crypto.PrivateKey.pubkey (pk, suite))
			| NONE => ~1
	end


val (privatekeyDup, privatekeyFree) = bucketOps privatekeyBucket


(* --------- *
 *  Exports  *
 * --------- *)

val () = _export "cusp_main" : (unit -> unit) -> unit; main
val () = _export "cusp_main_sigint" : (unit -> unit) -> unit; mainSigInt
val () = _export "cusp_main_running" : (unit -> bool) -> unit; mainIsRunning
val () = _export "cusp_stop_main" : (unit -> unit) -> unit; mainStop
val () = _export "cusp_process_events" : (unit -> unit) -> unit; processEvents

(* EndPoint functions *)
val () = _export "cusp_endpoint_new" : (int * int * bool * Word16.word * Word16.word -> int) -> unit; endpointNew
val () = _export "cusp_endpoint_destroy" : (int -> bool) -> unit; endpointDestroy
val () = _export "cusp_endpoint_when_safe_to_destroy" : (int * ptr * ptr -> int) -> unit; endpointWhenSafeToDestroy
val () = _export "cusp_endpoint_set_rate" : (int * int -> bool) -> unit; endpointSetRate
val () = _export "cusp_endpoint_key" : (int -> int) -> unit; endpointKey
val () = _export "cusp_endpoint_publickey_str" : (int * Word16.word * ptr -> string) -> unit; endpointPublickeyStr
val () = _export "cusp_endpoint_bytes_sent" : (int -> Int64.int) -> unit; endpointBytesSent
val () = _export "cusp_endpoint_bytes_received" : (int -> Int64.int) -> unit; endpointBytesReceived
val () = _export "cusp_endpoint_contact" : (int * int * Word16.word * ptr * ptr -> int) -> unit; endpointContact
val () = _export "cusp_endpoint_hosts" : (int -> int) -> unit; endpointHosts
val () = _export "cusp_endpoint_channels" : (int -> int) -> unit; endpointChannels
val () = _export "cusp_endpoint_advertise" : (int * Word16.word * ptr * ptr -> bool) -> unit; endpointAdvertise
val () = _export "cusp_endpoint_unadvertise" : (int * Word16.word -> bool) -> unit; endpointUnadvertise
val () = _export "cusp_endpoint_dup" : (int -> int) -> unit; endpointDup
val () = _export "cusp_endpoint_free" : (int -> bool) -> unit; endpointFree

(* Address functions *)
val () = _export "cusp_address_from_string" : (string -> int) -> unit; addressFromString
val () = _export "cusp_address_to_string" : (int * ptr -> string) -> unit; addressToString
val () = _export "cusp_address_dup" : (int -> int) -> unit; addressDup
val () = _export "cusp_address_free" : (int -> bool) -> unit; addressFree

(* Host functions *)
val () = _export "cusp_host_connect" : (int * Word16.word -> int) -> unit; hostConnect
val () = _export "cusp_host_listen" : (int * ptr * ptr -> Word16.word) -> unit; hostListen
val () = _export "cusp_host_unlisten" : (int * Word16.word -> bool) -> unit; hostUnlisten
val () = _export "cusp_host_key" : (int -> int) -> unit; hostKey
val () = _export "cusp_host_key_str" : (int * ptr -> string) -> unit; hostKeyStr
val () = _export "cusp_host_address" : (int -> int) -> unit; hostAddress
val () = _export "cusp_host_to_string" : (int * ptr -> string) -> unit; hostToString
val () = _export "cusp_host_instreams" : (int -> int) -> unit; hostInstreams
val () = _export "cusp_host_outstreams" : (int -> int) -> unit; hostOutstreams
val () = _export "cusp_host_queued_out_of_order" : (int -> int) -> unit; hostQueuedOutOfOrder
val () = _export "cusp_host_queued_unread" : (int -> int) -> unit; hostQueuedUnread
val () = _export "cusp_host_queued_inflight" : (int -> int) -> unit; hostQueuedInflight
val () = _export "cusp_host_queued_to_retransmit" : (int -> int) -> unit; hostQueuedToRetransmit
val () = _export "cusp_host_bytes_received" : (int -> Int64.int) -> unit; hostBytesReceived
val () = _export "cusp_host_bytes_sent" : (int -> Int64.int) -> unit; hostBytesSent
val () = _export "cusp_host_last_receive" : (int -> Int64.int) -> unit; hostLastReceive
val () = _export "cusp_host_last_send" : (int -> Int64.int) -> unit; hostLastSend
val () = _export "cusp_host_dup" : (int -> int) -> unit; hostDup
val () = _export "cusp_host_free" : (int -> bool) -> unit; hostFree

(* Host::Iterator functions *)
val () = _export "cusp_host_iterator_has_next" : (int -> bool) -> unit; hostIteratorHasNext
val () = _export "cusp_host_iterator_next" : (int -> int) -> unit; hostIteratorNext
val () = _export "cusp_host_iterator_dup" : (int -> int) -> unit; hostIteratorDup
val () = _export "cusp_host_iterator_free" : (int -> bool) -> unit; hostIteratorFree

(* Channel::Iterator functions *)
val () = _export "cusp_channel_iterator_has_next" : (int -> bool) -> unit; channelIteratorHasNext
val () = _export "cusp_channel_iterator_next" : (int * ptr -> int) -> unit; channelIteratorNext
val () = _export "cusp_channel_iterator_dup" : (int -> int) -> unit; channelIteratorDup
val () = _export "cusp_channel_iterator_free" : (int -> bool) -> unit; channelIteratorFree

(* InStream functions *)
val () = _export "cusp_instream_read" : (int * int * ptr * ptr -> bool) -> unit; instreamRead
val () = _export "cusp_instream_reset" : (int -> bool) -> unit; instreamReset
val () = _export "cusp_instream_queued_out_of_order" : (int -> int) -> unit; instreamQueuedOutOfOrder
val () = _export "cusp_instream_queued_unread" : (int -> int) -> unit; instreamQueuedUnread
val () = _export "cusp_instream_bytes_received" : (int -> Int64.int) -> unit; instreamBytesReceived
val () = _export "cusp_instream_dup" : (int -> int) -> unit; instreamDup
val () = _export "cusp_instream_free" : (int -> bool) -> unit; instreamFree

(* InStream::Iterator functions *)
val () = _export "cusp_instream_iterator_has_next" : (int -> bool) -> unit; instreamIteratorHasNext
val () = _export "cusp_instream_iterator_next" : (int -> int) -> unit; instreamIteratorNext
val () = _export "cusp_instream_iterator_dup" : (int -> int) -> unit; instreamIteratorDup
val () = _export "cusp_instream_iterator_free" : (int -> bool) -> unit; instreamIteratorFree

(* OutStream functions *)
val () = _export "cusp_outstream_get_priority" : (int -> Real32.real) -> unit; outstreamGetPriority
val () = _export "cusp_outstream_set_priority" : (int * Real32.real -> bool) -> unit; outstreamSetPriority
val () = _export "cusp_outstream_write" : (int * ptr * int * ptr * ptr -> bool) -> unit; outstreamWrite
val () = _export "cusp_outstream_shutdown" : (int * ptr * ptr -> bool) -> unit; outstreamShutdown
val () = _export "cusp_outstream_reset" : (int -> bool) -> unit; outstreamReset
val () = _export "cusp_outstream_queued_inflight" : (int -> int) -> unit; outstreamQueuedInflight
val () = _export "cusp_outstream_queued_to_retransmit" : (int -> int) -> unit; outstreamQueuedToRetransmit
val () = _export "cusp_outstream_bytes_sent" : (int -> Int64.int) -> unit; outstreamBytesSent
val () = _export "cusp_outstream_dup" : (int -> int) -> unit; outstreamDup
val () = _export "cusp_outstream_free" : (int -> bool) -> unit; outstreamFree

(* OutStream::Iterator functions *)
val () = _export "cusp_outstream_iterator_has_next" : (int -> bool) -> unit; outstreamIteratorHasNext
val () = _export "cusp_outstream_iterator_next" : (int -> int) -> unit; outstreamIteratorNext
val () = _export "cusp_outstream_iterator_dup" : (int -> int) -> unit; outstreamIteratorDup
val () = _export "cusp_outstream_iterator_free" : (int -> bool) -> unit; outstreamIteratorFree

(* Event functions *)
val () = _export "cusp_event_time" : (unit -> Int64.int) -> unit; eventTime
val () = _export "cusp_event_new" : (ptr * ptr -> int) -> unit; eventNew
val () = _export "cusp_event_schedule" : (Int64.int * ptr * ptr -> int) -> unit; eventSchedule
val () = _export "cusp_event_schedule_in" : (Int64.int * ptr * ptr -> int) -> unit; eventScheduleIn
val () = _export "cusp_event_reschedule" : (int * Int64.int -> bool) -> unit; eventReschedule
val () = _export "cusp_event_reschedule_in" : (int * Int64.int -> bool) -> unit; eventRescheduleIn
val () = _export "cusp_event_cancel" : (int -> bool) -> unit; eventCancel
val () = _export "cusp_event_time_of_execution" : (int -> Int64.int) -> unit; eventTimeOfExecution
val () = _export "cusp_event_time_till_execution" : (int -> Int64.int) -> unit; eventTimeTillExecution
val () = _export "cusp_event_is_scheduled" : (int -> bool) -> unit; eventIsScheduled
val () = _export "cusp_event_dup" : (int -> int) -> unit; eventDup
val () = _export "cusp_event_free" : (int -> bool) -> unit; eventFree

(* Abortable functions *)
val () = _export "cusp_abortable_abort" : (int -> bool) -> unit; abortableAbort
val () = _export "cusp_abortable_dup" : (int -> int) -> unit; abortableDup
val () = _export "cusp_abortable_free" : (int -> bool) -> unit; abortableFree

(* SuiteSet functions *)
val () = _export "cusp_suiteset_publickey_all" : (unit -> Word16.word) -> unit; suitesetPublickeyAll
val () = _export "cusp_suiteset_publickey_defaults" : (unit -> Word16.word) -> unit; suitesetPublickeyDefaults
val () = _export "cusp_suiteset_publickey_cheapest" : (Word16.word -> Word16.word) -> unit; suitesetPublickeyCheapest
val () = _export "cusp_suiteset_symmetric_all" : (unit -> Word16.word) -> unit; suitesetSymmetricAll
val () = _export "cusp_suiteset_symmetric_defaults" : (unit -> Word16.word) -> unit; suitesetSymmetricDefaults
val () = _export "cusp_suiteset_symmetric_cheapest" : (Word16.word -> Word16.word) -> unit; suitesetSymmetricCheapest

(* Suite functions *)
val () = _export "cusp_suite_publickey_name" : (Word16.word * ptr -> string) -> unit; suitePublickeyName
val () = _export "cusp_suite_publickey_cost" : (Word16.word -> Real32.real) -> unit; suitePublickeyCost
val () = _export "cusp_suite_symmetric_name" : (Word16.word * ptr -> string) -> unit; suiteSymmetricName
val () = _export "cusp_suite_symmetric_cost" : (Word16.word -> Real32.real) -> unit; suiteSymmetricCost

(* PublicKey functions *)
val () = _export "cusp_publickey_to_string" : (int * ptr -> string) -> unit; publickeyToString
val () = _export "cusp_publickey_suite" : (int -> Word16.word) -> unit; publickeySuite
val () = _export "cusp_publickey_dup" : (int -> int) -> unit; publickeyDup
val () = _export "cusp_publickey_free" : (int -> bool) -> unit; publickeyFree

(* PrivateKey functions *)
val () = _export "cusp_privatekey_new" : (unit -> int) -> unit; privatekeyNew
val () = _export "cusp_privatekey_save" : (int * string * ptr -> string) -> unit; privatekeySave
val () = _export "cusp_privatekey_load" : (string * string -> int) -> unit; privatekeyLoad
val () = _export "cusp_privatekey_pubkey" : (int * Word16.word -> int) -> unit; privatekeyPubkey
val () = _export "cusp_privatekey_dup" : (int -> int) -> unit; privatekeyDup
val () = _export "cusp_privatekey_free" : (int -> bool) -> unit; privatekeyFree


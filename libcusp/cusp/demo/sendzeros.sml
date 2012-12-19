structure CUSP = CUSP(structure UDP = UDP4
                      structure Event = Main.Event)
open CUSP

fun handler exn =
   let
      fun fmtcode c = " (" ^ OS.errorName c ^ ")"
      fun fmt (msg, code) = msg ^ getOpt (Option.map fmtcode code, "")
   in
      case exn of
         OS.SysErr syserr => print ("Exception: " ^ fmt syserr ^ "\n")
       | _ => (print "Unknown exception!\n"; raise exn)
   end
  
val key = Crypto.PrivateKey.new { entropy = Entropy.get }
(*val key = valOf (Crypto.PrivateKey.load { password="", key="AB83A01487F6BD8048F500D1AA3F08B36EF2AD4788EDA42D2C784032289CACA1CA1D6049BC901F5C8209FEE8DBAAB7D85222239034F765CC3BB824950365743356864C61658FE6B2" })*)

val t = 
   EndPoint.new { 
      port    = NONE, 
      key     = key,
      handler = handler,
      entropy = Entropy.get,
      options = SOME { 
         encrypt   = false,
         publickey = Suite.PublicKey.defaults,
         symmetric = Suite.Symmetric.defaults
   }  }

val zeros = Word8Vector.tabulate (32768, fn _ => 0w0)

fun quit _ =
   let
      val () = print ">>>>> Done sending, shutting down <<<<<\n"
      fun safe () = (print "All channels closed; terminating.\n"
                     ; EndPoint.destroy t; Main.stop ())
      val _ = EndPoint.whenSafeToDestroy (t, safe)
   in
      ()
   end

fun send stream =
    let
       fun next 10000 _ = OutStream.shutdown (stream, quit)
         | next i OutStream.READY = OutStream.write (stream, zeros, next (i+1))
         | next _ OutStream.RESET = print "Reset??\n"
    in
       OutStream.write (stream, zeros, next 1)
    end

val ok = fn
   NONE => print "Failed to connect\n"
 | SOME (h, stream) =>
    let
       val () = print "Connected!\n"
       val () = send stream
    in
       ()
    end

val host = 
   case Address.fromString (hd (CommandLine.arguments ())) of
      SOME x => x
    | NONE => (print "Couldn't resolve target name!\n"; raise Option)

val () = print ("Contacting " ^ Address.toString host ^ "...\n")
val _ = EndPoint.contact (t, host, 0w23, ok)

fun stats event =
   let
      fun wstream w = 
         print ("Write-Stream\n" ^
                " Sent: " ^ LargeInt.toString (OutStream.bytesSent w) ^ "\n" ^
                " InF:  " ^ Int.toString (OutStream.queuedInflight w) ^ "\n" ^
                " ToX:  " ^ Int.toString (OutStream.queuedToRetransmit w) ^ "\n")
      fun rstream r =
         print ("Read-Stream\n" ^
                " Recv: " ^ LargeInt.toString (InStream.bytesReceived r) ^ "\n" ^
                " OoO:  " ^ Int.toString (InStream.queuedOutOfOrder r) ^ "\n" ^
                " UnR:  " ^ Int.toString (InStream.queuedUnread r) ^ "\n")
      fun host h =
         print ("Host " ^ Crypto.PublicKey.toString (Host.key h) ^ "\n" ^
                " Sent: " ^ LargeInt.toString (Host.bytesSent h) ^ "\n" ^
                " Recv: " ^ LargeInt.toString (Host.bytesReceived h) ^ "\n" ^
                " OoO:  " ^ Int.toString (Host.queuedOutOfOrder h) ^ "\n" ^
                " UnR:  " ^ Int.toString (Host.queuedUnread h) ^ "\n" ^
                " InF:  " ^ Int.toString (Host.queuedInflight h) ^ "\n" ^
                " ToX:  " ^ Int.toString (Host.queuedToRetransmit h) ^ "\n")
      fun chan (a, h) =
         print ("Channel " ^ Address.toString a ^ " => " ^
                getOpt (Option.map (Crypto.PublicKey.toString o Host.key) h, "---") ^ "\n")
      fun endpoint e =
         print ("EndPoint\n" ^
                " Sent: " ^ LargeInt.toString (EndPoint.bytesSent e) ^ "\n" ^
                " Recv: " ^ LargeInt.toString (EndPoint.bytesReceived e) ^ "\n")
      
      fun happ h = (host h
                    ; Iterator.app rstream (Host.inStreams h)
                    ; Iterator.app wstream (Host.outStreams h))
      val () = endpoint t
      val () = Iterator.app chan (EndPoint.channels t)
      val () = Iterator.app happ (EndPoint.hosts t)
   in
      Main.Event.rescheduleIn (event, Time.fromSeconds 1)
   end
  
val _ = Main.Event.scheduleIn (Time.fromSeconds 1, stats)
val () = Main.run ()

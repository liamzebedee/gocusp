structure CUSP = CUSP(structure UDP = UDP4
                      structure Event = Main.Event)
open CUSP

fun remoteName host =
   let
      val toString = Option.map Address.toString o Host.address
   in
      concat [ Crypto.PublicKey.toString (Host.key host),
               " <", getOpt (toString host, "*"), ">" ]
   end

fun accept (host, _, stream) =
    let
       val () = print ("Accept from channel " ^ remoteName host ^ "\n")
       
       fun echo x = print (Byte.bytesToString (Word8ArraySlice.vector x) ^ "\n")
       val rec get = fn
          InStream.DATA x   => (echo x; InStream.read (stream, ~1, get))
        | InStream.SHUTDOWN => print "InStream ends.\n"
        | InStream.RESET    => print "InStream reset.\n"
    in
       InStream.read (stream, ~1, get)
    end

val host = fn
   NONE => print "Failed to contact\n"
 | SOME (host, stream) =>
     let
        val () = print ("Connect to " ^ remoteName host ^ "\n")
        val payload = Byte.stringToBytes "Hello world."
        val rec write = fn
           () => OutStream.write (stream, payload, shutdown)
        and shutdown = fn
           OutStream.RESET => print "OutStream reset.\n"
         | OutStream.READY => OutStream.shutdown (stream, done)
        and done = fn
           true => print "Sent\n"
         | false => print "Unack'd\n"
     in
        write ()
     end

fun handler exn =
   let
      fun fmtcode c = " (" ^ OS.errorName c ^ ")"
      fun fmt (msg, code) = msg ^ getOpt (Option.map fmtcode code, "")
   in
      case exn of
         OS.SysErr syserr => print ("Exception: " ^ fmt syserr ^ "\n")
       | _ => (print "Unknown exception!\n"; raise exn)
   end
  
val t = 
   EndPoint.new { 
      port    = SOME 8585, 
      key     = Crypto.PrivateKey.new { entropy = Entropy.get },
      handler = handler,
      entropy = Entropy.get,
      options = NONE }

val _ = EndPoint.advertise (t, SOME 0w23, accept)
val _ = 
   case CommandLine.arguments () of
      [peer] => EndPoint.contact (t, valOf (Address.fromString peer), 0w23, host)
    | _ => raise Domain

val attempt = ref 0
fun sigIntHandler () = 
   if !attempt = 0 then
      let
         fun done () = (print "Terminating...\n" 
                        ; EndPoint.destroy t; Main.stop ())
         val _ = EndPoint.whenSafeToDestroy (t, done)
         val () = attempt := !attempt + 1
         val () = print "User interrupt! -- attempting to quit.\n"
      in
         Main.REHOOK
      end
   else
      let
         val () = Main.stop ()
         val () = print "FORCED TO QUIT UNCLEANLY.\n"
      in
         Main.REHOOK
      end

val _ = Main.signal (Posix.Signal.int, sigIntHandler)
val () = Main.run ()

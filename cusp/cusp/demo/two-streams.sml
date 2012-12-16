structure CUSP = CUSP(structure UDP = UDP4
                      structure Event = Main.Event)
open CUSP

val zeros = Word8Vector.tabulate (32768, fn _ => 0w0)

fun send stream =
    let
       fun next OutStream.READY = OutStream.write (stream, zeros, next)
         | next OutStream.RESET = print "Reset??\n"
    in
       OutStream.write (stream, zeros, next)
    end

fun ok NONE = print "Failed to connect\n"
  | ok (SOME (h, stream)) =
    let
       val () = print "Connected!\n"
       val _ = Main.Event.scheduleIn (Time.fromSeconds 20, 
                                      fn _ => send (Host.connect (h, 0w23)))
    in
       send stream
    end

val host = 
   case Address.fromString (hd (CommandLine.arguments ())) of
      SOME x => x
    | NONE => (print "Couldn't resolve target name!\n"; raise Option)

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
      port    = NONE, 
      key     = Crypto.PrivateKey.new { entropy = Entropy.get },
      handler = handler,
      entropy = Entropy.get,
      options = NONE }

val () = print ("Contacting " ^ Address.toString host ^ "...\n")
val _ = EndPoint.contact (t, host, 0w23, ok)

val () = Main.run ()

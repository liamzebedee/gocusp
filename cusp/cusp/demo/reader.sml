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
  
val t = 
   EndPoint.new { 
      port    = SOME 8585, 
      key     = Crypto.PrivateKey.new { entropy = Entropy.get },
      handler = handler,
      entropy = Entropy.get,
      options = SOME { 
         encrypt   = false,
         publickey = Suite.PublicKey.defaults,
         symmetric = Suite.Symmetric.defaults
   }  }

val ticks = 100 (* ms *)

val last : LargeInt.int ref = ref 0
val count : LargeInt.int ref = ref 0
fun tick e =
   let
      val ns = Time.toNanoseconds (Event.time ())
      val ms = ns div 1000000
      val ms = (ms div ticks) * ticks
      val amount = !count - !last
      val hosts = Iterator.length (EndPoint.hosts t)
      val chans = Iterator.length (EndPoint.channels t)
      val () = print (LargeInt.toString ms ^ " " ^ Int.toString chans ^ " " ^ Int.toString hosts ^ " " ^ LargeInt.toString amount ^ "\n")
      val () = last := !count
   in
      Main.Event.rescheduleIn (e, Time.fromMilliseconds (Int.fromLarge ticks))
   end

fun connect (host, _, stream) =
    let
       val () = print "# ***************** Connect\n"
       fun echo x = print (Byte.bytesToString (Word8ArraySlice.vector x) ^ "\n")
       val rec get = fn
          InStream.DATA x   => 
             (count := !count + Int.toLarge (Word8ArraySlice.length x)
              ; InStream.read (stream, ~1, get))
        | InStream.SHUTDOWN => print "Stream ends\n"
        | InStream.RESET    => print "Reset??\n"
    in
       InStream.read (stream, ~1, get)
    end

val _ = EndPoint.advertise (t, SOME 0w23, connect)
val _ = Main.Event.scheduleIn (Time.zero, tick)

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

structure PacketFormat =
   struct
      type bits = {
         publickey : Suite.PublicKey.set,
         symmetric : Suite.Symmetric.set,
         noEncrypt : bool,
         resume    : bool
      }
      
      datatype ('a, 'b) message = 
         HELLO   of { remote : bits, 
                      B      : 'a,
                      Y      : 'a }
       | WELCOME of { remote : bits,
                      B      : 'a,
                      Y      : 'a }
       | FAIL    of { remote : bits }
       | DATA    of { acklen : int, 
                      finish : bool, 
                      asn    : 'b,
                      tsn    : 'b }
       | NOSTATE of { tail : Word8Vector.vector }
       | CORRUPT
      
      local
         open Serial
         val header = aggregate tuple2 `word32b `word32b $
      in
         val { parseSlice, writeSlice, ... } = methods header
      end
      
      fun parse (packet, (tsn, asn)) =
         let
            open Word8ArraySlice
            val (w1, w2) = parseSlice packet
            val w16 = Word16.fromLarge o Word32.toLarge
            
            fun bits () = {
               publickey = Suite.PublicKey.fromMask (w16 (Word32.>> (w2, 0w16))),
               symmetric = Suite.Symmetric.fromMask (w16 w2),
               resume    = Word32.andb (w1, 0w1) <> 0w0, 
               noEncrypt = Word32.andb (w1, 0w2) <> 0w0
            }
            
            fun keys () =
               let
                  val remote as { publickey, ... } = bits ()
                  val suite = valOf (Suite.PublicKey.cheapest publickey)
                  val { publicLength, ephemeralLength, ... } =
                     Crypto.publickeyInfo suite
                  val B = subslice (packet, 8, SOME publicLength)
                  val Y = subslice (packet, 8+publicLength, SOME ephemeralLength)
               in
                  { remote = remote, B = B, Y = Y }
               end
            
            fun seqs finish =
               let
                  val acklen = Word32.toInt (Word32.>> (w2, 0w28))
                  val tsnl = Word32.fromLargeInt tsn
                  val asnl = Word32.fromLargeInt asn
                  val tsn28 = Word28.fromLarge (Word32.toLarge (w1 - tsnl))
                  val asn28 = Word28.fromLarge (Word32.toLarge (w2 - asnl))
                  val tsn = tsn + Word28.toLargeIntX tsn28
                  val asn = asn + Word28.toLargeIntX asn28
               in
                  { finish = finish, acklen = acklen, asn = asn, tsn = tsn }
               end
            
            fun tail () =
               let
                  val out = vector (subslice (packet, 8, NONE))
               in
                  if Word8Vector.length out = 0 then raise Subscript else out
               end

         in
            case Word32.>> (w1, 0w28) of
               0w0 => NOSTATE { tail = tail () }
             | 0w1 => FAIL { remote = bits () }
             | 0w2 => HELLO (keys ())
             | 0w3 => WELCOME (keys ())
             | 0w4 => CORRUPT (* CHALLENGE *)
             | 0w5 => CORRUPT (* RESPONSE *)
             | 0w6 => DATA (seqs false)
             | 0w7 => DATA (seqs true)
             | _ => CORRUPT
         end
         handle _ => CORRUPT
      
      fun write (packet, m) =
         let
            val (a, i, _) = Word8ArraySlice.base packet
            
            fun nostate tail =
               let
                  val () = writeSlice (packet, (0w0, 0w0))
                  val () = Array.copyVec { src = tail, dst = a, di = i + 8 }
               in
                  Word8Vector.length tail + 8
               end
            
            fun bits (ty, { publickey, symmetric, resume, noEncrypt }) =
               let
                  val w1 = Word32.<< (ty, 0w28)
                  val w1 = Word32.orb (w1, if resume    then 0w1 else 0w0)
                  val w1 = Word32.orb (w1, if noEncrypt then 0w2 else 0w0)
                  val w32 = Word32.fromLarge o Word16.toLarge
                  val pk = w32 (Suite.PublicKey.toMask publickey)
                  val sy = w32 (Suite.Symmetric.toMask symmetric)
                  val w2 = Word32.orb (Word32.<< (pk, 0w16), sy)
                  val () = writeSlice (packet, (w1, w2))
               in
                  8
               end
            
            fun keys (ty, { remote, B, Y }) =
               let
                  val off = bits (ty, remote)
                  val Blen = Word8Vector.length B
                  val Ylen = Word8Vector.length Y
                  val () = Array.copyVec { src = B, dst = a, di = i+off }
                  val () = Array.copyVec { src = Y, dst = a, di = i+off+Blen }
               in
                  off + Blen + Ylen
               end
            
            fun data { acklen, finish, asn, tsn } =
               let
                  val tag = if finish then 0w7 else 0w6
                  val acklen = Word32.fromInt (Int.min (acklen, 15))
                  open Word32
                  val w1 = orb (<< (tag,    0w28), andb (tsn, 0wxfffffff))
                  val w2 = orb (<< (acklen, 0w28), andb (asn, 0wxfffffff))
                  val () = writeSlice (packet, (w1, w2))
               in
                  8
               end
         in
            case m of
               NOSTATE { tail } => nostate tail
             | FAIL { remote } => bits (0w1, remote)
             | HELLO   h => keys (0w2, h)
             | WELCOME w => keys (0w3, w)
             | DATA d => data d
             | CORRUPT => raise Fail "Asked to serialize a corrupt packet??"
         end
      
      fun extractTail data =
         let
            val off = Int.max (Word8ArraySlice.length data-16, 0)
            val tail = Word8ArraySlice.subslice (data, off, NONE)
         in
            Word8ArraySlice.vector tail
         end
   end

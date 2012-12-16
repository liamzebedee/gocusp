structure Crypto =
   struct
      structure PublicKey =
         struct
            type t = Suite.PublicKey.suite * Word8Vector.vector
            type suite = Suite.PublicKey.suite
            
            fun hash (_, v) = Hash.word8vector v
            fun eq ((sa, va), (sb, vb)) =
              sa = sb andalso va = vb
            fun toString (_, v) = WordToString.fromBytes v
            fun suite (s, _) = s
         end

      structure PrivateKey =
         struct
            type t =
               (Word64.word) *
               (LargeInt.int * Curve25519.t)
            
            local
               open Serial
               val entropy = aggregate tuple2
                  `word64l 
                  `(intinfl Curve25519.length) $
               val key = aggregate tuple3
                  `word64l
                  `(intinfl Curve25519.length) `Curve25519.t $
            in
               val { length, fromVector=create, ... } = methods entropy
               val { toVector, fromVector, ... } = methods key
            end
            
            fun new { entropy } = 
               let
                  val (xor, curve25519) = create (entropy length)
                  val curve25519 = Curve25519.clamp curve25519
               in
                  ((xor),
                   (curve25519, Curve25519.power (Curve25519.generator (), curve25519))
                  )
               end
            
            fun save (((x), (ce, cg)), {password=_}) =
               WordToString.fromBytes (toVector (x, ce, cg))
            
            fun load { password=_, key } =
               let
                  fun f (x, e, g) = ((x), (e, g))
                  val x = 
                     (SOME o f o fromVector o valOf o WordToString.toBytes) key
                     handle _ => NONE
               in
                  x
               end
            
            local
              val { toVector=vCurve, ... } = Serial.methods Curve25519.t
              val { toVector=vXor,   ... } = Serial.methods Serial.word64l
              open Suite.PublicKey
            in
              fun pubkey (((x), (_, g)), suite) = 
                 if suite = xor        then (suite, vXor   x) else
                 if suite = curve25519 then (suite, vCurve g) else
                 raise Fail "pubkey for non-existant pub-key suite requested"
            end
         end
   end

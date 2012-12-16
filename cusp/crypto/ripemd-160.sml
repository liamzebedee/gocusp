structure RIPEMD160 :> COMPRESSOR =
   struct
      type state = 
         Word32.word * Word32.word * Word32.word * Word32.word * Word32.word
      
      open Word32
      val rol = MLton.Word32.rol
      
      infix 6 orb xorb andb
      infix 5 rol
      
      (* the five basic functions F(), G() and H() *)
      fun F (x, y, z) = x xorb y xorb z
      fun G (x, y, z) = (x andb y) orb (notb x andb z)
      fun H (x, y, z) = (x orb notb y) xorb z
      fun I (x, y, z) = (x andb z) orb (y andb notb z) 
      fun J (x, y, z) = x xorb (y orb notb z)
      
      fun FF (a, b, c, d, e, x, s) =
         let
            val a = a + F (b, c, d) + x
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun GG (a, b, c, d, e, x, s) =
         let
            val a = a + G(b, c, d) + x + 0wx5a827999
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun HH (a, b, c, d, e, x, s) =
         let
            val a = a + H(b, c, d) + x + 0wx6ed9eba1
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun II (a, b, c, d, e, x, s) =
         let
            val a = a + I(b, c, d) + x + 0wx8f1bbcdc
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun JJ (a, b, c, d, e, x, s) =
         let
            val a = a + J(b, c, d) + x + 0wxa953fd4e
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun FFF (a, b, c, d, e, x, s) =
         let
            val a = a + F(b, c, d) + x
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun GGG (a, b, c, d, e, x, s) =
         let
            val a = a + G(b, c, d) + x + 0wx7a6d76e9
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun HHH (a, b, c, d, e, x, s) =
         let
            val a = a + H(b, c, d) + x + 0wx6d703ef3
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun III (a, b, c, d, e, x, s) =
         let
            val a = a + I(b, c, d) + x + 0wx5c4dd124
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      fun JJJ (a, b, c, d, e, x, s) =
         let
            val a = a + J(b, c, d) + x + 0wx50a28be6
            val a = (a rol s) + e
            val c = c rol 0w10
         in
            (a, c)
         end
      
      local
         open Serial
         val w32x16b = aggregate tuple16
            `word32b `word32b `word32b `word32b
            `word32b `word32b `word32b `word32b
            `word32b `word32b `word32b `word32b
            `word32b `word32b `word32b `word32b $
         val w32x5b = aggregate tuple5
            `word32b `word32b `word32b `word32b `word32b $
      in
         val { parseSlice, length=inputLength,  ... } = methods w32x16b
         val { writeSlice, length=outputLength, ... } = methods w32x5b
      end
      
      fun compress ((a, b, c, d, e), s) =
         let
            val (X0, X1, X2, X3, X4, X5, X6, X7,
                 X8, X9, XA, XB, XC, XD, XE, XF) = parseSlice s
            fun X  0 = X0 | X 1  = X1 | X  2 = X2 | X  3 = X3
              | X  4 = X4 | X 5  = X5 | X  6 = X6 | X  7 = X7
              | X  8 = X8 | X 9  = X9 | X 10 = XA | X 11 = XB
              | X 12 = XC | X 13 = XD | X 14 = XE | X 15 = XF
              | X _ = raise Domain
            
            val (aa, bb, cc, dd, ee) = (a, b, c, d, e)
            val (aaa, bbb, ccc, ddd, eee) = (a, b, c, d, e)
            
            (* round 1 *)
            val (aa, cc) = FF(aa, bb, cc, dd, ee, X  0, 0w11)
            val (ee, bb) = FF(ee, aa, bb, cc, dd, X  1, 0w14)
            val (dd, aa) = FF(dd, ee, aa, bb, cc, X  2, 0w15)
            val (cc, ee) = FF(cc, dd, ee, aa, bb, X  3, 0w12)
            val (bb, dd) = FF(bb, cc, dd, ee, aa, X  4, 0w05)
            val (aa, cc) = FF(aa, bb, cc, dd, ee, X  5, 0w08)
            val (ee, bb) = FF(ee, aa, bb, cc, dd, X  6, 0w07)
            val (dd, aa) = FF(dd, ee, aa, bb, cc, X  7, 0w09)
            val (cc, ee) = FF(cc, dd, ee, aa, bb, X  8, 0w11)
            val (bb, dd) = FF(bb, cc, dd, ee, aa, X  9, 0w13)
            val (aa, cc) = FF(aa, bb, cc, dd, ee, X 10, 0w14)
            val (ee, bb) = FF(ee, aa, bb, cc, dd, X 11, 0w15)
            val (dd, aa) = FF(dd, ee, aa, bb, cc, X 12, 0w06)
            val (cc, ee) = FF(cc, dd, ee, aa, bb, X 13, 0w07)
            val (bb, dd) = FF(bb, cc, dd, ee, aa, X 14, 0w09)
            val (aa, cc) = FF(aa, bb, cc, dd, ee, X 15, 0w08)
                                      
            (* round 2 *)
            val (ee, bb) = GG(ee, aa, bb, cc, dd, X  7, 0w07)
            val (dd, aa) = GG(dd, ee, aa, bb, cc, X  4, 0w06)
            val (cc, ee) = GG(cc, dd, ee, aa, bb, X 13, 0w08)
            val (bb, dd) = GG(bb, cc, dd, ee, aa, X  1, 0w13)
            val (aa, cc) = GG(aa, bb, cc, dd, ee, X 10, 0w11)
            val (ee, bb) = GG(ee, aa, bb, cc, dd, X  6, 0w09)
            val (dd, aa) = GG(dd, ee, aa, bb, cc, X 15, 0w07)
            val (cc, ee) = GG(cc, dd, ee, aa, bb, X  3, 0w15)
            val (bb, dd) = GG(bb, cc, dd, ee, aa, X 12, 0w07)
            val (aa, cc) = GG(aa, bb, cc, dd, ee, X  0, 0w12)
            val (ee, bb) = GG(ee, aa, bb, cc, dd, X  9, 0w15)
            val (dd, aa) = GG(dd, ee, aa, bb, cc, X  5, 0w09)
            val (cc, ee) = GG(cc, dd, ee, aa, bb, X  2, 0w11)
            val (bb, dd) = GG(bb, cc, dd, ee, aa, X 14, 0w07)
            val (aa, cc) = GG(aa, bb, cc, dd, ee, X 11, 0w13)
            val (ee, bb) = GG(ee, aa, bb, cc, dd, X  8, 0w12)
            
            (* round 3 *)
            val (dd, aa) = HH(dd, ee, aa, bb, cc, X  3, 0w11)
            val (cc, ee) = HH(cc, dd, ee, aa, bb, X 10, 0w13)
            val (bb, dd) = HH(bb, cc, dd, ee, aa, X 14, 0w06)
            val (aa, cc) = HH(aa, bb, cc, dd, ee, X  4, 0w07)
            val (ee, bb) = HH(ee, aa, bb, cc, dd, X  9, 0w14)
            val (dd, aa) = HH(dd, ee, aa, bb, cc, X 15, 0w09)
            val (cc, ee) = HH(cc, dd, ee, aa, bb, X  8, 0w13)
            val (bb, dd) = HH(bb, cc, dd, ee, aa, X  1, 0w15)
            val (aa, cc) = HH(aa, bb, cc, dd, ee, X  2, 0w14)
            val (ee, bb) = HH(ee, aa, bb, cc, dd, X  7, 0w08)
            val (dd, aa) = HH(dd, ee, aa, bb, cc, X  0, 0w13)
            val (cc, ee) = HH(cc, dd, ee, aa, bb, X  6, 0w06)
            val (bb, dd) = HH(bb, cc, dd, ee, aa, X 13, 0w05)
            val (aa, cc) = HH(aa, bb, cc, dd, ee, X 11, 0w12)
            val (ee, bb) = HH(ee, aa, bb, cc, dd, X  5, 0w07)
            val (dd, aa) = HH(dd, ee, aa, bb, cc, X 12, 0w05)
            
            (* round 4 *)
            val (cc, ee) = II(cc, dd, ee, aa, bb, X  1, 0w11)
            val (bb, dd) = II(bb, cc, dd, ee, aa, X  9, 0w12)
            val (aa, cc) = II(aa, bb, cc, dd, ee, X 11, 0w14)
            val (ee, bb) = II(ee, aa, bb, cc, dd, X 10, 0w15)
            val (dd, aa) = II(dd, ee, aa, bb, cc, X  0, 0w14)
            val (cc, ee) = II(cc, dd, ee, aa, bb, X  8, 0w15)
            val (bb, dd) = II(bb, cc, dd, ee, aa, X 12, 0w09)
            val (aa, cc) = II(aa, bb, cc, dd, ee, X  4, 0w08)
            val (ee, bb) = II(ee, aa, bb, cc, dd, X 13, 0w09)
            val (dd, aa) = II(dd, ee, aa, bb, cc, X  3, 0w14)
            val (cc, ee) = II(cc, dd, ee, aa, bb, X  7, 0w05)
            val (bb, dd) = II(bb, cc, dd, ee, aa, X 15, 0w06)
            val (aa, cc) = II(aa, bb, cc, dd, ee, X 14, 0w08)
            val (ee, bb) = II(ee, aa, bb, cc, dd, X  5, 0w06)
            val (dd, aa) = II(dd, ee, aa, bb, cc, X  6, 0w05)
            val (cc, ee) = II(cc, dd, ee, aa, bb, X  2, 0w12)
              
            (* round 5 *)
            val (bb, dd) = JJ(bb, cc, dd, ee, aa, X  4, 0w09)
            val (aa, cc) = JJ(aa, bb, cc, dd, ee, X  0, 0w15)
            val (ee, bb) = JJ(ee, aa, bb, cc, dd, X  5, 0w05)
            val (dd, aa) = JJ(dd, ee, aa, bb, cc, X  9, 0w11)
            val (cc, ee) = JJ(cc, dd, ee, aa, bb, X  7, 0w06)
            val (bb, dd) = JJ(bb, cc, dd, ee, aa, X 12, 0w08)
            val (aa, cc) = JJ(aa, bb, cc, dd, ee, X  2, 0w13)
            val (ee, bb) = JJ(ee, aa, bb, cc, dd, X 10, 0w12)
            val (dd, aa) = JJ(dd, ee, aa, bb, cc, X 14, 0w05)
            val (cc, ee) = JJ(cc, dd, ee, aa, bb, X  1, 0w12)
            val (bb, dd) = JJ(bb, cc, dd, ee, aa, X  3, 0w13)
            val (aa, cc) = JJ(aa, bb, cc, dd, ee, X  8, 0w14)
            val (ee, bb) = JJ(ee, aa, bb, cc, dd, X 11, 0w11)
            val (dd, aa) = JJ(dd, ee, aa, bb, cc, X  6, 0w08)
            val (cc, ee) = JJ(cc, dd, ee, aa, bb, X 15, 0w05)
            val (bb, dd) = JJ(bb, cc, dd, ee, aa, X 13, 0w06)
            
            (* parallel round 1 *)
            val (aaa, ccc) = JJJ(aaa, bbb, ccc, ddd, eee, X  5, 0w08)
            val (eee, bbb) = JJJ(eee, aaa, bbb, ccc, ddd, X 14, 0w09)
            val (ddd, aaa) = JJJ(ddd, eee, aaa, bbb, ccc, X  7, 0w09)
            val (ccc, eee) = JJJ(ccc, ddd, eee, aaa, bbb, X  0, 0w11)
            val (bbb, ddd) = JJJ(bbb, ccc, ddd, eee, aaa, X  9, 0w13)
            val (aaa, ccc) = JJJ(aaa, bbb, ccc, ddd, eee, X  2, 0w15)
            val (eee, bbb) = JJJ(eee, aaa, bbb, ccc, ddd, X 11, 0w15)
            val (ddd, aaa) = JJJ(ddd, eee, aaa, bbb, ccc, X  4, 0w05)
            val (ccc, eee) = JJJ(ccc, ddd, eee, aaa, bbb, X 13, 0w07)
            val (bbb, ddd) = JJJ(bbb, ccc, ddd, eee, aaa, X  6, 0w07)
            val (aaa, ccc) = JJJ(aaa, bbb, ccc, ddd, eee, X 15, 0w08)
            val (eee, bbb) = JJJ(eee, aaa, bbb, ccc, ddd, X  8, 0w11)
            val (ddd, aaa) = JJJ(ddd, eee, aaa, bbb, ccc, X  1, 0w14)
            val (ccc, eee) = JJJ(ccc, ddd, eee, aaa, bbb, X 10, 0w14)
            val (bbb, ddd) = JJJ(bbb, ccc, ddd, eee, aaa, X  3, 0w12)
            val (aaa, ccc) = JJJ(aaa, bbb, ccc, ddd, eee, X 12, 0w06)
            
            (* parallel round 2 *)
            val (eee, bbb) = III(eee, aaa, bbb, ccc, ddd, X  6, 0w09) 
            val (ddd, aaa) = III(ddd, eee, aaa, bbb, ccc, X 11, 0w13)
            val (ccc, eee) = III(ccc, ddd, eee, aaa, bbb, X  3, 0w15)
            val (bbb, ddd) = III(bbb, ccc, ddd, eee, aaa, X  7, 0w07)
            val (aaa, ccc) = III(aaa, bbb, ccc, ddd, eee, X  0, 0w12)
            val (eee, bbb) = III(eee, aaa, bbb, ccc, ddd, X 13, 0w08)
            val (ddd, aaa) = III(ddd, eee, aaa, bbb, ccc, X  5, 0w09)
            val (ccc, eee) = III(ccc, ddd, eee, aaa, bbb, X 10, 0w11)
            val (bbb, ddd) = III(bbb, ccc, ddd, eee, aaa, X 14, 0w07)
            val (aaa, ccc) = III(aaa, bbb, ccc, ddd, eee, X 15, 0w07)
            val (eee, bbb) = III(eee, aaa, bbb, ccc, ddd, X  8, 0w12)
            val (ddd, aaa) = III(ddd, eee, aaa, bbb, ccc, X 12, 0w07)
            val (ccc, eee) = III(ccc, ddd, eee, aaa, bbb, X  4, 0w06)
            val (bbb, ddd) = III(bbb, ccc, ddd, eee, aaa, X  9, 0w15)
            val (aaa, ccc) = III(aaa, bbb, ccc, ddd, eee, X  1, 0w13)
            val (eee, bbb) = III(eee, aaa, bbb, ccc, ddd, X  2, 0w11)
            
            (* parallel round 3 *)
            val (ddd, aaa) = HHH(ddd, eee, aaa, bbb, ccc, X 15, 0w09)
            val (ccc, eee) = HHH(ccc, ddd, eee, aaa, bbb, X  5, 0w07)
            val (bbb, ddd) = HHH(bbb, ccc, ddd, eee, aaa, X  1, 0w15)
            val (aaa, ccc) = HHH(aaa, bbb, ccc, ddd, eee, X  3, 0w11)
            val (eee, bbb) = HHH(eee, aaa, bbb, ccc, ddd, X  7, 0w08)
            val (ddd, aaa) = HHH(ddd, eee, aaa, bbb, ccc, X 14, 0w06)
            val (ccc, eee) = HHH(ccc, ddd, eee, aaa, bbb, X  6, 0w06)
            val (bbb, ddd) = HHH(bbb, ccc, ddd, eee, aaa, X  9, 0w14)
            val (aaa, ccc) = HHH(aaa, bbb, ccc, ddd, eee, X 11, 0w12)
            val (eee, bbb) = HHH(eee, aaa, bbb, ccc, ddd, X  8, 0w13)
            val (ddd, aaa) = HHH(ddd, eee, aaa, bbb, ccc, X 12, 0w05)
            val (ccc, eee) = HHH(ccc, ddd, eee, aaa, bbb, X  2, 0w14)
            val (bbb, ddd) = HHH(bbb, ccc, ddd, eee, aaa, X 10, 0w13)
            val (aaa, ccc) = HHH(aaa, bbb, ccc, ddd, eee, X  0, 0w13)
            val (eee, bbb) = HHH(eee, aaa, bbb, ccc, ddd, X  4, 0w07)
            val (ddd, aaa) = HHH(ddd, eee, aaa, bbb, ccc, X 13, 0w05)
         
            (* parallel round 4 *)   
            val (ccc, eee) = GGG(ccc, ddd, eee, aaa, bbb, X  8, 0w15)
            val (bbb, ddd) = GGG(bbb, ccc, ddd, eee, aaa, X  6, 0w05)
            val (aaa, ccc) = GGG(aaa, bbb, ccc, ddd, eee, X  4, 0w08)
            val (eee, bbb) = GGG(eee, aaa, bbb, ccc, ddd, X  1, 0w11)
            val (ddd, aaa) = GGG(ddd, eee, aaa, bbb, ccc, X  3, 0w14)
            val (ccc, eee) = GGG(ccc, ddd, eee, aaa, bbb, X 11, 0w14)
            val (bbb, ddd) = GGG(bbb, ccc, ddd, eee, aaa, X 15, 0w06)
            val (aaa, ccc) = GGG(aaa, bbb, ccc, ddd, eee, X  0, 0w14)
            val (eee, bbb) = GGG(eee, aaa, bbb, ccc, ddd, X  5, 0w06)
            val (ddd, aaa) = GGG(ddd, eee, aaa, bbb, ccc, X 12, 0w09)
            val (ccc, eee) = GGG(ccc, ddd, eee, aaa, bbb, X  2, 0w12)
            val (bbb, ddd) = GGG(bbb, ccc, ddd, eee, aaa, X 13, 0w09)
            val (aaa, ccc) = GGG(aaa, bbb, ccc, ddd, eee, X  9, 0w12)
            val (eee, bbb) = GGG(eee, aaa, bbb, ccc, ddd, X  7, 0w05)
            val (ddd, aaa) = GGG(ddd, eee, aaa, bbb, ccc, X 10, 0w15)
            val (ccc, eee) = GGG(ccc, ddd, eee, aaa, bbb, X 14, 0w08)
         
            (* parallel round 5 *)
            val (bbb, ddd) = FFF(bbb, ccc, ddd, eee, aaa, X 12, 0w08)
            val (aaa, ccc) = FFF(aaa, bbb, ccc, ddd, eee, X 15, 0w05)
            val (eee, bbb) = FFF(eee, aaa, bbb, ccc, ddd, X 10, 0w12)
            val (ddd, aaa) = FFF(ddd, eee, aaa, bbb, ccc, X  4, 0w09)
            val (ccc, eee) = FFF(ccc, ddd, eee, aaa, bbb, X  1, 0w12)
            val (bbb, ddd) = FFF(bbb, ccc, ddd, eee, aaa, X  5, 0w05)
            val (aaa, ccc) = FFF(aaa, bbb, ccc, ddd, eee, X  8, 0w14)
            val (eee, bbb) = FFF(eee, aaa, bbb, ccc, ddd, X  7, 0w06)
            val (ddd, aaa) = FFF(ddd, eee, aaa, bbb, ccc, X  6, 0w08)
            val (ccc, eee) = FFF(ccc, ddd, eee, aaa, bbb, X  2, 0w13)
            val (bbb, ddd) = FFF(bbb, ccc, ddd, eee, aaa, X 13, 0w06)
            val (aaa, ccc) = FFF(aaa, bbb, ccc, ddd, eee, X 14, 0w05)
            val (eee, bbb) = FFF(eee, aaa, bbb, ccc, ddd, X  0, 0w15)
            val (ddd, aaa) = FFF(ddd, eee, aaa, bbb, ccc, X  3, 0w13)
            val (ccc, eee) = FFF(ccc, ddd, eee, aaa, bbb, X  9, 0w11)
            val (bbb, ddd) = FFF(bbb, ccc, ddd, eee, aaa, X 11, 0w11)
         in
            (b + cc + ddd, 
             c + dd + eee, 
             d + ee + aaa,
             e + aa + bbb,
             a + bb + ccc)
         end

      val initial = (0wx67452301, 0wxefcdab89, 0wx98badcfe,
                     0wx10325476, 0wxc3d2e1f0)
      
      fun finish (x, s) = writeSlice (s, x)
   end

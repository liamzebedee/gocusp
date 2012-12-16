(*
local
   open Serial
   val x = aggregate tuple5 `int8 `word8 `word16 `word16 `word32 $
in
   val { length, writer, parser } = pickleVector `x $
end


val v = writer (fn v => v) (79, 0w13, 0wxaabb, 0wxccdd, 0wxabcdef01)
val (a, b, c, d, e) = parser (v, fn x => x)
val () = print (Int8.toString a ^ Word8.toString b ^ Word16.toString c ^
                Word16.toString d ^ Word32.toString e ^ "\n")
*)

local
   open Serial
   val x = aggregate tuple5 `int8 `word8 `word16l `word16b `word32l $
in
   val { align, length, writer, parser } = pickleArray `x $
end

fun f 0 = 0
  | f i = f (i-1) + 1

val a = Word8Array.array (16, 0w0)
val s = Word8ArraySlice.slice (a, f 4, NONE)
val () = writer s (79, 0w13, 0wxaabb, 0wxccdd, 0wxabcdef01)
val (a, b, c, d, e) = parser (s, fn x => x)

val () = print (Int8.toString a ^ Word8.toString b ^ Word16.toString c ^
                Word16.toString d ^ Word32.toString e ^ "\n")

val i = 0x123456789123456789
local
   open Serial
in
   val { length, writer, parser } = pickleVector `(intinfb 24) $
end

val v = writer (fn v => v) i
val j = parser (v, fn i => i)

val () = print (IntInf.toString i ^ "\n")
val () = print (WordToString.fromBytes v ^ "\n")
val () = print (IntInf.toString j ^ "\n")

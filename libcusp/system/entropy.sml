(* Only works on Unix. *)
structure Entropy :> ENTROPY =
   struct
      local
         val devrandom = ref NONE
         
         fun release () = BinIO.closeIn (valOf (!devrandom))
         fun init () =
            let
               val () =
                  devrandom := SOME (BinIO.openIn "/dev/urandom"
                               handle IO.Io _ => BinIO.openIn "/dev/random")
            in
               OS.Process.atExit release
            end
      in
         fun get length = 
            let
               val () = if isSome (!devrandom) then () else init ()
            in
               BinIO.inputN (valOf (!devrandom), length)
            end
      end
   end

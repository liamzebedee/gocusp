structure Entropy :> ENTROPY =
   struct
      (* Get the Unix version *)
      open Entropy
      
      (* Windows version using FFI: *)
      local
         type pointer = MLton.Pointer.t
         val null = MLton.Pointer.null
         
         val CryptAcquireContext = _import "CryptAcquireContextA" stdcall external : pointer ref * pointer * pointer * Word32.word * Word32.word -> int;
         val CryptGenRandom = _import "CryptGenRandom" stdcall external : pointer * Word32.word * Word8Array.array -> int;
         val GetLastError = _import "GetLastError" stdcall external : unit -> Word32.word;
         val CryptReleaseContext = _import "CryptReleaseContext" stdcall external : pointer * Word32.word -> int;
         val context = ref null
         
         fun release () =
            case CryptReleaseContext (!context, 0w0) of
               0 => raise Fail ("CryptReleaseContext failed with error code " ^ Word32.toString (GetLastError ()))
             | _ => ()
         fun init () = 
            case CryptAcquireContext (context, null, null, 0w1, 0wxF0000000) of
              0 => raise Fail ("CryptAcquireContext failed with error code " ^ Word32.toString (GetLastError ()))
            | _ => OS.Process.atExit release
      in
         fun windows length = 
            let
               val () = if !context = null then init () else ()
               val entropy = Word8Array.tabulate (length, fn _ => 0w0)
               val () = 
                  case CryptGenRandom (!context, Word32.fromInt length, entropy) of
                     0 => print ("CryptGenRandom failed with error code " ^ Word32.toString (GetLastError ()))
                   | _ => ()
            in
               Word8Array.vector entropy
            end
      end
      
      (* Pick either the UNIX or Windows code path *)
      val get =
         case MLton.Platform.OS.host of
            MLton.Platform.OS.MinGW => windows
          | _ => get
   end

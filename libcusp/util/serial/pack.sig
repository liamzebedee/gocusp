(* Always uses little-endian order *)
signature PACK =
   sig
      type t
      
      val subArr : Word8Array.array  * int -> t
      val subVec : Word8Array.vector * int -> t
      val update : Word8Array.array  * int * t -> unit
   end

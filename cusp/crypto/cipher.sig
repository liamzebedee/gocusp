signature CIPHER =
   sig
      structure Key : SERIALIZABLE

      val length : int
      val f: { key    : Key.t,
               plain  : Word8Array.array,
               cipher : Word8Array.array } (* result *)
             -> unit
   end

signature COMPRESSOR =
   sig
      type state
      
      val inputLength  : int
      val outputLength : int
      
      val initial  : state
      val compress : state * Word8ArraySlice.slice -> state
      val finish   : state * Word8ArraySlice.slice -> unit
   end

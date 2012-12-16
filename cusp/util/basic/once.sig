(* The idea of ONCE is that it can provide a "global variable" that is
 * thread-safe. You can go:
 *   val myBuffer = Once.new (fn () => Word8ArrayTabulate (256, fn _ => 0w0))
 * Then make a function which uses this temporary buffer:
 *   fun doWork x = Once.get (myBuffer, fn buf => ... work with buf ...)
 *
 * We provide a OncePerThread and OncePerEntry. OncePerEntry is needed
 * if the function doWork might be called recursively and need two values.
 *)
signature ONCE =
   sig
      type 'a t
      
      val new: (unit -> 'a) -> 'a t
      val get: 'a t * ('a -> 'b) -> 'b
   end

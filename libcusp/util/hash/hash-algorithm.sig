(* This is the interface of a hash algorithm.
 * The input and output depend on the hash algorithm.
 *)
signature HASH_ALGORITHM =
   sig
      type state
      type input
      type output
      
      type 'a t = 'a * input -> output
      val make: ('a, state) Hash.function -> 'a t
   end

(* This is the interface a hash algorithm has to provide.
 * The above interface is automatically created from this.
 *)
signature HASH_PRIMITIVE =
   sig
      (* Whatever one feeds into a hash to create the initial state *)
      type initial
      (* The state which accumulates a hash result *)
      type state
      (* The state which results after completing the hash  *)
      type final
      
      (* Get an initial state for hashing with step+finish *)
      val start: initial -> state Hash.state
      
      (* Finish the hash function *)
      val stop: state -> final
   end

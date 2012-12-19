(* All Diffie-Hellman key exchange protocols use a private exponent.
 * This exponent is used in some group where discrete logarithms are hard.
 * Public keys are elements of the group = well-known-generator ** secret.
 * Shared secrets are similarly = well-known-generator ** (secret1*secret2).
 *)
signature CYCLIC_GROUP =
   sig
      include SERIALIZABLE
      
      exception BadElement (* group element not formed from generator *)
      val generator  : unit -> t
      val multiply   : t * t -> t
      val power      : t * LargeInt.int -> t
      
      (* This is just like power, but specifies an upper bound on the input
       * bits. Using this information, fixedPower is constant time and thus
       * immune to timing attacks. The simple 'power' function counts the
       * bits actually used by the exponent, making it vulnerable.
       *)
      val fixedPower : t * LargeInt.int * int -> t
      
      (* Make a (length-byte) exponent into a valid private-key *)
      val clamp     : LargeInt.int -> LargeInt.int
      val length    : int
   end

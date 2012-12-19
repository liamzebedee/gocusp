signature CRYPTO =
   sig
      structure PublicKey : 
         sig
            type t
            type suite
            
            val hash : (t, 'a) Hash.function
            val eq : t * t -> bool
            
            val toString : t -> string
            val suite : t -> suite
         end
      
      structure PrivateKey :
         sig
            type t
            
            val new : { entropy : int -> Word8Vector.vector } -> t
            val save : t * { password : string } -> string
            val load : { password : string, key : string } -> t option
            
            val pubkey : t * PublicKey.suite -> PublicKey.t
         end
   end

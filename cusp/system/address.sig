(**
 * Provides the interface for abstract network addresses.
 * Because of NAT issues, a host can only safely determine
 * its own public address by sending a message to another
 * node and ask the receiver for the sender address. 
 * 
 * Authors: Christof Leng, Wesley Terpstra
 *)
signature ADDRESS =
   sig
      include SERIALIZABLE
      
      (**
       * Reads adress from string representation.
       *)
      val fromString : string -> t option
   end

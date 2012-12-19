signature SUITE_SET =
   sig
      type set
      eqtype suite
      
      (* Intersects two suite sets. *)
      val intersect : set * set -> set
      (* Creates the union of two suite sets. *)
      val union     : set * set -> set
      (* Removes the suites contained in one set from another. *)
      val subtract  : set * set -> set
      (* Checks whether the suite set is empty. *)
      val isEmpty   : set -> bool
      
      (* Checks wether the suite set contains a particular suite. *)
      val contains  : set * suite -> bool
      (* Creates a suite set containing one element. *)
      val element   : suite -> set
      
      (* Returns the cheapest suite from the set. *)
      val cheapest  : set -> suite option
      (* Returns an iterator over the set. *)
      val iterator  : set -> suite Iterator.t
      
      (* Returns the name of the suite. *)
      val name : suite -> string
      (* Returns the relative computational cost of the suite. *)
      val cost : suite -> Real32.real
      
      (* DO NOT USE! Only for C bindings. *)
      val fromMask : Word16.word -> set
      val toMask   : set -> Word16.word
      val fromValue : Word16.word -> suite
      val toValue   : suite -> Word16.word
      
      (* The set of all available suites. *)
      val all : set
      (* The default set of suites. *)
      val defaults : set
   end

signature SUITE =
   sig
      structure Symmetric : SUITE_SET
      structure PublicKey : SUITE_SET
   end

(*
** 2007 February 18
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
** $Id: ring.sig 5301 2007-02-23 01:41:53Z wesley $
*)
signature RING =
   sig
      (* handle to a link in the ring *)
      eqtype 'a t
      
      (* Create a new ring with just this one element *)
      val new: 'a -> 'a t
      
      (* Add a value to the ring, get a handle to the link *)
      val add: 'a t * 'a -> 'a t
      
      (* Remove a link from the ring, it is in a new ring *)
      val remove: 'a t -> unit
      
      (* Update the contents of an element in the ring *)
      val update: 'a t * 'a -> unit
      
      (* Retrieve the value in this link *)
      val get: 'a t -> 'a
      
      (* Is this the only element in the ring? *)
      val isSolo: 'a t -> bool
      
      (* Get an iterator that walks the ring.
       * The order is arbitrary except for the first value (the input).
       *)
      val iterator: 'a t -> 'a t Iterator.t
   end

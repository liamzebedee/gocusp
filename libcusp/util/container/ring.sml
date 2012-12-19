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
** $Id: ring.sml 5301 2007-02-23 01:41:53Z wesley $
*)
structure Ring :> RING =
   struct
      datatype 'a elt = T of {
         prev: 'a t option,
         next: 'a t option,
         value: 'a }
      withtype 'a t = 'a elt ref
      
      fun new x = 
         let
            val self = T { value = x, prev = NONE, next = NONE }
            val self = ref self
            val () = 
               self := T { value = x, prev = SOME self, next = SOME self }
         in
            self
         end
      
      fun add (prev, x) =
         let
            val T { value=pvalue, prev=pprev, next=next } = !prev
            val next = valOf next
            val self = T { value=x, prev = SOME prev, next = SOME next }
            val self = ref self
            val () = prev := T { value=pvalue, prev=pprev, next=SOME self }
            (* read next after writing prev, in case they are the same *)
            val T { value=nvalue, prev=_, next=nnext } = !next
            val () = next := T { value=nvalue, prev=SOME self, next=nnext }
         in
            self
         end
      
      fun remove self =
         let
            val T { value, prev=prev, next=next } = !self
            val next = valOf next
            val prev = valOf prev
            val T { value=pvalue, prev=pprev, next=_ } = !prev
            val () = prev := T { value=pvalue, prev=pprev, next=SOME next }
            val T { value=nvalue, prev=_, next=nnext } = !next
            val () = next := T { value=nvalue, prev=SOME prev, next=nnext }
         in
            self := T { value=value, prev=SOME self, next=SOME self }
         end
      
      fun update (self, value) =
         let
            val T { value=_, prev, next } = !self
         in
            self := T { value=value, prev=prev, next=next }
         end
      
      fun get self =
         let
            val T { value, prev=_, next=_ } = !self
         in
            value
         end
      
      fun isSolo self =
         let
            val T { value=_, prev=_, next } = !self
         in
            valOf next = self
         end
      
      fun iterator start =
         let
            fun loop i =
               let
                  val T { value=_, next, prev=_ } = !i
               in
                  if i = start
                  then Iterator.EOF
                  else Iterator.VALUE (i, fn () => loop (valOf next))
               end
            val T { value=_, next, prev=_ } = !start
         in
            Iterator.VALUE (start, fn () => loop (valOf next))
         end
   end

(*
val a = Ring.new 7
val b = Ring.add (a, 9)
val c = Ring.add (a, 11)
val d = Ring.add (b, 13)
val () = print (Int.toString (Ring.get b) ^ "\n")
val () = Ring.update (b, 10)
val () = print (Int.toString (MLton.size a) ^ "\n")
val () = Ring.remove c 
val () = Iterator.app (fn x => print (Int.toString x ^ "\n")) (Ring.iterator a)
*)

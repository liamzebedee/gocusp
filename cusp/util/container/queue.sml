structure Queue :> QUEUE =
   struct
      type 'a t = { head: 'a list, tail: 'a list }
      
      val empty = { head = [], tail = [] }
      
      val rec pop = fn z => case z of
         { head = x::r, tail }    => ({ head = r, tail = tail }, SOME x)
       | { head = [], tail = [] } => (z, NONE)
       | { head = [], tail }      => pop { head = rev tail, tail = [] }
      
      val rec peek = fn z => case z of
         { head = x::_, tail=_ }    => (z, SOME x)
       | { head = [], tail = [] } => (z, NONE)
       | { head = [], tail }      => peek { head = rev tail, tail = [] }
      
      fun isEmpty { head=[], tail=[] } = true
        | isEmpty _ = false
      
      fun pushFront ({ head, tail }, x) = { head = x::head, tail = tail }
      fun pushBack  ({ head, tail }, x) = { head = head, tail = x::tail }
      
      local
         open Iterator
         fun revList x = SKIP (fn () => fromList (List.rev x))
      in
         fun unordered { head, tail } = fromList head @ fromList tail
         fun forward   { head, tail } = fromList head @ revList  tail
         fun backward  { head, tail } = fromList tail @ revList  head
      end
   end

structure ImperativeQueue :> IMPERATIVE_QUEUE =
   struct
      type 'a t = 'a Queue.t ref
      
      fun new () = ref Queue.empty
      
      fun peek (x as ref q) = case Queue.peek q of (q, r) => (x := q; r)
      fun pop  (x as ref q) = case Queue.pop  q of (q, r) => (x := q; r)
      fun isEmpty (ref q) = Queue.isEmpty q
      
      fun pushFront (x as ref q, y) = x := Queue.pushFront (q, y)
      fun pushBack  (x as ref q, y) = x := Queue.pushBack  (q, y)
      
      fun unordered x = Queue.unordered (!x)
      fun forward   x = Queue.forward   (!x)
      fun backward  x = Queue.backward  (!x)
   end

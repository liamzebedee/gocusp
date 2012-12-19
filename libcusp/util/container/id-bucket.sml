structure IdBucket :> ID_BUCKET =
   struct
      datatype 'a cell = FREE of int | FULL of 'a
      type 'a t = { free: int, table: 'a cell array } ref

      fun new () =
         ref { free = 3, table = Array.tabulate (4, fn i => FREE (i-1)) }

      fun sub (ref { free=_, table }, i) =
         case Array.sub (table, i) of
            FREE _ => NONE
          | FULL x => SOME x

      fun alloc (self as ref { free, table }, value) =
         let
            val oldlen = Array.length table
            val newlen = oldlen+oldlen
            fun get i =
               if i < oldlen then Array.sub (table, i) else
               if i = oldlen then FREE ~1 else
               FREE (i-1)
            fun grow () = (newlen-1, Array.tabulate (newlen, get))
            val (free, table) =
               if free = ~1 then grow () else (free, table)
         in
            case Array.sub (table, free) of
               FULL _ => raise Fail "Impossibly full cell"
             | FREE next =>
                 (Array.update (table, free, FULL value)
                  ; self := { free = next, table = table }
                  ; free)
         end

      exception AlreadyFree
      fun free (self as ref { free, table }, index) =
         case Array.sub (table, index) of
            FREE _ => raise AlreadyFree
          | FULL _ =>
              (Array.update (table, index, FREE free)
               ; self := { free = index, table = table })

      fun replace (ref { free = _, table }, index, value) =
         case Array.sub (table, index) of
            FREE _ => raise AlreadyFree
          | FULL _ => Array.update (table, index, FULL value)

      fun iterator (ref { free=_, table }) =
         Iterator.mapPartial
         (fn (_, FREE _) => NONE | (i, FULL x) => SOME (i, x))
         (Iterator.fromArraySlicei (ArraySlice.full table))
   end

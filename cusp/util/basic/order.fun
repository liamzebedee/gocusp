functor Order(Base : ORDER) : ORDER_EXTENDED =
   struct
      open Base
       
      fun min (x, y) = if x < y then x else y
      fun max (x, y) = if x < y then y else x
      fun >   (x, y) = y < x
      fun >=  (x, y) = not (x < y)
      fun <=  (x, y) = not (y < x)
   end

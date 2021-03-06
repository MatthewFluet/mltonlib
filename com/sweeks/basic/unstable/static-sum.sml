(* Copyright (C) 2006 Stephen Weeks.
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)
structure StaticSum:> STATIC_SUM = struct

   type ('a1, 'a2, 'b1, 'b2, 'c) u = ('a1 -> 'a2) * ('b1 -> 'b2) -> 'c
   type ('a1, 'a2, 'b1, 'b2, 'c) t = Unit.t -> ('a1, 'a2, 'b1, 'b2, 'c) u

   fun left a1 = fn () => fn (f, _) => f a1
   fun right b1 = fn () => fn (_, f) => f b1
   fun switch (f, l, r) = f () (l, r)

end

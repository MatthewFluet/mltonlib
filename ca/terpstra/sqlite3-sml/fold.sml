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
** $Id$
*)
(* Shamelessly stolen from Vesa *)

fun $ (a, f) = f a
structure Fold : FOLD =
   struct
      type ('a, 'b, 'c, 'd) step = 'a * ('b -> 'c) -> 'd
      type ('a, 'b, 'c, 'd) t = ('a, 'b, 'c, 'd) step -> 'd
      type ('a1, 'a2, 'b, 'c, 'd) step0 = ('a1, 'b, 'c, ('a2, 'b, 'c, 'd) t) step
      type ('a11, 'a12, 'a2, 'b, 'c, 'd) step1 = ('a12, 'b, 'c, 'a11 -> ('a2, 'b, 'c, 'd) t) step
      
      fun fold (a, f) g = g (a, f)
      fun step0 h (a, f) = fold (h a, f)
      fun step1 h (a, f) b = fold (h (b, a), f)
   end

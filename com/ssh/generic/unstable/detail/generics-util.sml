(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

structure GenericsUtil :> GENERICS_UTIL = struct
   (* <-- SML/NJ workaround *)
   open Basic
   (* SML/NJ workaround --> *)

   val ` = Exn.name
   fun failCat ss = fail (concat ss)
   fun failExn e = failCat ["unregistered exn ", `e]
   fun failExnSq (l, r) = failCat ["unregistered exns ", `l, " and ", `r]
end
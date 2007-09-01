(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(* Helper for adding a new generic. *)
functor CloseWithExtra (Open : OPEN_CASES) = struct
   local
      structure Extra = WithExtra
         (structure Open = Open and Closed = CloseCases (Open) open Closed)
   in
      open Extra
   end
   structure Arbitrary   = Open.Rep
   structure DataRecInfo = Open.Rep
   structure Eq          = Open.Rep
   structure Hash        = Open.Rep
   structure Ord         = Open.Rep
   structure Pickle      = Open.Rep
   structure Pretty      = Open.Rep
   structure Some        = Open.Rep
   structure TypeHash    = Open.Rep
   structure TypeInfo    = Open.Rep
end

(* Register basis library exceptions for the default generics. *)
local structure ? = RegBasisExns (Generic) open ? in end

(* A simplistic graph for testing with cyclic data. *)
functor MkGraph (include GENERIC_EXTRA) :> sig
   type 'a t
   val t : 'a Rep.t -> 'a t Rep.t
   val intGraph1 : Int.t t
end = struct
   datatype 'a v = VTX of 'a * 'a t
   withtype 'a t = 'a v List.t Ref.t

   local
      val cVTX = C "VTX"
      fun withT aV = refc (list aV)
   in
      fun v a =
          (Tie.fix Y)
             (fn aV =>
                 iso (data (C1 cVTX (tuple2 (a, withT aV))))
                     (fn VTX ? => ?, VTX))
      fun t a = withT (v a)
   end

   fun arcs (VTX (_, r)) = r

   val intGraph1 = let
      val a = VTX (1, ref [])
      val b = VTX (2, ref [])
      val c = VTX (3, ref [])
      val d = VTX (4, ref [])
      val e = VTX (5, ref [])
      val f = VTX (6, ref [])
   in
      arcs a := [b, d]
    ; arcs b := [c, e]
    ; arcs c := [a, f]
    ; arcs d := [f]
    ; arcs e := [d]
    ; arcs f := [e]
    ; ref [a, b, c, d, e, f]
   end
end

(* A contrived recursive exception constructor for testing with cyclic data. *)
functor MkExnArray (include GENERIC_EXTRA) :> sig
   exception ExnArray of Exn.t Array.t
   val exnArray1 : Exn.t Array.t
end = struct
   exception ExnArray of Exn.t Array.t
   val () = regExn1' "ExnArray" (array exn) ExnArray (fn ExnArray ? => ?)

   val exnArray1 = Array.fromList [Empty]
   val () = Array.update (exnArray1, 0, ExnArray exnArray1)
end

(* A simple binary tree. *)
functor MkBinTree (include GENERIC_EXTRA) :> sig
   datatype 'a t = LF | BR of 'a t * 'a * 'a t
   val t : 'a Rep.t -> 'a t Rep.t
end = struct
   datatype 'a t = LF | BR of 'a t * 'a * 'a t
   local
      val cLF = C "LF"
      val cBR = C "BR"
   in
      fun t a =
          (Tie.fix Y)
             (fn aT =>
                 iso (data (C0 cLF +` C1 cBR (tuple3 (aT, a, aT))))
                     (fn LF => INL () | BR ? => INR ?,
                      fn INL () => LF | INR ? => BR ?))
   end
end
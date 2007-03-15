(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(** == Top-Level Bindings == *)

(** === Basic === *)

val eq = Basic.eq
val notEq = Basic.notEq
val fail = Basic.fail
val failing = Basic.failing
val raising = Basic.raising
val recur = Basic.recur
val repeat = Basic.repeat
val undefined = Basic.undefined

(** === Exn === *)

val finally = Exn.finally
val try = Exn.try

(** === Fn === *)

val const = Fn.const
val curry = Fn.curry
val flip = Fn.flip
val id = Fn.id
val pass = Fn.pass
val uncurry = Fn.uncurry

val op /> = Fn./>
val op </ = Fn.</
val op <\ = Fn.<\
val op >| = Fn.>|
val op \> = Fn.\>
val op |< = Fn.|<

(** === Option === *)

val isNone = Option.isNone

(** === Product === *)

datatype product = datatype Product.product

(** === Ref === *)

val op :=: = Ref.:=:

(** === Sum === *)

datatype sum = datatype Sum.sum

(** === TextIO === *)

val println = TextIO.println

(** === UnPr === *)

val negate = UnPr.negate

val op andAlso = UnPr.andAlso
val op orElse = UnPr.orElse

(** === Void === *)

type void = Void.t
val void = Void.void

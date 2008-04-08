(* Copyright (C) 2008 Vesa Karvonen
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(**
 * This is a translation of the ``Countdown'' example from Chapter 11 of
 * the book:
 *
 *   Programming in Haskell
 *   by Graham Hutton
 *   Cambridge University Press
 *   ISBN 0-521-69269-5
 *   http://www.cs.nott.ac.uk/~gmh/book.html
 *
 * See the WWW site for the original Haskell code.
 *
 * The original Haskell code uses lazy lists.  This translation uses
 * iterators rather than lists.  The translation is rather mechanical
 * and the programs are structurally very similar.
 *
 * Unsurprisingly using iterators gives excellent performance.  On a
 * Pentium M laptop, compiled with MLton, the solvers using iterators run
 * more than 3 times faster than GHC (6.6.1) compiled solvers using lazy
 * lists.  Note that it is more than likely that the same technique, using
 * iterators rather than lazy lists, could be used to speed up the Haskell
 * version.
 *)

(*** Expressions ***)

datatype b = ADD | SUB | MUL | DIV

fun valid ADD _ _ = true
  | valid SUB x y = x > y
  | valid MUL _ _ = true
  | valid DIV x y = x mod y = 0

fun apply ADD x y = x + y
  | apply SUB x y = x - y
  | apply MUL x y = x * y
  | apply DIV x y = x div y

datatype x = VAL of int | APP of b * x * x

fun eval (VAL n)         e = if n > 0 then e n else ()
  | eval (APP (b, l, r)) e = eval l (fn l =>
                             eval r (fn r =>
                             if valid b l r then e (apply b l r) else ()))

(*** Combinatorial functions ***)

fun subs []      e = e [] : unit
  | subs (x::xs) e = subs xs (fn ys => (e ys ; e (x::ys)))

fun interleave x []      e = e [x] : unit
  | interleave x (y::ys) e =
    (e (x::y::ys) ; interleave x ys (fn ys => e (y::ys)))

fun perms []      e = e [] : unit
  | perms (x::xs) e = perms xs (fn p => interleave x p e)

fun choices xs e = subs xs (fn s => perms s e)

(*** Brute force solution ***)

fun split []      _ = ()
  | split [_]     _ = ()
  | split (x::xs) e = (split xs (fn (ls, rs) => e (x::ls, rs)) ; e ([x], xs))

fun bops e = (e ADD ; e SUB ; e MUL ; e DIV) : unit

fun combine l r e = bops (fn b => e (APP (b, l, r)))

fun exprs []  _ = ()
  | exprs [n] e = e (VAL n)
  | exprs ns  e =
    split ns (fn (l, r) => exprs l (fn x => exprs r (fn y => combine x y e)))

fun solutions ns n e = choices ns (fn ns' =>
                       exprs ns' (fn x =>
                       eval x (fn n' =>
                       if n' = n then e x else ())))

(*** Combining generation and evaluation ***)

fun combine' (l, x) (r, y) e =
    bops (fn b => if valid b x y then e (APP (b, l, r), apply b x y) else ())

fun results []  _ = ()
  | results [n] e = if n > 0 then e (VAL n, n) else ()
  | results ns  e = split ns (fn (l, r) =>
                    results l (fn x =>
                    results r (fn y =>
                    combine' x y e)))

fun solutions' ns n e =
    choices ns (fn ns' => results ns' (fn (x, m) => if m = n then e x else ()))

(*** Exploiting numeric properties ***)

fun valid' ADD x y = x <= y
  | valid' SUB x y = x > y
  | valid' MUL x y = x <= y andalso 1 < x
  | valid' DIV x y = y <> 1 andalso x mod y = 0

fun combine'' (l, x) (r, y) e =
    bops (fn b => if valid' b x y then e (APP (b, l, r), apply b x y) else ())

fun results' []  _ = ()
  | results' [n] e = if n > 0 then e (VAL n, n) else ()
  | results' ns  e = split ns (fn (l, r) =>
                     results' l (fn x =>
                     results' r (fn y =>
                     combine'' x y e)))

fun solutions'' ns n e =
    choices ns (fn ns' => results' ns' (fn (x, m) => if m = n then e x else ()))

(*** Main Program ***)

val bToString = fn ADD => "+" | SUB => "-" | MUL => "*" | DIV => "/"

fun xToString (VAL i)         = Int.toString i
  | xToString (APP (b, l, r)) =
    concat ["(", xToString l, " ", bToString b, " ", xToString r, ")"]

fun s2i s =
    case Int.fromString s
     of NONE   => fails ["Not a number: ", s]
      | SOME i => if i <= 0 then fails ["Not a positive number: ", s] else i

fun main solver =
 fn s::n::ns => solver (List.map s2i (n::ns)) (s2i s) (println o xToString)
  | _        => fail "Not enough arguments"

val () =
    (case CommandLine.arguments ()
      of "-brute"    :: args => main solutions   args
       | "-combined" :: args => main solutions'  args
       | "-exploit"  :: args => main solutions'' args
       |                args => main solutions'' args)
    handle e =>
           (println (Exn.message e)
          ; printlns ["Usage: ", OS.Path.file (CommandLine.name ()),
                      " [-brute | -combined | -exploit] solution number ..."])

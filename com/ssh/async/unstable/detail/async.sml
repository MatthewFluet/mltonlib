(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

structure Async :> ASYNC = struct
   exception Full

   structure Queue = struct
      open Queue
      fun dequeWhile p q =
          case Queue.deque q of
             NONE => NONE
           | SOME t => if p t then dequeWhile p q else SOME t
   end

   structure Handler = struct
      datatype 'a t = T of {scheduled : Bool.t Ref.t, effect : 'a Effect.t}
      fun new () = T {scheduled = ref false, effect = id}
      fun scheduled (T t) = !(#scheduled t)
      fun prepend f (T t) = T {scheduled = #scheduled t, effect = #effect t o f}
      val handlers = Queue.new ()
      fun schedule a (T {scheduled, effect}) =
          if !scheduled then ()
          else (scheduled := true ; Queue.enque handlers (fn () => effect a))
      fun runAll () = Queue.appClear (pass ()) handlers
   end

   structure Event = struct
      datatype 'a t = E of ('a Handler.t Effect.t, 'a) Sum.t Thunk.t
      fun on (E t, f) =
          E (fn () =>
                INL (fn h => let
                           val h = Handler.prepend f h
                        in
                           case t () of
                              INL ef => ef h
                            | INR v =>
                              Handler.schedule () (Handler.prepend (const v) h)
                        end))
      fun choose es =
          E (fn () =>
                recur (es & []) (fn lp =>
                   fn [] & efs =>
                      INL (fn h =>
                              recur efs (fn lp =>
                                 fn [] => ()
                                  | ef::efs =>
                                    (ef h
                                   ; if Handler.scheduled h then ()
                                     else lp efs)))
                    | E e::es & efs =>
                      case e () of
                         INL ef => lp (es & ef::efs)
                       | result => result))
      fun once (E t) = Sum.app (fn ef => ef (Handler.new ()),
                                Queue.enque Handler.handlers o const) (t ())
      fun when ? = once (on ?)
      fun each e = when (e, fn () => each e)
      fun every ? = each (on ?)
      val any = once o choose
      val all = each o choose
   end

   open Event

   structure Ch = struct
      datatype 'a t
        = T of {ts : 'a Handler.t Queue.t,
                gs : {handler : Unit.t Handler.t, value : 'a} Queue.t}
      fun new () = T {ts = Queue.new (), gs = Queue.new ()}
      fun take (T {gs, ts}) =
          E (fn () =>
                case Queue.dequeWhile (Handler.scheduled o #handler) gs of
                   NONE => INL (Queue.enque ts)
                 | SOME {handler, value} =>
                   (Handler.schedule () handler ; INR value))
      fun give (T {ts, gs}) v =
          E (fn () =>
                case Queue.dequeWhile Handler.scheduled ts of
                   SOME th => (Handler.schedule v th ; INR ())
                 | NONE =>
                   INL (fn h => Queue.enque gs {handler = h, value = v}))
      fun send m = Event.once o give m
   end

   structure Mailbox = Ch

   structure IVar = struct
      datatype 'a t = T of {rs : 'a Handler.t Queue.t, st : 'a Option.t Ref.t}
      fun new () = T {rs = Queue.new (), st = ref NONE}
      fun read (T {rs, st}) =
          E (fn () =>
                case !st of
                   SOME v => INR v
                 | NONE => INL (Queue.enque rs))
      fun fill (T {rs, st}) v =
          case !st of
             SOME _ => raise Full
           | NONE => (st := SOME v ; Queue.appClear (Handler.schedule v) rs)
   end

   structure MVar = struct
      datatype 'a t = T of {ts : 'a Handler.t Queue.t, st : 'a Option.t Ref.t}
      fun new () = T {ts = Queue.new (), st = ref NONE}
      fun take (T {ts, st}) =
          E (fn () =>
                case !st of
                   SOME v => (st := NONE ; INR v)
                 | NONE => INL (Queue.enque ts))
      fun fill (T {ts, st}) v =
          case !st of
             SOME _ => raise Full
           | NONE =>
             case Queue.dequeWhile Handler.scheduled ts of
                NONE => st := SOME v
              | SOME h => Handler.schedule v h
      fun send (T {ts, st}) v =
          case !st of
             SOME _ => st := SOME v
           | NONE =>
             case Queue.dequeWhile Handler.scheduled ts of
                NONE => st := SOME v
              | SOME h => Handler.schedule v h
   end

   structure SkipCh = MVar

   structure Multicast = struct
      datatype 'a n = N of 'a * 'a n IVar.t
      datatype 'a t = T of 'a n IVar.t Ref.t
      fun new () = T (ref (IVar.new ()))
      fun taker (T st) = let
         val ch = Ch.new ()
         fun lp st =
             when (IVar.read st,
                   fn N (v, st) =>
                      when (Ch.give ch v,
                            fn () => lp st))
      in
         lp (!st) ; Ch.take ch
      end
      fun send (T st) v = let
         val ost = !st
         val nst = IVar.new ()
      in 
         st := nst ; IVar.fill ost (N (v, nst))
      end
   end
end

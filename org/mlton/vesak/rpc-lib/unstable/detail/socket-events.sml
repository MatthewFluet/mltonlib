(* Copyright (C) 2008 Vesa Karvonen
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

structure SocketEvents :> sig
   exception Closed

   type 'm socket = 'm INetSock.stream_sock

   type ('a, 'm) monad = 'm socket -> (Exn.t, 'a) Sum.t Async.Event.t
   val return : 'a -> ('a, 'm) monad
   val >>= : ('a, 'm) monad * ('a -> ('b, 'm) monad) -> ('b, 'm) monad

   val error : Exn.t -> ('a, 'm) monad

   val sockEvt : OS.IO.poll_desc UnOp.t -> ('m socket, 'm) monad

   val recv : Word8ArraySlice.t -> (Word8ArraySlice.t, Socket.active) monad

   val sendArr : Word8ArraySlice.t -> (Unit.t, Socket.active) monad
   val sendVec : Word8VectorSlice.t -> (Unit.t, Socket.active) monad
end = struct
   open PollLoop Async

   exception Closed

   type 'm socket = 'm INetSock.stream_sock

   type ('a, 'm) monad = 'm socket -> (Exn.t, 'a) Sum.t Async.Event.t
   fun error e _ =
       case IVar.new ()
        of result => (IVar.fill result (INL e) ; IVar.read result)
   fun return x _ =
       case IVar.new ()
        of result => (IVar.fill result (INR x) ; IVar.read result)
   fun (xM >>= x2yM) socket =
       case IVar.new ()
        of result =>
           ((when (xM socket))
             (fn INL e => IVar.fill result (INL e)
               | INR x =>
                 (when (x2yM x socket))
                  (IVar.fill result))
          ; IVar.read result)

   local
      fun mk toIODesc poll s = let
         val ch = IVar.new ()
         val pollDesc = poll (valOf (OS.IO.pollDesc (toIODesc s)))
      in
         addDesc
          (pollDesc, fn _ => (IVar.fill ch (INR s) ; remDesc pollDesc))
       ; IVar.read ch
      end
   in
      fun sockEvt ? = mk Socket.ioDesc ?
    (*fun iodEvt ? = mk id ?*)
   end

   local
      fun mk isEmpty subslice poll operNB result slice =
          recur slice (fn lp =>
             fn slice =>
                if isEmpty slice
                then return result
                else sockEvt poll >>= (fn socket =>
                     case operNB (socket, slice)
                      of NONE   => error (Fail "impossible")
                       | SOME 0 => error Closed
                       | SOME n =>
                         lp (subslice (slice, n, NONE))))
   in
      fun recv slice =
          mk Word8ArraySlice.isEmpty Word8ArraySlice.subslice
             OS.IO.pollIn Socket.recvArrNB slice slice
      fun sendArr slice =
          mk Word8ArraySlice.isEmpty Word8ArraySlice.subslice
             OS.IO.pollOut Socket.sendArrNB () slice
      fun sendVec slice =
          mk Word8VectorSlice.isEmpty Word8VectorSlice.subslice
             OS.IO.pollOut Socket.sendVecNB () slice
   end
end

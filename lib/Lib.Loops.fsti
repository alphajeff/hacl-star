module Lib.Loops

open FStar.HyperStack
open FStar.HyperStack.ST
open Lib.IntTypes

unfold let v = size_v

inline_for_extraction
val for:
    start:size_t
  -> finish:size_t{v finish >= v start}
  -> inv:(mem -> (i:nat{v start <= i /\ i <= v finish}) -> Type0)
  -> f:(i:size_t{v start <= v i /\ v i < v finish} -> Stack unit
                  (requires fun h -> inv h (v i))
                  (ensures  fun h_1 _ h_2 -> inv h_2 (v i + 1))) ->
  Stack unit
    (requires fun h -> inv h (v start))
    (ensures  fun _ _ h_2 -> inv h_2 (v finish))
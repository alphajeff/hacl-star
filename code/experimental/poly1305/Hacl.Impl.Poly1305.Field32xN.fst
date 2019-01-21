module Hacl.Impl.Poly1305.Field32xN

open FStar.HyperStack
open FStar.HyperStack.All
open FStar.Mul

open Lib.IntTypes
open Lib.Buffer
open Lib.ByteBuffer
open Lib.IntVector

include Hacl.Spec.Poly1305.Field32xN
open Hacl.Spec.Poly1305.Field32xN.Lemmas

module S = Hacl.Spec.Poly1305.Vec
module ST = FStar.HyperStack.ST
module LSeq = Lib.Sequence
module BSeq = Lib.ByteSequence

let felem (w:lanes) = lbuffer (uint64xN w) 5ul
let felem_wide (w:lanes) = felem w
let precomp_r (w:lanes) = lbuffer (uint64xN w) 20ul

unfold
let op_String_Access #a #len = LSeq.index #a #len

noextract
val as_tup5: #w:lanes -> h:mem -> f:felem w -> GTot (felem5 w)
let as_tup5 #w h f =
  let s = as_seq h f in
  let s0 = s.[0] in
  let s1 = s.[1] in
  let s2 = s.[2] in
  let s3 = s.[3] in
  let s4 = s.[4] in
  (s0,s1,s2,s3,s4)

noextract
val felem_fits: #w:lanes -> h:mem -> f:felem w -> m:scale32_5 -> Type0
let felem_fits #w h f m =
  felem_fits5 (as_tup5 h f) m

noextract
val felem_wide_fits: #w:lanes -> h:mem -> f:felem w -> m:scale32_5 -> Type0
let felem_wide_fits #w h f m =
  felem_wide_fits5 (as_tup5 h f) m

noextract
let feval (#w:lanes) (h:mem) (f:felem w) : GTot (LSeq.lseq S.pfelem w) =
  feval5 (as_tup5 h f)

noextract
let fas_nat (#w:lanes) (h:mem) (f:felem w) : GTot (LSeq.lseq nat w) =
  fas_nat5 (as_tup5 h f)

noextract
let felem_less (#w:lanes) (h:mem) (f:felem w) (max:nat) : Type0 =
  felem_less5 (as_tup5 h f) max

inline_for_extraction
val create_felem:
    w:lanes
  -> StackInline (felem w)
    (requires fun h -> True)
    (ensures  fun h0 b h1 ->
      stack_allocated b h0 h1 (LSeq.create 5 (zero w)) /\
      feval h1 b == LSeq.create w 0)
let create_felem w =
  let r = create 5ul (zero w) in
  let h1 = ST.get () in
  LSeq.eq_intro (feval h1 r) (LSeq.create w 0);
  r

inline_for_extraction
val set_bit:
    #w:lanes
  -> f:felem w
  -> i:size_t{size_v i <= 128}
  -> Stack unit
    (requires fun h ->
      live h f /\
      felem_fits h f (1, 1, 1, 1, 1) /\
      felem_less #w h f (pow2 (v i)))
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
     (Math.Lemmas.pow2_le_compat 128 (v i);
      feval h1 f == LSeq.map (S.pfadd (pow2 (v i))) (feval h0 f)))
let set_bit #w f i = admit();
  let b = u64 1 <<. (i %. 26ul) in
  let mask = vec_load b w in
  let fi = f.(i /. 26ul) in
  f.(i /. 26ul) <- vec_or fi mask

inline_for_extraction
val set_bit128:
    #w:lanes
  -> f:felem w
  -> Stack unit
    (requires fun h ->
      live h f /\
      felem_fits h f (1, 1, 1, 1, 1) /\
      felem_less #w h f (pow2 128))
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      feval h1 f == LSeq.map (S.pfadd (pow2 128)) (feval h0 f))
let set_bit128 #w f = admit();
  let b = u64 0x1000000 in
  let mask = vec_load b w in
  let f4 = f.(4ul) in
  f.(4ul) <- vec_or f4 mask

inline_for_extraction
val set_zero:
    #w:lanes
  -> f:felem w
  -> Stack unit
    (requires fun h -> live h f)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      feval h1 f == LSeq.create w 0)
let set_zero #w f =
  f.(0ul) <- zero w;
  f.(1ul) <- zero w;
  f.(2ul) <- zero w;
  f.(3ul) <- zero w;
  f.(4ul) <- zero w;
  let h1 = ST.get () in
  LSeq.eq_intro (feval h1 f) (LSeq.create w 0)

inline_for_extraction
val copy_felem:
    #w:lanes
  -> #m:scale32_5
  -> f1:felem w
  -> f2:felem w
  -> Stack unit
    (requires fun h ->
      live h f1 /\ live h f2 /\ disjoint f1 f2 /\
      felem_fits h f2 m)
    (ensures  fun h0 _ h1 ->
      modifies (loc f1) h0 h1 /\
      felem_fits h1 f1 m /\
      as_tup5 h1 f1 == as_tup5 h0 f2)
let copy_felem #w #m f1 f2 =
  f1.(0ul) <- f2.(0ul);
  f1.(1ul) <- f2.(1ul);
  f1.(2ul) <- f2.(2ul);
  f1.(3ul) <- f2.(3ul);
  f1.(4ul) <- f2.(4ul)

//[@CInline]
inline_for_extraction
val fadd:
    #w:lanes
  -> out:felem w
  -> f1:felem w
  -> f2:felem w
  -> Stack unit
    (requires fun h ->
      live h f1 /\ live h f2 /\ live h out /\
      felem_fits h f1 (1,2,1,1,1) /\
      felem_fits h f2 (1,1,1,1,1))
    (ensures  fun h0 _ h1 ->
      modifies (loc out) h0 h1 /\
      //as_tup5 h1 out == fadd5 (as_tup5 h0 f1) (as_tup5 h0 f2) /\
      felem_fits h1 out (2, 3, 2, 2, 2) /\
      feval h1 out == LSeq.map2 S.pfadd (feval h0 f1) (feval h0 f2))
let fadd #w out f1 f2 =
  let f10 = f1.(0ul) in
  let f11 = f1.(1ul) in
  let f12 = f1.(2ul) in
  let f13 = f1.(3ul) in
  let f14 = f1.(4ul) in
  let f20 = f2.(0ul) in
  let f21 = f2.(1ul) in
  let f22 = f2.(2ul) in
  let f23 = f2.(3ul) in
  let f24 = f2.(4ul) in
  let (o0,o1,o2,o3,o4) =
    fadd5 #w (f10,f11,f12,f13,f14) (f20,f21,f22,f23,f24) in
  out.(0ul) <- o0;
  out.(1ul) <- o1;
  out.(2ul) <- o2;
  out.(3ul) <- o3;
  out.(4ul) <- o4

#reset-options "--z3rlimit 50 --using_facts_from '* -FStar.Seq'"

inline_for_extraction
val fmul_r:
    #w:lanes
  -> out:felem w
  -> f1:felem w
  -> r:felem w
  -> r5:felem w
  -> Stack unit
    (requires fun h ->
      live h out /\ live h f1 /\
      live h r /\ live h r5 /\
      felem_fits h f1 (2, 3, 2, 2, 2) /\
      felem_fits h r (1, 2, 1, 1, 1) /\
      felem_fits h r5 (5, 10, 5, 5, 5) /\
      as_tup5 h r5 == precomp_r5 (as_tup5 h r))
    (ensures  fun h0 _ h1 ->
      modifies (loc out) h0 h1 /\
      acc_inv_t (as_tup5 h1 out) /\
      feval h1 out == LSeq.map2 (S.pfmul) (feval h0 f1) (feval h0 r))
let fmul_r #w out f1 r r5 =
  let r0 = r.(0ul) in
  let r1 = r.(1ul) in
  let r2 = r.(2ul) in
  let r3 = r.(3ul) in
  let r4 = r.(4ul) in

  let r50 = r5.(0ul) in
  let r51 = r5.(1ul) in
  let r52 = r5.(2ul) in
  let r53 = r5.(3ul) in
  let r54 = r5.(4ul) in

  let f10 = f1.(0ul) in
  let f11 = f1.(1ul) in
  let f12 = f1.(2ul) in
  let f13 = f1.(3ul) in
  let f14 = f1.(4ul) in

  let (o0, o1, o2, o3, o4) =
    fmul_r5 #w (f10, f11, f12, f13, f14)
      (r0, r1, r2, r3, r4) (r50, r51, r52, r53, r54) in
  out.(0ul) <- o0;
  out.(1ul) <- o1;
  out.(2ul) <- o2;
  out.(3ul) <- o3;
  out.(4ul) <- o4

inline_for_extraction
val fadd_mul_r:
    #w:lanes
  -> acc:felem w
  -> f1:felem w
  -> p:precomp_r w
  -> Stack unit
    (requires fun h ->
      live h acc /\ live h f1 /\ live h p /\
     (let r = gsub p 0ul 5ul in
      let r5 = gsub p 5ul 5ul in
      felem_fits h acc (1, 2, 1, 1, 1) /\
      felem_fits h f1 (1, 1, 1, 1, 1) /\
      felem_fits h r (1, 1, 1, 1, 1) /\
      felem_fits h r5 (5, 5, 5, 5, 5) /\
      as_tup5 h r5 == precomp_r5 (as_tup5 h r)))
    (ensures  fun h0 _ h1 ->
      modifies (loc acc) h0 h1 /\
      //as_tup5 h1 acc == fadd_mul_r5 (as_tup5 h0 acc) (as_tup5 h0 f1) (as_tup5 h0 r) (as_tup5 h0 r5) /\
      acc_inv_t (as_tup5 h1 acc) /\
      feval h1 acc == LSeq.map2 (S.pfmul)
        (LSeq.map2 (S.pfadd) (feval h0 acc) (feval h0 f1)) (feval h0 (gsub p 0ul 5ul)))
let fadd_mul_r #w out f1 p =
  let r = sub p 0ul 5ul in
  let r5 = sub p 5ul 5ul in
  let r0 = r.(0ul) in
  let r1 = r.(1ul) in
  let r2 = r.(2ul) in
  let r3 = r.(3ul) in
  let r4 = r.(4ul) in

  let r50 = r5.(0ul) in
  let r51 = r5.(1ul) in
  let r52 = r5.(2ul) in
  let r53 = r5.(3ul) in
  let r54 = r5.(4ul) in

  let f10 = f1.(0ul) in
  let f11 = f1.(1ul) in
  let f12 = f1.(2ul) in
  let f13 = f1.(3ul) in
  let f14 = f1.(4ul) in

  let a0 = out.(0ul) in
  let a1 = out.(1ul) in
  let a2 = out.(2ul) in
  let a3 = out.(3ul) in
  let a4 = out.(4ul) in

  let (o0, o1, o2, o3, o4) =
    fadd_mul_r5 #w (a0, a1, a2, a3, a4) (f10, f11, f12, f13, f14)
      (r0, r1, r2, r3, r4) (r50, r51, r52, r53, r54) in
  out.(0ul) <- o0;
  out.(1ul) <- o1;
  out.(2ul) <- o2;
  out.(3ul) <- o3;
  out.(4ul) <- o4

inline_for_extraction
val fmul_rn:
    #w:lanes
  -> out:felem w
  -> f1:felem w
  -> p:precomp_r w
  -> Stack unit
    (requires fun h ->
      live h out /\ live h f1 /\ live h p /\
     (let rn = gsub p 10ul 5ul in
      let rn_5 = gsub p 15ul 5ul in
      felem_fits h f1 (2, 3, 2, 2, 2) /\
      felem_fits h rn (1, 2, 1, 1, 1) /\
      felem_fits h rn_5 (5, 10, 5, 5, 5) /\
      as_tup5 h rn_5 == precomp_r5 (as_tup5 h rn)))
    (ensures  fun h0 _ h1 ->
      modifies (loc out) h0 h1 /\
      acc_inv_t (as_tup5 h1 out) /\
      feval h1 out == LSeq.map2 S.pfmul (feval h0 f1) (feval h0 (gsub p 10ul 5ul)))
let fmul_rn #w out f1 p =
  let rn = sub p 10ul 5ul in
  let rn5 = sub p 15ul 5ul in
  fmul_r #w out f1 rn rn5

inline_for_extraction
val reduce_felem:
    #w:lanes
  -> f:felem w
  -> Stack unit
    (requires fun h ->
      live h f /\ acc_inv_t (as_tup5 h f))
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      feval h1 f == feval h0 f /\
      felem_less h1 f S.prime)
let reduce_felem #w f =
  let f0 = f.(0ul) in
  let f1 = f.(1ul) in
  let f2 = f.(2ul) in
  let f3 = f.(3ul) in
  let f4 = f.(4ul) in
  let (f0, f1, f2, f3, f4) =
    reduce_felem5 (f0, f1, f2, f3, f4) in
  f.(0ul) <- f0;
  f.(1ul) <- f1;
  f.(2ul) <- f2;
  f.(3ul) <- f3;
  f.(4ul) <- f4

inline_for_extraction
val precompute_shift_reduce:
    #w:lanes
  -> f1:felem w
  -> f2:felem w
  -> Stack unit
    (requires fun h -> live h f1 /\ live h f2)
    (ensures  fun h0 _ h1 ->
      modifies (loc f1) h0 h1 /\
      as_tup5 h1 f1 == precomp_r5 (as_tup5 h0 f2))
let precompute_shift_reduce #w f1 f2 =
  let f20 = f2.(0ul) in
  let f21 = f2.(1ul) in
  let f22 = f2.(2ul) in
  let f23 = f2.(3ul) in
  let f24 = f2.(4ul) in
  f1.(0ul) <- vec_smul_mod f20 (u64 5);
  f1.(1ul) <- vec_smul_mod f21 (u64 5);
  f1.(2ul) <- vec_smul_mod f22 (u64 5);
  f1.(3ul) <- vec_smul_mod f23 (u64 5);
  f1.(4ul) <- vec_smul_mod f24 (u64 5)

noextract
val load_precompute_r_post:
    #w:lanes
  -> h:mem
  -> p:precomp_r w
  -> Type0
let load_precompute_r_post #w h p =
  assert_norm (pow2 128 < S.prime);
  let r = gsub p 0ul 5ul in
  let r_5 = gsub p 5ul 5ul in
  let rn = gsub p 10ul 5ul in
  let rn_5 = gsub p 15ul 5ul in
  felem_fits h r (1, 1, 1, 1, 1) /\
  felem_fits h r_5 (5, 5, 5, 5, 5) /\
  felem_fits h rn (1, 2, 1, 1, 1) /\
  felem_fits h rn_5 (5, 10, 5, 5, 5) /\
  as_tup5 h r_5 == precomp_r5 (as_tup5 h r) /\
  as_tup5 h rn_5 == precomp_r5 (as_tup5 h rn) /\
  feval h rn == S.compute_rw (feval h r)

inline_for_extraction
val load_felem:
    #w:lanes
  -> f:felem w
  -> lo:uint64xN w
  -> hi:uint64xN w
  -> Stack unit
    (requires fun h -> live h f)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      felem_less h1 f (pow2 128) /\
      feval h1 f == LSeq.createi #S.pfelem w
	(fun i -> uint_v (vec_v hi).[i] * pow2 64 + uint_v (vec_v lo).[i]))
let load_felem #w f lo hi = admit();
  f.(0ul) <- vec_and lo (mask26 w);
  f.(1ul) <- vec_and (vec_shift_right lo 26ul) (mask26 w);
  f.(2ul) <- vec_or (vec_shift_right lo 52ul) (vec_shift_left (vec_and hi (mask14 w)) 12ul);
  f.(3ul) <- vec_and (vec_shift_right hi 14ul) (mask26 w);
  f.(4ul) <- vec_shift_right hi 40ul

inline_for_extraction
val load_precompute_r1:
    p:precomp_r 1
  -> r0:uint64
  -> r1:uint64
  -> Stack unit
    (requires fun h -> live h p)
    (ensures  fun h0 _ h1 ->
      modifies (loc p) h0 h1 /\
      load_precompute_r_post h1 p /\
      feval h1 (gsub p 0ul 5ul) ==
        LSeq.create 1 (uint_v r1 * pow2 64 + uint_v r0))
let load_precompute_r1 p r0 r1 =
  let r = sub p 0ul 5ul in
  let r5 = sub p 5ul 5ul in
  let rn = sub p 10ul 5ul in
  let rn_5 = sub p 15ul 5ul in

  let r_vec0 = vec_load r0 1 in
  let r_vec1 = vec_load r1 1 in

  let h0 = ST.get () in
  load_felem r r_vec0 r_vec1;
  let h1 = ST.get () in
  LSeq.eq_intro
    (LSeq.createi #S.pfelem 1 (fun i -> uint_v (vec_v r_vec1).[i] * pow2 64 + uint_v (vec_v r_vec0).[i]))
    (LSeq.create 1 (uint_v r1 * pow2 64 + uint_v r0));
  assert (feval h1 r == LSeq.create 1 (uint_v r1 * pow2 64 + uint_v r0));
  precompute_shift_reduce r5 r;

  copy_felem #_ #(1,1,1,1,1) rn r;
  copy_felem #_ #(5,5,5,5,5) rn_5 r5

inline_for_extraction
val load_precompute_r2:
    p:precomp_r 2
  -> r0:uint64
  -> r1:uint64
  -> Stack unit
    (requires fun h -> live h p)
    (ensures  fun h0 _ h1 ->
      modifies (loc p) h0 h1 /\
      load_precompute_r_post h1 p /\
      feval h1 (gsub p 0ul 5ul) ==
        LSeq.create 2 (uint_v r1 * pow2 64 + uint_v r0))
let load_precompute_r2 p r0 r1 =
  let r = sub p 0ul 5ul in
  let r5 = sub p 5ul 5ul in
  let rn = sub p 10ul 5ul in
  let rn_5 = sub p 15ul 5ul in

  let r_vec0 = vec_load r0 2 in
  let r_vec1 = vec_load r1 2 in

  let h0 = ST.get () in
  load_felem r r_vec0 r_vec1;
  let h1 = ST.get () in
  LSeq.eq_intro
    (LSeq.createi #S.pfelem 2 (fun i -> uint_v (vec_v r_vec1).[i] * pow2 64 + uint_v (vec_v r_vec0).[i]))
    (LSeq.create 2 (uint_v r1 * pow2 64 + uint_v r0));
  assert (feval h1 r == LSeq.create 2 (uint_v r1 * pow2 64 + uint_v r0));

  precompute_shift_reduce r5 r;
  fmul_r rn r r r5;
  precompute_shift_reduce rn_5 rn

inline_for_extraction
val load_precompute_r4:
    p:precomp_r 4
  -> r0:uint64
  -> r1:uint64
  -> Stack unit
    (requires fun h -> live h p)
    (ensures  fun h0 _ h1 ->
      modifies (loc p) h0 h1 /\
      load_precompute_r_post h1 p /\
      feval h1 (gsub p 0ul 5ul) ==
        LSeq.create 4 (uint_v r1 * pow2 64 + uint_v r0))
let load_precompute_r4 p r0 r1 =
  let r = sub p 0ul 5ul in
  let r5 = sub p 5ul 5ul in
  let rn = sub p 10ul 5ul in
  let rn_5 = sub p 15ul 5ul in

  let r_vec0 = vec_load r0 4 in
  let r_vec1 = vec_load r1 4 in

  let h0 = ST.get () in
  load_felem r r_vec0 r_vec1;
  let h1 = ST.get () in
  LSeq.eq_intro
    (LSeq.createi #S.pfelem 4 (fun i -> uint_v (vec_v r_vec1).[i] * pow2 64 + uint_v (vec_v r_vec0).[i]))
    (LSeq.create 4 (uint_v r1 * pow2 64 + uint_v r0));
  assert (feval h1 r == LSeq.create 4 (uint_v r1 * pow2 64 + uint_v r0));

  precompute_shift_reduce r5 r;
  fmul_r rn r r r5;
  precompute_shift_reduce rn_5 rn;
  fmul_r rn rn rn rn_5;
  precompute_shift_reduce rn_5 rn

inline_for_extraction
val load_precompute_r:
    #w:lanes
  -> p:precomp_r w
  -> r0:uint64
  -> r1:uint64
  -> Stack unit
    (requires fun h -> live h p)
    (ensures  fun h0 _ h1 ->
      modifies (loc p) h0 h1 /\
      load_precompute_r_post #w h1 p /\
      feval h1 (gsub p 0ul 5ul) ==
        LSeq.create w (uint_v r1 * pow2 64 + uint_v r0))
let load_precompute_r #w p r0 r1 =
  match w with
  | 1 -> load_precompute_r1 p r0 r1
  | 2 -> load_precompute_r2 p r0 r1
  | 4 -> load_precompute_r4 p r0 r1

val lemma_nat_from_bytes_le1: b:LSeq.lseq uint8 16 ->
  Lemma (
    let lo:LSeq.lseq uint64 1 = BSeq.uints_from_bytes_le (LSeq.sub b 0 8) in
    let hi:LSeq.lseq uint64 1 = BSeq.uints_from_bytes_le (LSeq.sub b 8 8) in
    BSeq.nat_from_bytes_le b == pow2 64 * uint_v hi.[0] + uint_v lo.[0])
let lemma_nat_from_bytes_le1 b = admit()

inline_for_extraction
val load_felem1_le:
    f:felem 1
  -> b:lbuffer uint8 16ul
  -> Stack unit
    (requires fun h -> live h f /\ live h b)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      felem_less h1 f (pow2 128) /\
      feval h1 f == S.load_elem1 (as_seq h0 b))
let load_felem1_le f b =
  let h0 = ST.get () in
  let lo = vec_load_le U64 1 (sub b 0ul 8ul) in
  let hi = vec_load_le U64 1 (sub b 8ul 8ul) in

  load_felem f lo hi;
  let h1 = ST.get () in
  assert (feval h1 f == LSeq.createi #S.pfelem 1 (fun i -> uint_v (vec_v hi).[i] * pow2 64 + uint_v (vec_v lo).[i]));
  lemma_nat_from_bytes_le1 (as_seq h0 b);
  assert (uint_v (vec_v hi).[0] * pow2 64 + uint_v (vec_v lo).[0] == BSeq.nat_from_bytes_le (as_seq h0 b));
  LSeq.eq_intro
    (LSeq.createi #S.pfelem 1 (fun i -> uint_v (vec_v hi).[i] * pow2 64 + uint_v (vec_v lo).[i]))
    (LSeq.create 1 (BSeq.nat_from_bytes_le (as_seq h0 b)))

val vec_interleave_low_lemma64_2: b1:uint64xN 2 -> b2:uint64xN 2 ->
  Lemma (vec_v (vec_interleave_low b1 b2) == create2 (vec_v b1).[0] (vec_v b2).[0])
let vec_interleave_low_lemma64_2 b1 b2 = admit()

val vec_interleave_high_lemma64_2: b1:uint64xN 2 -> b2:uint64xN 2 ->
  Lemma (vec_v (vec_interleave_high b1 b2) == create2 (vec_v b1).[1] (vec_v b2).[1])
let vec_interleave_high_lemma64_2 b1 b2 = admit()

val lemma_nat_from_bytes_le2: b:LSeq.lseq uint8 32 ->
  Lemma (
    let lo:LSeq.lseq uint64 2 = BSeq.uints_from_bytes_le (LSeq.sub b 0 16) in
    let hi:LSeq.lseq uint64 2 = BSeq.uints_from_bytes_le (LSeq.sub b 16 16) in
    let b1 = BSeq.nat_from_bytes_le (LSeq.sub b 0 16) in
    let b2 = BSeq.nat_from_bytes_le (LSeq.sub b 16 16) in
    b1 == pow2 64 * uint_v lo.[1] + uint_v lo.[0] /\
    b2 == pow2 64 * uint_v hi.[1] + uint_v hi.[0])
let lemma_nat_from_bytes_le2 b = admit()

inline_for_extraction
val load_felem2_le:
    f:felem 2
  -> b:lbuffer uint8 32ul
  -> Stack unit
    (requires fun h -> live h f /\ live h b)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      felem_less h1 f (pow2 128) /\
      feval h1 f == S.load_elem2 (as_seq h0 b))
let load_felem2_le f b =
  let h0 = ST.get () in
  let b1 = vec_load_le U64 2 (sub b 0ul 16ul) in
  let b2 = vec_load_le U64 2 (sub b 16ul 16ul) in
  let lo = vec_interleave_low b1 b2 in
  let hi = vec_interleave_high b1 b2 in
  load_felem f lo hi;
  let h1 = ST.get () in
  //assert (
    //feval h1 f == LSeq.createi #S.pfelem 2
    //(fun i -> uint_v (vec_v hi).[i] * pow2 64 + uint_v (vec_v lo).[i]));

  vec_interleave_low_lemma64_2 b1 b2;
  //assert ((vec_v lo).[0] == (vec_v b1).[0]);
  //assert ((vec_v lo).[1] == (vec_v b2).[0]);

  vec_interleave_high_lemma64_2 b1 b2;
  //assert ((vec_v hi).[0] == (vec_v b1).[1]);
  //assert ((vec_v hi).[1] == (vec_v b2).[1]);

  lemma_nat_from_bytes_le2 (as_seq h0 b);
  //assert (BSeq.nat_from_bytes_le (LSeq.sub (as_seq h0 b) 0 16) == pow2 64 * uint_v (vec_v hi).[0] + uint_v (vec_v lo).[0]);
  //assert (BSeq.nat_from_bytes_le (LSeq.sub (as_seq h0 b) 16 16) == pow2 64 * uint_v (vec_v hi).[1] + uint_v (vec_v lo).[1]);
  LSeq.eq_intro (feval h1 f) (S.load_elem2 (as_seq h0 b))

 //LSeq.eq_intro
    //(LSeq.createi #S.pfelem 2 (fun i -> uint_v (vec_v hi).[i] * pow2 64 + uint_v (vec_v lo).[i]))
    //(create2 (BSeq.nat_from_bytes_le (LSeq.sub (as_seq h0 b) 0 16)) (BSeq.nat_from_bytes_le (LSeq.sub (as_seq h0 b) 16 16)))

val vec_interleave_low_lemma64_4: b1:uint64xN 4 -> b2:uint64xN 4 ->
  Lemma (vec_v (vec_interleave_low b1 b2) == create4 (vec_v b1).[0] (vec_v b2).[0] (vec_v b1).[2] (vec_v b2).[2])
let vec_interleave_low_lemma64_4 b1 b2 = admit()

val vec_interleave_high_lemma64_4: b1:uint64xN 4 -> b2:uint64xN 4 ->
  Lemma (vec_v (vec_interleave_high b1 b2) == create4 (vec_v b1).[1] (vec_v b2).[1] (vec_v b1).[3] (vec_v b2).[3])
let vec_interleave_high_lemma64_4 b1 b2 = admit()

val vec_interleave_low_lemma128_2: b1:vec_t U128 2 -> b2:vec_t U128 2 ->
  Lemma (vec_v (vec_interleave_low b1 b2) == create2 (vec_v b1).[0] (vec_v b2).[0])
let vec_interleave_low_lemma128_2 b1 b2 = admit()

val vec_interleave_high_lemma128_2: b1:vec_t U128 2 -> b2:vec_t U128 2 ->
  Lemma (vec_v (vec_interleave_high b1 b2) == create2 (vec_v b1).[1] (vec_v b2).[1])
let vec_interleave_high_lemma128_2 b1 b2 = admit()

val lemma_cast_vec128_to_vec64: b:vec_t U128 2 ->
  Lemma (
    let r = vec_v (cast U64 4 b) in
    let b = vec_v b in
    uint_v b.[0] == uint_v r.[0] + uint_v r.[1] * pow2 64 /\
    uint_v b.[1] == uint_v r.[2] + uint_v r.[3] * pow2 64)
let lemma_cast_vec128_to_vec64 b = admit()

val lemma_nat_from_bytes_le128: b:LSeq.lseq uint8 64 ->
  Lemma (
    let lo:LSeq.lseq uint128 2 = BSeq.uints_from_bytes_le (LSeq.sub b 0 32) in
    let hi:LSeq.lseq uint128 2 = BSeq.uints_from_bytes_le (LSeq.sub b 32 32) in
    let b1 = BSeq.nat_from_bytes_le (LSeq.sub b 0 16) in
    let b2 = BSeq.nat_from_bytes_le (LSeq.sub b 16 16) in
    let b3 = BSeq.nat_from_bytes_le (LSeq.sub b 32 16) in
    let b4 = BSeq.nat_from_bytes_le (LSeq.sub b 48 16) in
    b1 == uint_v lo.[0] /\
    b2 == uint_v lo.[1] /\
    b3 == uint_v hi.[0] /\
    b4 == uint_v hi.[1])
let lemma_nat_from_bytes_le128 b = admit()

val lemma_load_felem4_le: b:LSeq.lseq uint8 64 -> lo0:vec_t U128 2 -> hi0:vec_t U128 2 ->
  Lemma
  (requires (
    let lo:LSeq.lseq uint128 2 = BSeq.uints_from_bytes_le (LSeq.sub b 0 32) in
    let hi:LSeq.lseq uint128 2 = BSeq.uints_from_bytes_le (LSeq.sub b 32 32) in
    vec_v lo0 == create2 lo.[0] hi.[0] /\
    vec_v hi0 == create2 lo.[1] hi.[1]))
  (ensures (
    let lo:LSeq.lseq uint128 2 = BSeq.uints_from_bytes_le (LSeq.sub b 0 32) in
    let hi:LSeq.lseq uint128 2 = BSeq.uints_from_bytes_le (LSeq.sub b 32 32) in
    let b1 = BSeq.nat_from_bytes_le (LSeq.sub b 0 16) in
    let b2 = BSeq.nat_from_bytes_le (LSeq.sub b 16 16) in
    let b3 = BSeq.nat_from_bytes_le (LSeq.sub b 32 16) in
    let b4 = BSeq.nat_from_bytes_le (LSeq.sub b 48 16) in
    let lo1 = vec_v (cast U64 4 lo0) in
    let hi1 = vec_v (cast U64 4 hi0) in
    b1 == pow2 64 * uint_v lo1.[1] + uint_v lo1.[0] /\
    b2 == pow2 64 * uint_v hi1.[1] + uint_v hi1.[0] /\
    b3 == pow2 64 * uint_v lo1.[3] + uint_v lo1.[2] /\
    b4 == pow2 64 * uint_v hi1.[3] + uint_v hi1.[2]))
let lemma_load_felem4_le b lo0 hi0 =
  lemma_nat_from_bytes_le128 b;
  lemma_cast_vec128_to_vec64 lo0;
  lemma_cast_vec128_to_vec64 hi0

inline_for_extraction
val load_felem4_le:
    f:felem 4
  -> b:lbuffer uint8 64ul
  -> Stack unit
    (requires fun h -> live h f /\ live h b)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      felem_less h1 f (pow2 128) /\
      feval h1 f == S.load_elem4 (as_seq h0 b))
let load_felem4_le f b =
  let h0 = ST.get () in
  let lo0 = vec_load_le U128 2 (sub b 0ul 32ul) in
  let hi0 = vec_load_le U128 2 (sub b 32ul 32ul) in
  let lo1 = vec_interleave_low lo0 hi0 in
  let hi1 = vec_interleave_high lo0 hi0 in
  let h1 = ST.get () in
  //assert (vec_v lo0 == BSeq.uints_from_bytes_le (LSeq.sub (as_seq h0 b) 0 32));
  //assert (vec_v hi0 == BSeq.uints_from_bytes_le (LSeq.sub (as_seq h0 b) 32 32));

  vec_interleave_low_lemma128_2 lo0 hi0;
  vec_interleave_high_lemma128_2 lo0 hi0;

  //assert (vec_v lo1 == create2 (vec_v lo0).[0] (vec_v hi0).[0]);
  //assert (vec_v hi1 == create2 (vec_v lo0).[1] (vec_v hi0).[1]);

  let lo2 = cast U64 4 lo1 in
  let hi2 = cast U64 4 hi1 in

  let lo = vec_interleave_low lo2 hi2 in
  let hi = vec_interleave_high lo2 hi2 in
  vec_interleave_low_lemma64_4 lo2 hi2;
  vec_interleave_high_lemma64_4 lo2 hi2;
  //assert (vec_v lo == create4 (vec_v lo2).[0] (vec_v hi2).[0] (vec_v lo2).[2] (vec_v hi2).[2]);
  //assert (vec_v hi == create4 (vec_v lo2).[1] (vec_v hi2).[1] (vec_v lo2).[3] (vec_v hi2).[3]);

  load_felem f lo hi;
  let h2 = ST.get () in
  //assert (
      //feval h2 f == LSeq.createi #S.pfelem 4
	//(fun i -> uint_v (vec_v hi).[i] * pow2 64 + uint_v (vec_v lo).[i]));
  lemma_load_felem4_le (as_seq h0 b) lo1 hi1;
  LSeq.eq_intro (feval h2 f) (S.load_elem4 (as_seq h0 b))

inline_for_extraction
val load_felems_le:
    #w:lanes
  -> f:felem w
  -> b:lbuffer uint8 (size w *! 16ul)
  -> Stack unit
    (requires fun h -> live h f /\ live h b)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      felem_less h1 f (pow2 128) /\
      feval h1 f == S.load_elem (as_seq h0 b))
let load_felems_le #w f b =
  match w with
  | 1 -> load_felem1_le f b
  | 2 -> load_felem2_le f b
  | 4 -> load_felem4_le f b

val lemma_nat_from_bytes_le: b:LSeq.lseq uint8 16 ->
  Lemma (
    let lo = BSeq.uint_from_bytes_le (LSeq.sub b 0 8) in
    let hi = BSeq.uint_from_bytes_le (LSeq.sub b 8 8) in
    BSeq.nat_from_bytes_le b == pow2 64 * uint_v hi + uint_v lo)
let lemma_nat_from_bytes_le b = admit()

inline_for_extraction
val load_felem_le:
    #w:lanes
  -> f:felem w
  -> b:lbuffer uint8 16ul
  -> Stack unit
    (requires fun h -> live h f /\ live h b)
    (ensures  fun h0 _ h1 ->
      modifies (loc f) h0 h1 /\
      felem_fits h1 f (1, 1, 1, 1, 1) /\
      felem_less h1 f (pow2 128) /\
      feval h1 f == LSeq.create w (BSeq.nat_from_bytes_le (as_seq h0 b)))
let load_felem_le #w f b =
  let lo = uint_from_bytes_le #U64 (sub b 0ul 8ul) in
  let hi = uint_from_bytes_le #U64 (sub b 8ul 8ul) in
  let f0 = vec_load lo w in
  let f1 = vec_load hi w in
  let h0 = ST.get () in
  load_felem f f0 f1;
  let h1 = ST.get () in
  lemma_nat_from_bytes_le (as_seq h0 b);
  LSeq.eq_intro (feval h1 f) (LSeq.create w (BSeq.nat_from_bytes_le (as_seq h0 b)))

inline_for_extraction
val store_felem:
    #w:lanes
  -> f:felem w
  -> Stack (uint64xN w & uint64xN w)
    (requires fun h ->
      live h f /\ felem_fits h f (1, 1, 1, 1, 3))
    (ensures  fun h0 (lo, hi) h1 -> h0 == h1 /\
      (forall (i:nat). i < w ==>
	v (vec_v hi).[i] * pow2 64 + v (vec_v lo).[i] == (fas_nat h0 f).[i] % pow2 128))
let store_felem #w f = admit();
  let f0 = f.(0ul) in
  let f1 = f.(1ul) in
  let f2 = f.(2ul) in
  let f3 = f.(3ul) in
  let f4 = f.(4ul) in
  store_felem5 #w (f0, f1, f2, f3, f4)

val lemma_nat_to_bytes_le: lo:uint64xN 1 -> hi:uint64xN 1 ->
  Lemma (
    let b0 = BSeq.uints_to_bytes_le (vec_v lo) in
    let b1 = BSeq.uints_to_bytes_le (vec_v hi) in
    BSeq.nat_to_bytes_le 16 (v (vec_v hi).[0] * pow2 64 + v (vec_v lo).[0]) == LSeq.concat b0 b1)
let lemma_nat_to_bytes_le lo hi = admit()

inline_for_extraction
val store_felem1_le:
    b:lbuffer uint8 16ul
  -> f:felem 1
  -> Stack unit
    (requires fun h ->
      live h f /\ live h b /\ felem_fits h f (1, 1, 1, 1, 3))
    (ensures  fun h0 _ h1 ->
      modifies (loc b) h0 h1 /\
      as_seq h1 b == BSeq.nat_to_bytes_le 16 ((fas_nat h0 f).[0] % pow2 128))
let store_felem1_le b f =
  let h0 = ST.get () in
  let (r0, r1) = store_felem #1 f in
  assert (v (vec_v r1).[0] * pow2 64 + v (vec_v r0).[0] == (fas_nat h0 f).[0] % pow2 128);
  vec_store_le (sub b 0ul 8ul) r0;
  vec_store_le (sub b 8ul 8ul) r1;
  let h1 = ST.get () in
  lemma_nat_to_bytes_le r0 r1;
  LSeq.lemma_concat2 8 (LSeq.sub (as_seq h1 b) 0 8) 8 (LSeq.sub (as_seq h1 b) 8 8) (as_seq h1 b);
  LSeq.eq_intro (as_seq h1 b) (BSeq.nat_to_bytes_le 16 ((fas_nat h0 f).[0] % pow2 128))

val lemma_nat_to_bytes_le1: r:vec_t U64 2 ->
  Lemma (
    BSeq.uints_to_bytes_le (vec_v r) ==
    BSeq.nat_to_bytes_le 16 (v (vec_v r).[1] * pow2 64 + v (vec_v r).[0]))
let lemma_nat_to_bytes_le1 r = admit()

inline_for_extraction
val store_felem2_le:
    b:lbuffer uint8 16ul
  -> f:felem 2
  -> Stack unit
    (requires fun h ->
      live h f /\ live h b /\ felem_fits h f (1, 1, 1, 1, 3))
    (ensures  fun h0 _ h1 ->
      modifies (loc b) h0 h1 /\
      as_seq h1 b == BSeq.nat_to_bytes_le 16 ((fas_nat h0 f).[0] % pow2 128))
let store_felem2_le b f =
  let (f0, f1) = store_felem #2 f in
  let r0:vec_t U64 2 = vec_interleave_low f0 f1 in
  vec_interleave_low_lemma64_2 f0 f1;
  //assert (v (vec_v r0).[1] * pow2 64 + v (vec_v r0).[0] == (fas_nat h0 f).[0] % pow2 128);
  vec_store_le b r0;
  lemma_nat_to_bytes_le1 r0

val lemma_cast_vec64_to_vec128: b:vec_t U64 4 ->
  Lemma (
    let r = vec_v (cast U128 2 b) in
    let b = vec_v b in
    uint_v r.[0] == uint_v b.[0] + uint_v b.[1] * pow2 64 /\
    uint_v r.[1] == uint_v b.[2] + uint_v b.[3] * pow2 64)
let lemma_cast_vec64_to_vec128 b = admit()

val lemma_nat_to_bytes_le2: r:vec_t U128 2 ->
  Lemma (
    let b = BSeq.uints_to_bytes_le (vec_v r) in
    LSeq.sub b 0 16 == BSeq.uint_to_bytes_le (vec_v r).[0] /\
    LSeq.sub b 16 16 == BSeq.uint_to_bytes_le (vec_v r).[1])
let lemma_nat_to_bytes_le2 r = admit()

val lemma_nat_to_bytes_le0: r:uint128 ->
  Lemma (BSeq.uint_to_bytes_le r == BSeq.nat_to_bytes_le 16 (uint_v r))
let lemma_nat_to_bytes_le0 r = admit()

inline_for_extraction
val store_felem4_le:
    b:lbuffer uint8 16ul
  -> f:felem 4
  -> Stack unit
    (requires fun h ->
      live h f /\ live h b /\ felem_fits h f (1, 1, 1, 1, 3))
    (ensures  fun h0 _ h1 ->
      modifies (loc b) h0 h1 /\
      as_seq h1 b == BSeq.nat_to_bytes_le 16 ((fas_nat h0 f).[0] % pow2 128))
let store_felem4_le b f =
  push_frame ();
  let (f0, f1) = store_felem #4 f in
  let lo = vec_interleave_low f0 f1 in
  let hi = vec_interleave_high f0 f1 in
  vec_interleave_low_lemma64_4 f0 f1;
  vec_interleave_high_lemma64_4 f0 f1;
  let lo1 = cast U128 2 lo in
  let hi1 = cast U128 2 hi in
  lemma_cast_vec64_to_vec128 lo;
  lemma_cast_vec64_to_vec128 hi;
  let r0 = vec_interleave_low lo1 hi1 in
  vec_interleave_low_lemma128_2 lo1 hi1;
  let tmp = create 32ul (u8 0) in
  vec_store_le tmp r0;
  lemma_nat_to_bytes_le2 r0;
  let h0 = ST.get () in
  copy b (sub tmp 0ul 16ul);
  let h1 = ST.get () in
  assert (as_seq h1 b == BSeq.uint_to_bytes_le (vec_v r0).[0]);
  assert (v (vec_v r0).[0] == v (vec_v f1).[0] * pow2 64 + v (vec_v f0).[0]);
  lemma_nat_to_bytes_le0 (vec_v r0).[0];
  pop_frame()

inline_for_extraction
val store_felem_le:
    #w:lanes
  -> b:lbuffer uint8 16ul
  -> f:felem w
  -> Stack unit
    (requires fun h ->
      live h f /\ live h b /\ felem_fits h f (1, 1, 1, 1, 3))
    (ensures  fun h0 _ h1 ->
      modifies (loc b) h0 h1 /\
      as_seq h1 b == BSeq.nat_to_bytes_le 16 ((fas_nat h0 f).[0] % pow2 128))
let store_felem_le #w b f =
  match w with
  | 1 -> store_felem1_le b f
  | 2 -> store_felem2_le b f
  | 4 -> store_felem4_le b f

//[@ CInline]
inline_for_extraction
val carry_full_felem:
    #w:lanes
  -> out:felem w
  -> inp:felem_wide w
  -> Stack unit
    (requires fun h -> live h out /\ live h inp)
    (ensures  fun h0 _ h1 -> modifies (loc out) h0 h1)
[@ CInline]
let carry_full_felem #w out inp =
  let i0 = inp.(0ul) in
  let i1 = inp.(1ul) in
  let i2 = inp.(2ul) in
  let i3 = inp.(3ul) in
  let i4 = inp.(4ul) in
  let (t0, t1, t2, t3, t4) =
    carry_full_felem5 (i0, i1, i2, i3, i4) in
  out.(0ul) <- t0;
  out.(1ul) <- t1;
  out.(2ul) <- t2;
  out.(3ul) <- t3;
  out.(4ul) <- t4

inline_for_extraction
val fmul_r1_normalize:
    out:felem 1
  -> p:precomp_r 1
  -> Stack unit
    (requires fun h -> live h out /\ live h p)
    (ensures  fun h0 _ h1 -> modifies (loc out |+| loc p) h0 h1)
[@ CInline]
let fmul_r1_normalize out p = admit();
  let r = sub p 0ul 5ul in
  let r5 = sub p 5ul 5ul in
  fmul_r out out r r5

inline_for_extraction
val fmul_r2_normalize:
    out:felem 2
  -> p:precomp_r 2
  -> Stack unit
    (requires fun h -> live h out /\ live h p)
    (ensures  fun h0 _ h1 -> modifies (loc out |+| loc p) h0 h1)
[@ CInline]
let fmul_r2_normalize out p =
  //push_frame();
  admit();
  //let tmp = create_felem 2 in
  let r = sub p 0ul 5ul in
  let r2 = sub p 10ul 5ul in
  let r2_5 = sub p 15ul 5ul in
  r2.(0ul) <- vec_interleave_low r2.(0ul) r.(0ul);
  r2.(1ul) <- vec_interleave_low r2.(1ul) r.(1ul);
  r2.(2ul) <- vec_interleave_low r2.(2ul) r.(2ul);
  r2.(3ul) <- vec_interleave_low r2.(3ul) r.(3ul);
  r2.(4ul) <- vec_interleave_low r2.(4ul) r.(4ul);
  precompute_shift_reduce r2_5 r2;
  fmul_r out out r2 r2_5;
  //mul_felem tmp out r2 r2_5;
  //carry_wide_felem out tmp;
  let o0 = out.(0ul) in
  let o1 = out.(1ul) in
  let o2 = out.(2ul) in
  let o3 = out.(3ul) in
  let o4 = out.(4ul) in
  let o0 = vec_add_mod o0 (vec_interleave_high o0 o0) in
  let o1 = vec_add_mod o1 (vec_interleave_high o1 o1) in
  let o2 = vec_add_mod o2 (vec_interleave_high o2 o2) in
  let o3 = vec_add_mod o3 (vec_interleave_high o3 o3) in
  let o4 = vec_add_mod o4 (vec_interleave_high o4 o4) in
  let (o0, o1, o2, o3, o4) = carry_full_felem5 (o0, o1, o2, o3, o4) in
  out.(0ul) <- o0;
  out.(1ul) <- o1;
  out.(2ul) <- o2;
  out.(3ul) <- o3;
  out.(4ul) <- o4
  //pop_frame()

inline_for_extraction
val fmul_r4_normalize:
    out:felem 4
  -> p:precomp_r 4
  -> Stack unit
    (requires fun h -> live h out /\ live h p)
    (ensures  fun h0 _ h1 -> modifies (loc out |+| loc p) h0 h1)
[@ CInline]
let fmul_r4_normalize out p =
  push_frame();
  admit();
  let r = sub p 0ul 5ul in
  let r_5 = sub p 5ul 5ul in
  let r4 = sub p 10ul 5ul in
  let r4_5 = sub p 15ul 5ul in
  let r2 = create_felem 4 in
  let r3 = create_felem 4 in
  let tmp = create_felem 4 in
  fmul_r r2 r r r_5;
  //mul_felem tmp r r r_5;
  //carry_wide_felem r2 tmp;
  fmul_r r3 r2 r r_5;
  //mul_felem tmp r2 r r_5;
  //carry_wide_felem r3 tmp;
  let h0 = ST.get() in
  loop_nospec #h0 5ul r2
  (fun i ->
    let v1212 = vec_interleave_low r2.(i) r.(i) in
    let v3434 = vec_interleave_low r4.(i) r3.(i) in
    let v1234 = vec_interleave_low (cast U128 2 v3434) (cast U128 2 v1212) in
    r2.(i) <- cast U64 4 v1234
  );

  let r1234 = r2 in
  let r1234_5 = r3 in
  precompute_shift_reduce r1234_5 r1234;
  fmul_r out out r1234 r1234_5;
  //mul_felem tmp out r1234 r1234_5;
  //carry_wide_felem out tmp;

  loop_nospec #h0 5ul out
  (fun i ->
    let oi = out.(i) in
    let v0 = cast U64 4 (vec_interleave_high (cast U128 2 oi) (cast U128 2 oi)) in
    let v1 = vec_add_mod oi v0 in
    let v2 = vec_add_mod v1 (vec_permute4 v1 1ul 1ul 1ul 1ul) in
    out.(i) <- v2
  );
  carry_full_felem out out;
  pop_frame()

inline_for_extraction
val fmul_rn_normalize:
    #w:lanes
  -> out:felem w
  -> p:precomp_r w
  -> Stack unit
    (requires fun h -> live h out /\ live h p)
    (ensures  fun h0 _ h1 -> modifies (loc out |+| loc p) h0 h1)
[@ CInline]
let fmul_rn_normalize #w out p =
  match w with
  | 1 -> fmul_r1_normalize out p
  | 2 -> fmul_r2_normalize out p
  | 4 -> fmul_r4_normalize out p
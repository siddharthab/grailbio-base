// Code generated by " ../gtl/generate.py --prefix=And -DOPCHAR=& --package=simd --output=and_generic.go bitwise_generic.go.tpl ". DO NOT EDIT.

// Copyright 2018 GRAIL, Inc.  All rights reserved.
// Use of this source code is governed by the Apache-2.0
// license that can be found in the LICENSE file.

// +build !amd64 appengine

package simd

// AndUnsafeInplace sets main[pos] := main[pos] & arg[pos] for every position
// in main[].
//
// WARNING: This is a function designed to be used in inner loops, which makes
// assumptions about length and capacity which aren't checked at runtime.  Use
// the safe version of this function when that's a problem.
// Assumptions #2-3 are always satisfied when the last
// potentially-size-increasing operation on arg[] is {Re}makeUnsafe(),
// ResizeUnsafe(), or XcapUnsafe(), and the same is true for main[].
//
// 1. len(arg) and len(main) must be equal.
//
// 2. Capacities are at least RoundUpPow2(len(main) + 1, bytesPerVec).
//
// 3. The caller does not care if a few bytes past the end of main[] are
// changed.
func AndUnsafeInplace(main, arg []byte) {
	for i, x := range main {
		main[i] = x & arg[i]
	}
}

// AndInplace sets main[pos] := main[pos] & arg[pos] for every position in
// main[].  It panics if slice lengths don't match.
func AndInplace(main, arg []byte) {
	if len(arg) != len(main) {
		panic("AndInplace() requires len(arg) == len(main).")
	}
	for i, x := range main {
		main[i] = x & arg[i]
	}
}

// AndUnsafe sets dst[pos] := src1[pos] & src2[pos] for every position in dst.
//
// WARNING: This is a function designed to be used in inner loops, which makes
// assumptions about length and capacity which aren't checked at runtime.  Use
// the safe version of this function when that's a problem.
// Assumptions #2-3 are always satisfied when the last
// potentially-size-increasing operation on src1[] is {Re}makeUnsafe(),
// ResizeUnsafe(), or XcapUnsafe(), and the same is true for src2[] and dst[].
//
// 1. len(src1), len(src2), and len(dst) must be equal.
//
// 2. Capacities are at least RoundUpPow2(len(dst) + 1, bytesPerVec).
//
// 3. The caller does not care if a few bytes past the end of dst[] are
// changed.
func AndUnsafe(dst, src1, src2 []byte) {
	for i, x := range src1 {
		dst[i] = x & src2[i]
	}
}

// And sets dst[pos] := src1[pos] & src2[pos] for every position in dst.  It
// panics if slice lengths don't match.
func And(dst, src1, src2 []byte) {
	dstLen := len(dst)
	if (len(src1) != dstLen) || (len(src2) != dstLen) {
		panic("And() requires len(src1) == len(src2) == len(dst).")
	}
	for i, x := range src1 {
		dst[i] = x & src2[i]
	}
}

// AndConst8UnsafeInplace sets main[pos] := main[pos] & val for every position
// in main[].
//
// WARNING: This is a function designed to be used in inner loops, which makes
// assumptions about length and capacity which aren't checked at runtime.  Use
// the safe version of this function when that's a problem.
// These assumptions are always satisfied when the last
// potentially-size-increasing operation on main[] is {Re}makeUnsafe(),
// ResizeUnsafe(), or XcapUnsafe().
//
// 1. cap(main) is at least RoundUpPow2(len(main) + 1, bytesPerVec).
//
// 2. The caller does not care if a few bytes past the end of main[] are
// changed.
func AndConst8UnsafeInplace(main []byte, val byte) {
	for i, x := range main {
		main[i] = x & val
	}
}

// AndConst8Inplace sets main[pos] := main[pos] & val for every position in
// main[].
func AndConst8Inplace(main []byte, val byte) {
	for i, x := range main {
		main[i] = x & val
	}
}

// AndConst8Unsafe sets dst[pos] := src[pos] & val for every position in dst.
//
// WARNING: This is a function designed to be used in inner loops, which makes
// assumptions about length and capacity which aren't checked at runtime.  Use
// the safe version of this function when that's a problem.
// Assumptions #2-3 are always satisfied when the last
// potentially-size-increasing operation on src[] is {Re}makeUnsafe(),
// ResizeUnsafe(), or XcapUnsafe(), and the same is true for dst[].
//
// 1. len(src) and len(dst) must be equal.
//
// 2. Capacities are at least RoundUpPow2(len(dst) + 1, bytesPerVec).
//
// 3. The caller does not care if a few bytes past the end of dst[] are
// changed.
func AndConst8Unsafe(dst, src []byte, val byte) {
	for i, x := range src {
		dst[i] = x & val
	}
}

// AndConst8 sets dst[pos] := src[pos] & val for every position in dst.  It
// panics if slice lengths don't match.
func AndConst8(dst, src []byte, val byte) {
	if len(src) != len(dst) {
		panic("AndConst8() requires len(src) == len(dst).")
	}
	for i, x := range src {
		dst[i] = x & val
	}
}

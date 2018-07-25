// Copyright 2021 GRAIL, Inc.  All rights reserved.
// Use of this source code is governed by the Apache-2.0
// license that can be found in the LICENSE file.

// +build amd64,!appengine

package PACKAGE

import (
	"reflect"
	"unsafe"
)

// ZZUnsafeInplace sets main[pos] := main[pos] OPCHAR arg[pos] for every position
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
func ZZUnsafeInplace(main, arg []byte) {
	mainLen := len(main)
	argData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&arg)).Data)
	mainData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&main)).Data)
	argWordsIter := argData
	mainWordsIter := mainData
	if mainLen > 2*BytesPerWord {
		nWordMinus2 := (mainLen - BytesPerWord - 1) >> Log2BytesPerWord
		for widx := 0; widx < nWordMinus2; widx++ {
			mainWord := *((*uintptr)(mainWordsIter))
			argWord := *((*uintptr)(argWordsIter))
			*((*uintptr)(mainWordsIter)) = mainWord OPCHAR argWord
			mainWordsIter = unsafe.Add(mainWordsIter, BytesPerWord)
			argWordsIter = unsafe.Add(argWordsIter, BytesPerWord)
		}
	} else if mainLen <= BytesPerWord {
		mainWord := *((*uintptr)(mainWordsIter))
		argWord := *((*uintptr)(argWordsIter))
		*((*uintptr)(mainWordsIter)) = mainWord OPCHAR argWord
		return
	}
	// The last two read-and-writes to main[] usually overlap.  To avoid a
	// store-to-load forwarding slowdown, we read both words before writing
	// either.
	// shuffleLookupOddInplaceSSSE3Asm() uses the same strategy.
	mainWord1 := *((*uintptr)(mainWordsIter))
	argWord1 := *((*uintptr)(argWordsIter))
	finalOffset := uintptr(mainLen - BytesPerWord)
	mainFinalWordPtr := unsafe.Add(mainData, finalOffset)
	argFinalWordPtr := unsafe.Add(argData, finalOffset)
	mainWord2 := *((*uintptr)(mainFinalWordPtr))
	argWord2 := *((*uintptr)(argFinalWordPtr))
	*((*uintptr)(mainWordsIter)) = mainWord1 OPCHAR argWord1
	*((*uintptr)(mainFinalWordPtr)) = mainWord2 OPCHAR argWord2
}

// ZZInplace sets main[pos] := arg[pos] OPCHAR main[pos] for every position in
// main[].  It panics if slice lengths don't match.
func ZZInplace(main, arg []byte) {
	// This takes ~6-8% longer than ZZUnsafeInplace on the short-array benchmark
	// on my Mac.
	mainLen := len(main)
	if len(arg) != mainLen {
		panic("ZZInplace() requires len(arg) == len(main).")
	}
	if mainLen < BytesPerWord {
		// It's probably possible to do better here (e.g. when mainLen is in 4..7,
		// operate on uint32s), but I won't worry about it unless/until that's
		// actually a common case.
		for pos, argByte := range arg {
			main[pos] = main[pos] OPCHAR argByte
		}
		return
	}
	argData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&arg)).Data)
	mainData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&main)).Data)
	argWordsIter := argData
	mainWordsIter := mainData
	if mainLen > 2*BytesPerWord {
		nWordMinus2 := (mainLen - BytesPerWord - 1) >> Log2BytesPerWord
		for widx := 0; widx < nWordMinus2; widx++ {
			mainWord := *((*uintptr)(mainWordsIter))
			argWord := *((*uintptr)(argWordsIter))
			*((*uintptr)(mainWordsIter)) = mainWord OPCHAR argWord
			mainWordsIter = unsafe.Add(mainWordsIter, BytesPerWord)
			argWordsIter = unsafe.Add(argWordsIter, BytesPerWord)
		}
	}
	mainWord1 := *((*uintptr)(mainWordsIter))
	argWord1 := *((*uintptr)(argWordsIter))
	finalOffset := uintptr(mainLen - BytesPerWord)
	mainFinalWordPtr := unsafe.Add(mainData, finalOffset)
	argFinalWordPtr := unsafe.Add(argData, finalOffset)
	mainWord2 := *((*uintptr)(mainFinalWordPtr))
	argWord2 := *((*uintptr)(argFinalWordPtr))
	*((*uintptr)(mainWordsIter)) = mainWord1 OPCHAR argWord1
	*((*uintptr)(mainFinalWordPtr)) = mainWord2 OPCHAR argWord2
}

// ZZUnsafe sets dst[pos] := src1[pos] OPCHAR src2[pos] for every position in dst.
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
func ZZUnsafe(dst, src1, src2 []byte) {
	src1Header := (*reflect.SliceHeader)(unsafe.Pointer(&src1))
	src2Header := (*reflect.SliceHeader)(unsafe.Pointer(&src2))
	dstHeader := (*reflect.SliceHeader)(unsafe.Pointer(&dst))
	nWord := DivUpPow2(len(dst), BytesPerWord, Log2BytesPerWord)

	src1Iter := unsafe.Pointer(src1Header.Data)
	src2Iter := unsafe.Pointer(src2Header.Data)
	dstIter := unsafe.Pointer(dstHeader.Data)
	for widx := 0; widx < nWord; widx++ {
		src1Word := *((*uintptr)(src1Iter))
		src2Word := *((*uintptr)(src2Iter))
		*((*uintptr)(dstIter)) = src1Word OPCHAR src2Word
		src1Iter = unsafe.Add(src1Iter, BytesPerWord)
		src2Iter = unsafe.Add(src2Iter, BytesPerWord)
		dstIter = unsafe.Add(dstIter, BytesPerWord)
	}
}

// ZZ sets dst[pos] := src1[pos] OPCHAR src2[pos] for every position in dst.  It
// panics if slice lengths don't match.
func ZZ(dst, src1, src2 []byte) {
	dstLen := len(dst)
	if (len(src1) != dstLen) || (len(src2) != dstLen) {
		panic("ZZ() requires len(src1) == len(src2) == len(dst).")
	}
	if dstLen < BytesPerWord {
		for pos, src1Byte := range src1 {
			dst[pos] = src1Byte OPCHAR src2[pos]
		}
		return
	}
	src1Data := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&src1)).Data)
	src2Data := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&src2)).Data)
	dstData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&dst)).Data)
	nWordMinus1 := (dstLen - 1) >> Log2BytesPerWord

	src1Iter := src1Data
	src2Iter := src2Data
	dstIter := dstData
	for widx := 0; widx < nWordMinus1; widx++ {
		src1Word := *((*uintptr)(src1Iter))
		src2Word := *((*uintptr)(src2Iter))
		*((*uintptr)(dstIter)) = src1Word OPCHAR src2Word
		src1Iter = unsafe.Add(src1Iter, BytesPerWord)
		src2Iter = unsafe.Add(src2Iter, BytesPerWord)
		dstIter = unsafe.Add(dstIter, BytesPerWord)
	}
	// No store-forwarding problem here.
	finalOffset := uintptr(dstLen - BytesPerWord)
	src1Iter = unsafe.Add(src1Data, finalOffset)
	src2Iter = unsafe.Add(src2Data, finalOffset)
	dstIter = unsafe.Add(dstData, finalOffset)
	src1Word := *((*uintptr)(src1Iter))
	src2Word := *((*uintptr)(src2Iter))
	*((*uintptr)(dstIter)) = src1Word OPCHAR src2Word
}

// ZZConst8UnsafeInplace sets main[pos] := main[pos] OPCHAR val for every position
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
func ZZConst8UnsafeInplace(main []byte, val byte) {
	mainLen := len(main)
	argWord := 0x101010101010101 * uintptr(val)
	mainData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&main)).Data)
	mainWordsIter := mainData
	if mainLen > 2*BytesPerWord {
		nWordMinus2 := (mainLen - BytesPerWord - 1) >> Log2BytesPerWord
		for widx := 0; widx < nWordMinus2; widx++ {
			mainWord := *((*uintptr)(mainWordsIter))
			*((*uintptr)(mainWordsIter)) = mainWord OPCHAR argWord
			mainWordsIter = unsafe.Add(mainWordsIter, BytesPerWord)
		}
	} else if mainLen <= BytesPerWord {
		mainWord := *((*uintptr)(mainWordsIter))
		*((*uintptr)(mainWordsIter)) = mainWord OPCHAR argWord
		return
	}
	mainWord1 := *((*uintptr)(mainWordsIter))
	finalOffset := uintptr(mainLen - BytesPerWord)
	mainFinalWordPtr := unsafe.Add(mainData, finalOffset)
	mainWord2 := *((*uintptr)(mainFinalWordPtr))
	*((*uintptr)(mainWordsIter)) = mainWord1 OPCHAR argWord
	*((*uintptr)(mainFinalWordPtr)) = mainWord2 OPCHAR argWord
}

// ZZConst8Inplace sets main[pos] := main[pos] OPCHAR val for every position in
// main[].
func ZZConst8Inplace(main []byte, val byte) {
	mainLen := len(main)
	if mainLen < BytesPerWord {
		for pos, mainByte := range main {
			main[pos] = mainByte OPCHAR val
		}
		return
	}
	argWord := 0x101010101010101 * uintptr(val)
	mainData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&main)).Data)
	mainWordsIter := mainData
	if mainLen > 2*BytesPerWord {
		nWordMinus2 := (mainLen - BytesPerWord - 1) >> Log2BytesPerWord
		for widx := 0; widx < nWordMinus2; widx++ {
			mainWord := *((*uintptr)(mainWordsIter))
			*((*uintptr)(mainWordsIter)) = mainWord OPCHAR argWord
			mainWordsIter = unsafe.Add(mainWordsIter, BytesPerWord)
		}
	}
	mainWord1 := *((*uintptr)(mainWordsIter))
	finalOffset := uintptr(mainLen - BytesPerWord)
	mainFinalWordPtr := unsafe.Add(mainData, finalOffset)
	mainWord2 := *((*uintptr)(mainFinalWordPtr))
	*((*uintptr)(mainWordsIter)) = mainWord1 OPCHAR argWord
	*((*uintptr)(mainFinalWordPtr)) = mainWord2 OPCHAR argWord
}

// ZZConst8Unsafe sets dst[pos] := src[pos] OPCHAR val for every position in dst.
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
func ZZConst8Unsafe(dst, src []byte, val byte) {
	srcHeader := (*reflect.SliceHeader)(unsafe.Pointer(&src))
	dstHeader := (*reflect.SliceHeader)(unsafe.Pointer(&dst))
	nWord := DivUpPow2(len(dst), BytesPerWord, Log2BytesPerWord)
	argWord := 0x101010101010101 * uintptr(val)

	srcIter := unsafe.Pointer(srcHeader.Data)
	dstIter := unsafe.Pointer(dstHeader.Data)
	for widx := 0; widx < nWord; widx++ {
		srcWord := *((*uintptr)(srcIter))
		*((*uintptr)(dstIter)) = srcWord OPCHAR argWord
		srcIter = unsafe.Add(srcIter, BytesPerWord)
		dstIter = unsafe.Add(dstIter, BytesPerWord)
	}
}

// ZZConst8 sets dst[pos] := src[pos] OPCHAR val for every position in dst.  It
// panics if slice lengths don't match.
func ZZConst8(dst, src []byte, val byte) {
	dstLen := len(dst)
	if len(src) != dstLen {
		panic("ZZConst8() requires len(src) == len(dst).")
	}
	if dstLen < BytesPerWord {
		for pos, srcByte := range src {
			dst[pos] = srcByte OPCHAR val
		}
		return
	}
	srcData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&src)).Data)
	dstData := unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&dst)).Data)
	nWordMinus1 := (dstLen - 1) >> Log2BytesPerWord
	argWord := 0x101010101010101 * uintptr(val)

	srcIter := unsafe.Pointer(srcData)
	dstIter := unsafe.Pointer(dstData)
	for widx := 0; widx < nWordMinus1; widx++ {
		srcWord := *((*uintptr)(srcIter))
		*((*uintptr)(dstIter)) = srcWord OPCHAR argWord
		srcIter = unsafe.Add(srcIter, BytesPerWord)
		dstIter = unsafe.Add(dstIter, BytesPerWord)
	}
	finalOffset := uintptr(dstLen - BytesPerWord)
	srcIter = unsafe.Add(srcData, finalOffset)
	dstIter = unsafe.Add(dstData, finalOffset)
	srcWord := *((*uintptr)(srcIter))
	*((*uintptr)(dstIter)) = srcWord OPCHAR argWord
}

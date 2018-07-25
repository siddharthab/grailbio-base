// Code generated by "../generate.py --output=string_freepool_race.go --prefix=strings -DELEM=[]string --package=tests ../randomized_freepool_race.go.tpl". DO NOT EDIT.

//go:build race
// +build race

package tests

import "sync/atomic"

type StringsFreePool struct {
	new func() []string
	len int64
}

func NewStringsFreePool(new func() []string, maxSize int) *StringsFreePool {
	return &StringsFreePool{new: new}
}

func (p *StringsFreePool) Put(x []string) {
	atomic.AddInt64(&p.len, -1)
}

func (p *StringsFreePool) Get() []string {
	atomic.AddInt64(&p.len, 1)
	return p.new()
}

func (p *StringsFreePool) ApproxLen() int { return int(atomic.LoadInt64(&p.len)) }

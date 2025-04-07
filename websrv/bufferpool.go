package websrv

import (
	"bytes"

	"github.com/oxtoacart/bpool"
)

var bufferpool *bpool.BufferPool

func init() {
	bufferpool = bpool.NewBufferPool(64)
}

func Buffer() *bytes.Buffer {
	return bufferpool.Get()
}

func ReleaseBuffer(b *bytes.Buffer) {
	bufferpool.Put(b)
}

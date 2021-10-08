// ioctx adds context.Context to io APIs.
//
// TODO: Specify policy for future additions to this package. It may be best to only add analogues
// of the stdlib "io" so ioctx.* are easy for readers to understand. New functions and types (other
// than conversions to and from stdlib types) should be added elsewhere.
package ioctx

import "context"

// Reader is io.Reader with context added.
type Reader interface {
	Read(context.Context, []byte) (n int, err error)
}

// Closer is io.Closer with context added.
type Closer interface {
	Close(context.Context) error
}

// ReadCloser is io.ReadCloser with context added.

type ReadCloser interface {
	Reader
	Closer
}

// ReaderAt is io.ReaderAt with context added.

type ReaderAt interface {
	ReadAt(_ context.Context, dst []byte, off int64) (n int, err error)
}
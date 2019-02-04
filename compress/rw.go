// Package compress provides convenience functions for creating compressors and
// uncompressors based on filenames.
package compress

import (
	"compress/bzip2"
	"fmt"
	"io"
	"io/ioutil"

	"github.com/grailbio/base/file"
	"github.com/grailbio/base/fileio"
	"github.com/klauspost/compress/gzip"
	"github.com/yasushi-saito/zlibng"
)

// NewReaderPath creates a reader that uncompresses data read from the given
// reader.  The compression format is determined by the pathname extensions. The
// following extensions are recognized:
//
//  .gz => gzip format
//  .bz2 => bz2 format
//
// For other extensions, this function returns nil.
//
// If the caller receives a non-nil reader from this function, it must close the
// reader after use. For some file formats, Close() is the only place that
// reports file corruption.
func NewReaderPath(r io.Reader, path string) io.ReadCloser {
	switch fileio.DetermineType(path) {
	case fileio.Gzip:
		gz, err := zlibng.NewReader(r)
		if err != nil {
			return file.NewError(err)
		}
		return gz
	case fileio.Bzip2:
		return ioutil.NopCloser(bzip2.NewReader(r))
	}
	return nil
}

// NewWriterPath creates a WriteCloser that compresses data.  The compression
// format is determined by the pathname extensions. The following extension is
// recognized:
//
//  .gz => gzip format
//
// For other extensions, this function returns nil. If this function returns a
// non-nil writecloser, the caller must call Close() once after writing all the
// data.
func NewWriterPath(w io.Writer, path string) io.WriteCloser {
	switch fileio.DetermineType(path) {
	case fileio.Gzip:
		return gzip.NewWriter(w)
	case fileio.Bzip2:
		return file.NewError(fmt.Errorf("%s: bzip2 writer not supported", path))
	}
	return nil
}
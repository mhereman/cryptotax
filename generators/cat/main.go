//go:build ignore
// +build ignore

package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

var indir string
var inpattern string
var outfile string

func main() {
	flag.StringVar(&indir, "in", "../websrv/assets/src/static/js", "Source directory")
	flag.StringVar(&inpattern, "pattern", "*.js", "Source file pattern")
	flag.StringVar(&outfile, "out", "../websrv/assets/static/js/app.js", "Output file")
	flag.Parse()

	path, _ := strings.CutSuffix(indir, "/")
	path, err := filepath.Abs(fmt.Sprintf("%s", path))
	if err != nil {
		panic(err)
	}

	matches, err := filepath.Glob(fmt.Sprintf("%s/%s", indir, inpattern))
	if err != nil {
		panic(err)
	}

	outFile, err := os.Create(outfile)
	if err != nil {
		panic(err)
	}
	defer outFile.Close()

	for _, match := range matches {
		func() {
			inFile, err := os.Open(match)
			if err != nil {
				panic(err)
			}
			defer inFile.Close()

			buf := make([]byte, 1024)
			for {
				n, err := inFile.Read(buf)
				if err != nil && err != io.EOF {
					panic(err)
				}
				if n == 0 {
					outFile.Write([]byte("\n"))
					break
				}

				if _, err = outFile.Write(buf[:n]); err != nil {
					panic(err)
				}
			}
		}()
	}
}

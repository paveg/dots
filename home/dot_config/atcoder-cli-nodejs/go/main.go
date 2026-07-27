package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

var (
	sc = bufio.NewScanner(os.Stdin)
	wr = bufio.NewWriter(os.Stdout)
)

func init() {
	sc.Buffer(make([]byte, 1024*1024), 1024*1024*1024)
	sc.Split(bufio.ScanWords)
}

func nextStr() string { sc.Scan(); return sc.Text() }
func nextInt() int    { n, _ := strconv.Atoi(nextStr()); return n }

func main() {
	defer func() {
		_ = wr.Flush()
	}()

	n := nextInt()
	_, _ = fmt.Fprintln(wr, n)
}

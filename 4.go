package main

import (
	"crypto/md5"
	"fmt"
	"os"
	"path"
	"strings"
	"strconv"
)

func main() {
	if (len(os.Args) != 2) {
		fmt.Printf("Usage: %s <seed>\n", path.Base(os.Args[0]))
		os.Exit(1)
	}

	five_zeros := "00000"
	fmt.Printf("%v\t", five_zeros)
	fmt.Println(prefixHash(os.Args[1], five_zeros))

	six_zeros := "000000"
	fmt.Printf("%v\t", six_zeros)
	fmt.Println(prefixHash(os.Args[1], six_zeros))
}

func prefixHash(seed string, prefix string) (string, uint64) {
	i := uint64(0)
	for {
		b := []byte(seed)
		b = strconv.AppendUint(b, i, 10)

		h := fmt.Sprintf("%x", md5.Sum(b))
		if strings.HasPrefix(h, prefix) {
			return h, i
		}

		i += 1
	}
}

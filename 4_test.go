package main

import (
	"testing"
)

type Example struct {
	seed   string
	hash   string
	answer uint64
}

func TestExampleSeeds(t *testing.T) {
	examples := []Example{
		{"abcdef", "000001dbbfa3a5c83a2d506429c7b00e", 609043},
		{"pqrstuv", "000006136ef2ff3b291c85725f17325c", 1048970},
	}

	for _, expected := range examples {
		if h, i := prefixHash(expected.seed, "00000"); h != expected.hash {
			t.Errorf("Expected hash of %v", expected.hash)
		} else if i != expected.answer {
			t.Errorf("Expected answer of %v", expected.answer)
		}
	}
}

package main

import (
	"testing"
)

func TestExampleSeeds(t *testing.T) {
	if h, i := prefixHash("abcdef", "00000"); h != "000001dbbfa3a5c83a2d506429c7b00e" {
		t.Errorf("Expected hash of 000001dbbfa... ")
	} else if i != 609043 {
		t.Errorf("Expected answer of 609043")
	}

	if h, i := prefixHash("pqrstuv", "00000"); h != "000006136ef2ff3b291c85725f17325c" {
		t.Errorf("Expected hash of 000006136ef... ")
	} else if i != 1048970 {
		t.Errorf("Expected answer of 1048970")
	}
}

#!/usr/bin/bash

set -e

filter () {
	cat \
		| egrep    '([aeiou].*){3,}' \
		| egrep    '([a-z])\1' \
		| egrep -v '(ab|cd|pq|xy)' \
		| wc -l
}

die () {
	echo "$0: $1"
	exit 1
}

pass () {
	[ `echo "$1" | filter` -ne 0 ] || die "$1 NO PASS"
}

fail () {
	[ `echo "$1" | filter` -eq 0 ] || die "$1 NO FAIL"
}

pass "ugknbfddgicrmopn"
pass "aaa"
fail "jchzalrnumimnmhp"
fail "haegwjzuvuyypxyu"
fail "dvszwmarrgswjxmb"

filter

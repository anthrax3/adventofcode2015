#!/usr/bin/bash

set -e

filter () {
	cat \
		| egrep '([a-z]{2}).*\1' \
		| egrep '([a-z]).\1' \
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

pass "qjhvhtzxzqqjkmpb"
pass "xxyxx"
fail "uurcxstgmygtbstg"
fail "ieodomkazucvgmuy"

filter

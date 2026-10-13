#!/bin/sh
# Plain-sh test for bootstrap.sh's hatdots_asset_pair OS/arch -> release
# asset-name mapping. No bats dependency: assert and count failures by
# hand, exit non-zero if any assertion failed.
#
# Run from anywhere:
#   sh installer/scripts/test/test_asset_pair.sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd)

# Sourcing bootstrap.sh must not run its main() — bootstrap.sh's own
# guard checks $0, which here is this test script's path, not
# "bootstrap.sh"/"sh"/"bash"/"dash", so main() is skipped.
. "$repo_root/bootstrap.sh"

failures=0

assert_pair() {
	uname_s="$1"
	uname_m="$2"
	want="$3"

	got=$(hatdots_asset_pair "$uname_s" "$uname_m") || got="<error>"
	if [ "$got" != "$want" ]; then
		printf 'FAIL: hatdots_asset_pair(%s, %s) = %s, want %s\n' "$uname_s" "$uname_m" "$got" "$want" >&2
		failures=$((failures + 1))
	fi
}

assert_unsupported() {
	uname_s="$1"
	uname_m="$2"

	if got=$(hatdots_asset_pair "$uname_s" "$uname_m" 2>/dev/null); then
		printf 'FAIL: hatdots_asset_pair(%s, %s) = %s, want an error (unsupported)\n' "$uname_s" "$uname_m" "$got" >&2
		failures=$((failures + 1))
	fi
}

assert_pair Linux x86_64 linux_amd64
assert_pair Linux aarch64 linux_arm64
assert_pair Linux amd64 linux_amd64
assert_pair Linux arm64 linux_arm64
assert_pair Darwin x86_64 darwin_amd64
assert_pair Darwin arm64 darwin_arm64

assert_unsupported Windows x86_64
assert_unsupported Linux riscv64
assert_unsupported SunOS x86_64

if [ "$failures" -ne 0 ]; then
	printf '%d assertion(s) failed\n' "$failures" >&2
	exit 1
fi

echo "test_asset_pair: all assertions passed"

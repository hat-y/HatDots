#!/bin/sh
# HatDots bootstrap: clone/update the repo, download the latest `hatdots`
# installer release for this OS/arch (verifying its sha256 against the
# release's checksums.txt), and run it. Falls back to `go run` when no
# release exists yet and Go is available locally.
#
# Usage: curl -fsSL <raw-url-to-this-file> | sh -s -- [hatdots args...]
#    or: ./bootstrap.sh [hatdots args...]
#
# Env:
#   HATDOTS_DIR   where to clone/find the repo (default: $HOME/projects/HatDots)
set -eu

HATDOTS_REPO_URL="https://github.com/hat-y/HatDots.git"
HATDOTS_RELEASES_API="https://api.github.com/repos/hat-y/HatDots/releases/latest"

log() {
	printf '%s\n' "bootstrap: $*" >&2
}

die() {
	log "$*"
	exit 1
}

# hatdots_asset_pair maps `uname -s`/`uname -m` output to the
# "<goos>_<goarch>" pair used in release asset names (see
# .goreleaser.yaml's archives.name_template). Prints the pair on stdout
# and returns 0 on a supported combination; returns 1 (printing nothing)
# otherwise. Kept as its own function so installer/scripts/test can
# source this file and exercise it directly without running main.
hatdots_asset_pair() {
	uname_s="$1"
	uname_m="$2"

	goos=""
	case "$uname_s" in
	Linux) goos="linux" ;;
	Darwin) goos="darwin" ;;
	*) return 1 ;;
	esac

	goarch=""
	case "$uname_m" in
	x86_64 | amd64) goarch="amd64" ;;
	aarch64 | arm64) goarch="arm64" ;;
	*) return 1 ;;
	esac

	printf '%s_%s\n' "$goos" "$goarch"
}

# is_hatdots_clone reports (via exit status) whether dir looks like a
# real HatDots checkout: a modules.toml declaring the installer's own
# schema marker, the same check the Go installer's findRepoRoot uses.
is_hatdots_clone() {
	dir="$1"
	[ -f "$dir/modules.toml" ] || return 1
	grep -q 'schema[[:space:]]*=[[:space:]]*"hatdots/v1"' "$dir/modules.toml" 2>/dev/null
}

ensure_repo() {
	dir="$1"
	if [ -e "$dir" ]; then
		if [ ! -d "$dir" ]; then
			die "$dir exists and is not a directory; refusing to touch it."
		fi
		if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
			log "cloning HatDots into empty directory $dir"
			git clone --depth=1 "$HATDOTS_REPO_URL" "$dir"
			return 0
		fi
		if is_hatdots_clone "$dir"; then
			log "updating existing HatDots clone at $dir"
			git -C "$dir" pull --ff-only || log "update failed or not possible (local changes?); continuing with the existing checkout"
			return 0
		fi
		die "$dir exists, is not empty, and does not look like a HatDots clone (no modules.toml with schema = \"hatdots/v1\"); refusing to touch it. Set HATDOTS_DIR to a different path."
	fi
	log "cloning HatDots into $dir"
	git clone --depth=1 "$HATDOTS_REPO_URL" "$dir"
}

sha256_of() {
	file="$1"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$file" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$file" | awk '{print $1}'
	else
		die "neither sha256sum nor shasum is available to verify the download"
	fi
}

# release_asset_url extracts the browser_download_url for the first
# asset in the release JSON whose name matches pattern (a plain
# substring, not a regex).
release_asset_url() {
	json_file="$1"
	pattern="$2"
	grep -o '"browser_download_url": *"[^"]*"' "$json_file" |
		sed -E 's/.*"(https:[^"]*)"/\1/' |
		grep -F "$pattern" |
		head -n1
}

download_and_run_release() {
	dir="$1"
	shift

	uname_s=$(uname -s)
	uname_m=$(uname -m)
	pair=$(hatdots_asset_pair "$uname_s" "$uname_m") || {
		log "unsupported OS/arch for a prebuilt release: $uname_s/$uname_m"
		return 1
	}

	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT

	release_json="$tmp/release.json"
	if ! curl -fsSL "$HATDOTS_RELEASES_API" -o "$release_json" 2>/dev/null; then
		log "could not reach the GitHub releases API (no network, or no release published yet)"
		return 1
	fi

	# hatdots_asset_pair only ever returns a linux_* or darwin_* pair on
	# this POSIX-sh script (bootstrap.ps1 handles Windows separately), and
	# .goreleaser.yaml archives both as tar.gz — unlike the windows_* zip
	# archives, which this script never has to pick an extension for.
	ext="tar.gz"

	asset_url=$(release_asset_url "$release_json" "_${pair}.${ext}")
	if [ -z "$asset_url" ]; then
		log "no release asset found for ${pair} (ext=${ext})"
		return 1
	fi
	checksums_url=$(release_asset_url "$release_json" "checksums.txt")
	if [ -z "$checksums_url" ]; then
		log "no checksums.txt found in the latest release"
		return 1
	fi

	asset_file="$tmp/$(basename "$asset_url")"
	checksums_file="$tmp/checksums.txt"
	log "downloading $(basename "$asset_url")"
	curl -fsSL "$asset_url" -o "$asset_file"
	curl -fsSL "$checksums_url" -o "$checksums_file"

	expected=$(grep -F "$(basename "$asset_file")" "$checksums_file" | awk '{print $1}' | head -n1)
	if [ -z "$expected" ]; then
		die "no checksum entry found for $(basename "$asset_file") in checksums.txt; aborting"
	fi
	actual=$(sha256_of "$asset_file")
	if [ "$expected" != "$actual" ]; then
		die "sha256 mismatch for $(basename "$asset_file"): expected $expected, got $actual; aborting"
	fi
	log "sha256 verified"

	extract_dir="$tmp/extracted"
	mkdir -p "$extract_dir"
	tar -xzf "$asset_file" -C "$extract_dir"

	bin="$extract_dir/hatdots"
	[ -x "$bin" ] || die "extracted archive did not contain an executable hatdots binary"

	"$bin" --repo "$dir" "$@"
}

run_from_source() {
	dir="$1"
	shift
	command -v go >/dev/null 2>&1 || {
		log "no published release for this platform yet, and 'go' is not available to build from source."
		log "install Go (https://go.dev/dl/) or wait for a tagged release, then re-run this script."
		return 1
	}
	log "no published release available; falling back to 'go run ./installer/cmd/hatdots'"
	(cd "$dir" && go run ./installer/cmd/hatdots --repo "$dir" "$@")
}

main() {
	dir="${HATDOTS_DIR:-$HOME/projects/HatDots}"
	ensure_repo "$dir"

	if download_and_run_release "$dir" "$@"; then
		return 0
	fi
	run_from_source "$dir" "$@"
}

# Only run main when this script is executed directly (./bootstrap.sh or
# piped into `sh`), not when it is sourced by installer/scripts/test's
# shell tests to exercise hatdots_asset_pair in isolation.
case "${0##*/}" in
*bootstrap.sh | sh | dash | bash) main "$@" ;;
esac

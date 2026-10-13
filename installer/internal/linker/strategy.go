package linker

import (
	"fmt"
	"strings"
)

// dirLinkStrategy creates a link to a directory. On Unix-like systems a
// plain symlink always suffices; Windows needs a fallback because
// symlinks there require either admin rights or Developer Mode.
type dirLinkStrategy interface {
	link(src, dst string) error
}

// symlinkStrategy is the default (Linux/macOS): always symlink.
type symlinkStrategy struct {
	symlink func(src, dst string) error
}

func (s symlinkStrategy) link(src, dst string) error {
	return s.symlink(src, dst)
}

// windowsDirStrategy tries a symlink first and falls back to an NTFS
// junction (`cmd /c mklink /J`) when that fails — the one fallback the
// phase-4a spec calls for. Both operations are injected functions so this
// decision logic is exercised by a plain Linux test, without needing a
// real Windows machine or a build tag.
type windowsDirStrategy struct {
	symlink        func(src, dst string) error
	mklinkJunction func(src, dst string) error
}

func (w windowsDirStrategy) link(src, dst string) error {
	if err := w.symlink(src, dst); err == nil {
		return nil
	}
	if err := checkMklinkSafe(src, dst); err != nil {
		return err
	}
	return w.mklinkJunction(src, dst)
}

// windowsShellMetacharacters are the characters cmd.exe re-parses even
// inside what looks like a single, already-quoted argument (`&`, `|`,
// `%`, `^`). mklinkJunction runs `cmd /c mklink /J <dst> <src>`; a path
// containing one of these could make cmd.exe run something other than
// mklink. This installer only ever constructs these paths from the
// manifest and detected platform paths, but checking costs nothing and
// fails closed instead of trusting that nothing upstream ever lets one
// of these characters through.
const windowsShellMetacharacters = "&|%^"

// checkMklinkSafe rejects src/dst before they ever reach a real `cmd /c
// mklink` invocation.
func checkMklinkSafe(src, dst string) error {
	if strings.ContainsAny(src, windowsShellMetacharacters) {
		return fmt.Errorf("refusing to run mklink: src %q contains a cmd.exe shell metacharacter (one of %q)", src, windowsShellMetacharacters)
	}
	if strings.ContainsAny(dst, windowsShellMetacharacters) {
		return fmt.Errorf("refusing to run mklink: dst %q contains a cmd.exe shell metacharacter (one of %q)", dst, windowsShellMetacharacters)
	}
	return nil
}

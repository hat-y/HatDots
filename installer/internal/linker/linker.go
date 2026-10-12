// Package linker is the adapter that applies domain.Action link steps to
// the real filesystem (or reports them without touching it, in dry-run
// mode) and implements domain.FSState by inspecting what is already there.
package linker

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

// FSState implements domain.FSState against the real filesystem.
type FSState struct{}

// Inspect reports what currently sits at dst, resolving a relative symlink
// target against dst's own directory before comparing it with
// expandedSrc (both absolute at that point) so relative and absolute
// symlinks to the same place are recognized as identical.
func (FSState) Inspect(dst, expandedSrc string) (domain.DstState, error) {
	info, err := os.Lstat(dst)
	if os.IsNotExist(err) {
		return domain.DstMissing, nil
	}
	if err != nil {
		return 0, err
	}

	if info.Mode()&os.ModeSymlink == 0 {
		return domain.DstOther, nil
	}

	target, err := os.Readlink(dst)
	if err != nil {
		return 0, err
	}
	if !filepath.IsAbs(target) {
		target = filepath.Join(filepath.Dir(dst), target)
	}
	if filepath.Clean(target) == filepath.Clean(expandedSrc) {
		return domain.DstSymlinkToExpectedSrc, nil
	}
	return domain.DstSymlinkElsewhere, nil
}

// backupTimeFormat produces the "<dst>.hatdots-bak.<UTC timestamp>" suffix
// documented in the task spec: a compact, sortable, filename-safe UTC
// timestamp.
const backupTimeFormat = "20060102T150405Z"

// Linker applies domain.Action link steps. The zero value is usable (it
// defaults to time.Now and a platform-appropriate directory-link
// strategy); DryRun and Now are there for callers/tests that need control.
type Linker struct {
	DryRun bool
	// Now supplies the clock used to name backup files; defaults to
	// time.Now when nil.
	Now func() time.Time
	// dirStrategy picks how a directory source gets linked (plain
	// symlink on Unix, symlink-then-junction-fallback on Windows). Left
	// unset, it resolves to defaultDirStrategy() (set per-OS by the
	// linker_unix.go/linker_windows.go build-tagged files).
	dirStrategy dirLinkStrategy
}

func (l Linker) now() time.Time {
	if l.Now != nil {
		return l.Now()
	}
	return time.Now().UTC()
}

func (l Linker) strategy() dirLinkStrategy {
	if l.dirStrategy != nil {
		return l.dirStrategy
	}
	return defaultDirStrategy()
}

// Apply carries out one action's filesystem side effects. Only link-kind
// actions touch the filesystem here; package-install and post-install
// actions are handled by the pkg/post-install executors, not the linker.
func (l Linker) Apply(action domain.Action) error {
	switch action.Kind {
	case domain.ActionLinkSkipIdentical:
		return nil
	case domain.ActionLinkCreate, domain.ActionLinkReplace, domain.ActionBackupThenLink:
		return l.applyLink(action)
	default:
		return fmt.Errorf("linker: not a link action: %s", action.Kind)
	}
}

func (l Linker) applyLink(action domain.Action) error {
	if l.DryRun {
		return nil
	}

	if err := os.MkdirAll(filepath.Dir(action.Dst), 0o755); err != nil {
		return fmt.Errorf("create parent dir for %s: %w", action.Dst, err)
	}

	switch action.Kind {
	case domain.ActionLinkReplace:
		if err := os.Remove(action.Dst); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("remove existing symlink %s: %w", action.Dst, err)
		}
	case domain.ActionBackupThenLink:
		backup := action.Dst + ".hatdots-bak." + l.now().Format(backupTimeFormat)
		if err := os.Rename(action.Dst, backup); err != nil {
			return fmt.Errorf("back up %s to %s: %w", action.Dst, backup, err)
		}
	}

	isDir, err := isDirSrc(action.Src)
	if err != nil {
		return fmt.Errorf("stat src %s: %w", action.Src, err)
	}
	if isDir {
		return l.strategy().link(action.Src, action.Dst)
	}
	return os.Symlink(action.Src, action.Dst)
}

func isDirSrc(src string) (bool, error) {
	info, err := os.Stat(src)
	if err != nil {
		return false, err
	}
	return info.IsDir(), nil
}

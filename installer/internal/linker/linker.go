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

// BackupRestoreError reports that a link failed AFTER its destination's
// original content had already been moved aside to BackupPath. Restored
// says whether Apply managed to move it back automatically; when it
// didn't (RestoreErr != nil), the user must recover it by hand — Error()
// spells out the exact `mv` command for that.
type BackupRestoreError struct {
	Dst        string
	BackupPath string
	LinkErr    error
	Restored   bool
	RestoreErr error
}

func (e *BackupRestoreError) Error() string {
	if e.Restored {
		return fmt.Sprintf("link %s failed (%v); the original was restored automatically from %s", e.Dst, e.LinkErr, e.BackupPath)
	}
	return fmt.Sprintf(
		"link %s failed (%v); the original is still backed up at %s and could NOT be restored automatically (%v) — recover it yourself: mv %s %s",
		e.Dst, e.LinkErr, e.BackupPath, e.RestoreErr, e.BackupPath, e.Dst,
	)
}

func (e *BackupRestoreError) Unwrap() error { return e.LinkErr }

func (l Linker) applyLink(action domain.Action) error {
	if l.DryRun {
		return nil
	}

	if err := os.MkdirAll(filepath.Dir(action.Dst), 0o755); err != nil {
		return fmt.Errorf("create parent dir for %s: %w", action.Dst, err)
	}

	var backupPath string
	switch action.Kind {
	case domain.ActionLinkReplace:
		if err := os.Remove(action.Dst); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("remove existing symlink %s: %w", action.Dst, err)
		}
	case domain.ActionBackupThenLink:
		backup, err := freeBackupPath(action.Dst, l.now())
		if err != nil {
			return fmt.Errorf("find a free backup path for %s: %w", action.Dst, err)
		}
		if err := os.Rename(action.Dst, backup); err != nil {
			return fmt.Errorf("back up %s to %s: %w", action.Dst, backup, err)
		}
		backupPath = backup
	}

	linkErr := l.createLink(action.Src, action.Dst)
	if linkErr == nil {
		return nil
	}
	if backupPath == "" {
		// Nothing was moved aside for this action kind; nothing to
		// restore, just surface the failure.
		return linkErr
	}

	// The original sat at action.Dst until we moved it to backupPath
	// above, and the link we meant to put in its place failed. Try to
	// put it straight back rather than leaving the user with neither
	// the original file nor a working link.
	restoreErr := os.Rename(backupPath, action.Dst)
	return &BackupRestoreError{
		Dst:        action.Dst,
		BackupPath: backupPath,
		LinkErr:    linkErr,
		Restored:   restoreErr == nil,
		RestoreErr: restoreErr,
	}
}

func (l Linker) createLink(src, dst string) error {
	isDir, err := isDirSrc(src)
	if err != nil {
		return fmt.Errorf("stat src %s: %w", src, err)
	}
	if isDir {
		return l.strategy().link(src, dst)
	}
	return os.Symlink(src, dst)
}

// freeBackupPath returns a backup path for dst at clock time now that
// does not already exist on disk: "<dst>.hatdots-bak.<timestamp>", or
// "<dst>.hatdots-bak.<timestamp>-1", "-2", ... when that name is already
// taken (e.g. two backups of the same dst within the same clock second).
// It never returns a path that os.Lstat finds, so Apply's os.Rename onto
// it can never silently clobber an existing backup.
func freeBackupPath(dst string, now time.Time) (string, error) {
	base := dst + ".hatdots-bak." + now.Format(backupTimeFormat)
	candidate := base
	for i := 0; ; i++ {
		if i > 0 {
			candidate = fmt.Sprintf("%s-%d", base, i)
		}
		_, err := os.Lstat(candidate)
		if os.IsNotExist(err) {
			return candidate, nil
		}
		if err != nil {
			return "", err
		}
		// candidate exists (err == nil): try the next suffix.
	}
}

func isDirSrc(src string) (bool, error) {
	info, err := os.Stat(src)
	if err != nil {
		return false, err
	}
	return info.IsDir(), nil
}

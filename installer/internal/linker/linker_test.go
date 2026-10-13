package linker

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func TestFSState_Inspect(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src-file")
	if err := os.WriteFile(src, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	other := filepath.Join(dir, "other-file")
	if err := os.WriteFile(other, []byte("y"), 0o644); err != nil {
		t.Fatal(err)
	}

	fs := FSState{}

	t.Run("missing", func(t *testing.T) {
		dst := filepath.Join(dir, "missing")
		got, err := fs.Inspect(dst, src)
		if err != nil || got != domain.DstMissing {
			t.Fatalf("got %v, %v, want DstMissing, nil", got, err)
		}
	})

	t.Run("symlink to expected src", func(t *testing.T) {
		dst := filepath.Join(dir, "linked-same")
		if err := os.Symlink(src, dst); err != nil {
			t.Fatal(err)
		}
		got, err := fs.Inspect(dst, src)
		if err != nil || got != domain.DstSymlinkToExpectedSrc {
			t.Fatalf("got %v, %v, want DstSymlinkToExpectedSrc, nil", got, err)
		}
	})

	t.Run("symlink elsewhere", func(t *testing.T) {
		dst := filepath.Join(dir, "linked-other")
		if err := os.Symlink(other, dst); err != nil {
			t.Fatal(err)
		}
		got, err := fs.Inspect(dst, src)
		if err != nil || got != domain.DstSymlinkElsewhere {
			t.Fatalf("got %v, %v, want DstSymlinkElsewhere, nil", got, err)
		}
	})

	t.Run("real file", func(t *testing.T) {
		dst := filepath.Join(dir, "real-file")
		if err := os.WriteFile(dst, []byte("z"), 0o644); err != nil {
			t.Fatal(err)
		}
		got, err := fs.Inspect(dst, src)
		if err != nil || got != domain.DstOther {
			t.Fatalf("got %v, %v, want DstOther, nil", got, err)
		}
	})

	t.Run("relative symlink target resolved against dst dir", func(t *testing.T) {
		dst := filepath.Join(dir, "linked-relative")
		if err := os.Symlink("src-file", dst); err != nil {
			t.Fatal(err)
		}
		got, err := fs.Inspect(dst, src)
		if err != nil || got != domain.DstSymlinkToExpectedSrc {
			t.Fatalf("got %v, %v, want DstSymlinkToExpectedSrc for a relative symlink resolving to src", got, err)
		}
	})
}

func fixedClock(ts string) func() time.Time {
	t, err := time.Parse(time.RFC3339, ts)
	if err != nil {
		panic(err)
	}
	return func() time.Time { return t }
}

func TestLinker_Apply_LinkCreate(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	if err := os.WriteFile(src, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(dir, "nested", "dst")

	l := Linker{Now: fixedClock("2026-10-12T00:00:00Z")}
	action := domain.Action{Kind: domain.ActionLinkCreate, Src: src, Dst: dst}
	if err := l.Apply(action); err != nil {
		t.Fatalf("Apply error: %v", err)
	}

	target, err := os.Readlink(dst)
	if err != nil {
		t.Fatalf("Readlink error: %v", err)
	}
	if target != src {
		t.Errorf("link target = %q, want %q", target, src)
	}
}

func TestLinker_Apply_LinkReplace(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	other := filepath.Join(dir, "other")
	for _, p := range []string{src, other} {
		if err := os.WriteFile(p, []byte("x"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	dst := filepath.Join(dir, "dst")
	if err := os.Symlink(other, dst); err != nil {
		t.Fatal(err)
	}

	l := Linker{Now: fixedClock("2026-10-12T00:00:00Z")}
	action := domain.Action{Kind: domain.ActionLinkReplace, Src: src, Dst: dst}
	if err := l.Apply(action); err != nil {
		t.Fatalf("Apply error: %v", err)
	}

	target, err := os.Readlink(dst)
	if err != nil {
		t.Fatalf("Readlink error: %v", err)
	}
	if target != src {
		t.Errorf("link target = %q, want %q", target, src)
	}
}

func TestLinker_Apply_LinkSkipIdentical_NoOp(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	if err := os.WriteFile(src, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(dir, "dst")
	if err := os.Symlink(src, dst); err != nil {
		t.Fatal(err)
	}
	before, _ := os.Readlink(dst)

	l := Linker{Now: fixedClock("2026-10-12T00:00:00Z")}
	action := domain.Action{Kind: domain.ActionLinkSkipIdentical, Src: src, Dst: dst}
	if err := l.Apply(action); err != nil {
		t.Fatalf("Apply error: %v", err)
	}

	after, _ := os.Readlink(dst)
	if before != after {
		t.Errorf("skip-identical mutated the symlink: before=%q after=%q", before, after)
	}
}

func TestLinker_Apply_BackupThenLink_PreservesOriginalContent(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	if err := os.WriteFile(src, []byte("new content"), 0o644); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(dir, "dst")
	if err := os.WriteFile(dst, []byte("original content"), 0o644); err != nil {
		t.Fatal(err)
	}

	l := Linker{Now: fixedClock("2026-10-12T15:04:05Z")}
	action := domain.Action{Kind: domain.ActionBackupThenLink, Src: src, Dst: dst}
	if err := l.Apply(action); err != nil {
		t.Fatalf("Apply error: %v", err)
	}

	target, err := os.Readlink(dst)
	if err != nil {
		t.Fatalf("dst is not a symlink after backup-then-link: %v", err)
	}
	if target != src {
		t.Errorf("link target = %q, want %q", target, src)
	}

	wantBackup := dst + ".hatdots-bak.20261012T150405Z"
	data, err := os.ReadFile(wantBackup)
	if err != nil {
		t.Fatalf("backup file %q not found: %v", wantBackup, err)
	}
	if string(data) != "original content" {
		t.Errorf("backup content = %q, want %q", data, "original content")
	}
}

func TestLinker_Apply_BackupThenLink_CollisionProofNaming(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	if err := os.WriteFile(src, []byte("new content"), 0o644); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(dir, "dst")

	// Same frozen clock for both applies, so a naive implementation would
	// compute the exact same backup path twice.
	l := Linker{Now: fixedClock("2026-10-12T15:04:05Z")}

	if err := os.WriteFile(dst, []byte("first original"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := l.Apply(domain.Action{Kind: domain.ActionBackupThenLink, Src: src, Dst: dst}); err != nil {
		t.Fatalf("first Apply error: %v", err)
	}

	// dst is now a symlink; put a second, different real file back in its
	// place to simulate a second backup-worthy destination occurring
	// within the same clock second.
	if err := os.Remove(dst); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(dst, []byte("second original"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := l.Apply(domain.Action{Kind: domain.ActionBackupThenLink, Src: src, Dst: dst}); err != nil {
		t.Fatalf("second Apply error: %v", err)
	}

	matches, err := filepath.Glob(dst + ".hatdots-bak.*")
	if err != nil {
		t.Fatal(err)
	}
	if len(matches) != 2 {
		t.Fatalf("got %d backup files, want 2 distinct ones: %v", len(matches), matches)
	}

	contents := map[string]bool{}
	for _, m := range matches {
		data, err := os.ReadFile(m)
		if err != nil {
			t.Fatalf("reading backup %q: %v", m, err)
		}
		contents[string(data)] = true
	}
	if !contents["first original"] || !contents["second original"] {
		t.Fatalf("backups did not preserve both distinct originals: %v", contents)
	}
}

func TestLinker_Apply_DryRunNeverTouchesFilesystem(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	if err := os.WriteFile(src, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(dir, "nested", "dst")

	l := Linker{DryRun: true, Now: fixedClock("2026-10-12T00:00:00Z")}
	action := domain.Action{Kind: domain.ActionLinkCreate, Src: src, Dst: dst}
	if err := l.Apply(action); err != nil {
		t.Fatalf("Apply error: %v", err)
	}

	if _, err := os.Lstat(dst); !os.IsNotExist(err) {
		t.Errorf("dry-run created something at %q (err=%v)", dst, err)
	}
}

func TestLinker_Apply_DirLinkUsesDirStrategy(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "srcdir")
	if err := os.MkdirAll(src, 0o755); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(dir, "dst")

	called := false
	l := Linker{
		Now: fixedClock("2026-10-12T00:00:00Z"),
		dirStrategy: symlinkStrategy{symlink: func(s, d string) error {
			called = true
			return os.Symlink(s, d)
		}},
	}
	action := domain.Action{Kind: domain.ActionLinkCreate, Src: src, Dst: dst}
	if err := l.Apply(action); err != nil {
		t.Fatalf("Apply error: %v", err)
	}
	if !called {
		t.Error("dirStrategy.link was never invoked for a directory source")
	}
}

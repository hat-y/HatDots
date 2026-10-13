package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

const validMarkerTOML = "schema = \"hatdots/v1\"\n"

func TestFindRepoRoot_WalksUpToModulesToml(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "modules.toml"), []byte(validMarkerTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	nested := filepath.Join(root, "a", "b", "c")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatal(err)
	}

	got, src, err := findRepoRoot(nested, func() (string, error) { return "", nil })
	if err != nil {
		t.Fatalf("findRepoRoot error: %v", err)
	}
	if got != root {
		t.Errorf("got %q, want %q", got, root)
	}
	if src != repoSourceWalkUp {
		t.Errorf("source = %v, want repoSourceWalkUp", src)
	}
}

func TestFindRepoRoot_FallsBackToExecutableDir(t *testing.T) {
	start := t.TempDir() // no modules.toml anywhere above this
	exeDir := t.TempDir()
	if err := os.WriteFile(filepath.Join(exeDir, "modules.toml"), []byte(validMarkerTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	exePath := filepath.Join(exeDir, "hatdots")

	got, src, err := findRepoRoot(start, func() (string, error) { return exePath, nil })
	if err != nil {
		t.Fatalf("findRepoRoot error: %v", err)
	}
	if got != exeDir {
		t.Errorf("got %q, want %q", got, exeDir)
	}
	if src != repoSourceExecutableFallback {
		t.Errorf("source = %v, want repoSourceExecutableFallback", src)
	}
}

func TestFindRepoRoot_IgnoresModulesTomlWithoutSchemaMarker(t *testing.T) {
	// A modules.toml that exists but has no (or the wrong) schema marker
	// must not be accepted as a repo root — it might just be some
	// unrelated file that happens to share the name.
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "modules.toml"), []byte("not a hatdots manifest\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	nested := filepath.Join(root, "a", "b")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatal(err)
	}

	if _, _, err := findRepoRoot(nested, func() (string, error) { return "", nil }); err == nil {
		t.Fatal("expected an error: no candidate here declares the schema marker")
	}
}

func TestParseOnly_SplitsCommaList(t *testing.T) {
	got := parseOnly("nvim, tmux ,ghostty")
	want := []string{"nvim", "tmux", "ghostty"}
	if len(got) != len(want) {
		t.Fatalf("got %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("got[%d] = %q, want %q", i, got[i], want[i])
		}
	}
}

func TestResolveOSFlag_DefaultsToAutoDetected(t *testing.T) {
	got, err := resolveOSFlag("")
	if err != nil {
		t.Fatalf("resolveOSFlag error: %v", err)
	}
	if got == "" {
		t.Error("resolveOSFlag(\"\") returned empty OS, want an auto-detected value")
	}
}

func TestResolveOSFlag_RejectsUnknownValue(t *testing.T) {
	if _, err := resolveOSFlag("solaris"); err == nil {
		t.Error("expected an error for an unknown --os value")
	}
}

func TestResolveDesktopFlag(t *testing.T) {
	cases := []struct {
		in   string
		want domain.Desktop
	}{
		{"", domain.NoDesktop}, // sentinel meaning "auto-detect" is handled by the caller
		{"none", domain.NoDesktop},
		{"omarchy", domain.Omarchy},
	}
	for _, tc := range cases {
		got, err := resolveDesktopFlag(tc.in)
		if err != nil {
			t.Fatalf("resolveDesktopFlag(%q) error: %v", tc.in, err)
		}
		if got != tc.want {
			t.Errorf("resolveDesktopFlag(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}

func TestResolveDesktopFlag_RejectsUnknownValue(t *testing.T) {
	if _, err := resolveDesktopFlag("kde"); err == nil {
		t.Error("expected an error for an unknown --desktop value")
	}
}

func TestRun_ListSubcommandPrintsModules(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifestTOML := `
schema = "hatdots/v1"

[[modules]]
id = "nvim"
name = "Neovim"
description = "Editor"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`
	if err := os.WriteFile(filepath.Join(repo, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}

	var stdout, stderr bytes.Buffer
	code := run([]string{"list", "--repo", repo}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code != 0 {
		t.Fatalf("exit code = %d, stderr = %s", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), "nvim") {
		t.Errorf("stdout = %q, want it to mention the nvim module", stdout.String())
	}
	if !strings.Contains(stdout.String(), "required") {
		t.Errorf("stdout = %q, want it to flag nvim as required", stdout.String())
	}
}

func TestRun_DryRunAllYesNeverTouchesDisk(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifestTOML := `
schema = "hatdots/v1"

[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`
	if err := os.WriteFile(filepath.Join(repo, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	home := t.TempDir()
	t.Setenv("HOME", home)

	var stdout, stderr bytes.Buffer
	code := run([]string{"--repo", repo, "--dry-run", "--all", "--yes", "--os", "linux", "--desktop", "none"}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code != 0 {
		t.Fatalf("exit code = %d, stderr = %s", code, stderr.String())
	}
	if _, err := os.Lstat(filepath.Join(home, ".config", "nvim")); !os.IsNotExist(err) {
		t.Errorf("dry-run touched %q", filepath.Join(home, ".config", "nvim"))
	}
	if !strings.Contains(stdout.String(), "link-create") {
		t.Errorf("stdout = %q, want it to summarize the planned action", stdout.String())
	}
}

func TestRun_NonInteractiveWithoutYesStillApplies(t *testing.T) {
	// Without a TTY and without --yes, the installer must not block on a
	// prompt it can never receive an answer to; it proceeds (consistent
	// with "without a TTY or with --yes, run non-interactively").
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifestTOML := `
schema = "hatdots/v1"

[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`
	if err := os.WriteFile(filepath.Join(repo, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	home := t.TempDir()
	t.Setenv("HOME", home)

	var stdout, stderr bytes.Buffer
	code := run([]string{"--repo", repo, "--all", "--os", "linux", "--desktop", "none"}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code != 0 {
		t.Fatalf("exit code = %d, stderr = %s", code, stderr.String())
	}
	if _, err := os.Lstat(filepath.Join(home, ".config", "nvim")); err != nil {
		t.Errorf("non-interactive run did not create the link: %v", err)
	}
}

func TestPrintPlan_WarnsAboutFilesThatWillBeReplaced(t *testing.T) {
	plan := domain.Plan{Actions: []domain.Action{
		{Kind: domain.ActionLinkCreate, ModuleID: "nvim", Src: "/repo/common/nvim", Dst: "/home/u/.config/nvim"},
		{Kind: domain.ActionBackupThenLink, ModuleID: "starship", Src: "/repo/common/starship/starship.toml", Dst: "/home/u/.config/starship.toml"},
	}}
	var stdout bytes.Buffer
	printPlan(&stdout, plan)

	out := stdout.String()
	if !strings.Contains(out, "These files will be replaced (backup kept):") {
		t.Errorf("stdout = %q, want a backup-warning section", out)
	}
	if !strings.Contains(out, "/home/u/.config/starship.toml") {
		t.Errorf("stdout = %q, want it to list the file that will be backed up", out)
	}
}

func TestPrintPlan_NoWarningWhenNothingWillBeReplaced(t *testing.T) {
	plan := domain.Plan{Actions: []domain.Action{
		{Kind: domain.ActionLinkCreate, ModuleID: "nvim", Src: "/repo/common/nvim", Dst: "/home/u/.config/nvim"},
	}}
	var stdout bytes.Buffer
	printPlan(&stdout, plan)

	if strings.Contains(stdout.String(), "will be replaced") {
		t.Errorf("stdout = %q, want no backup-warning section when nothing is backed up", stdout.String())
	}
}

func TestRun_EmptyHOMEFailsCleanlyInsteadOfWritingToRoot(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifestTOML := `
schema = "hatdots/v1"

[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`
	if err := os.WriteFile(filepath.Join(repo, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", "")

	var stdout, stderr bytes.Buffer
	code := run([]string{"--repo", repo, "--dry-run", "--all", "--yes", "--os", "linux", "--desktop", "none"}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code == 0 {
		t.Fatalf("expected a non-zero exit code with an empty HOME, got 0; stdout=%s", stdout.String())
	}
	if stderr.Len() == 0 {
		t.Error("expected a clear error on stderr explaining why it refused, got none")
	}
	if strings.Contains(stdout.String(), "/.config/nvim") {
		t.Errorf("stdout = %q, must never compute a root-relative destination like /.config/nvim from an empty HOME", stdout.String())
	}
}

func TestRun_NoFlagsSelectsDefaultModulesNotEveryOptionalOne(t *testing.T) {
	repo := t.TempDir()
	for _, dir := range []string{"common/nvim", "common/tmux", "common/starship"} {
		if err := os.MkdirAll(filepath.Join(repo, dir), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	manifestTOML := `
schema = "hatdots/v1"

[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"

[[modules]]
id = "tmux"
default = true

  [[modules.links]]
  src = "common/tmux"
  dst = "~/.config/tmux"

[[modules]]
id = "starship"
default = false

  [[modules.links]]
  src = "common/starship"
  dst = "~/.config/starship"
`
	if err := os.WriteFile(filepath.Join(repo, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	home := t.TempDir()
	t.Setenv("HOME", home)

	var stdout, stderr bytes.Buffer
	code := run([]string{"--repo", repo, "--yes", "--os", "linux", "--desktop", "none"}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code != 0 {
		t.Fatalf("exit code = %d, stderr = %s", code, stderr.String())
	}
	if _, err := os.Lstat(filepath.Join(home, ".config", "nvim")); err != nil {
		t.Errorf("required module nvim was not linked: %v", err)
	}
	if _, err := os.Lstat(filepath.Join(home, ".config", "tmux")); err != nil {
		t.Errorf("default=true module tmux was not linked: %v", err)
	}
	if _, err := os.Lstat(filepath.Join(home, ".config", "starship")); !os.IsNotExist(err) {
		t.Errorf("default=false module starship was linked without being asked for (err=%v)", err)
	}
}

// withFakeExecutable points executableFunc at exePath for the duration of
// the test, so findRepoRoot's executable-dir fallback is exercised
// without a real installed binary.
func withFakeExecutable(t *testing.T, exePath string) {
	t.Helper()
	orig := executableFunc
	executableFunc = func() (string, error) { return exePath, nil }
	t.Cleanup(func() { executableFunc = orig })
}

func setupFallbackRepo(t *testing.T) (cwd, home string) {
	t.Helper()
	cwd = t.TempDir() // no modules.toml anywhere above this
	exeDir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(exeDir, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifestTOML := `
schema = "hatdots/v1"

[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`
	if err := os.WriteFile(filepath.Join(exeDir, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	withFakeExecutable(t, filepath.Join(exeDir, "hatdots"))
	home = t.TempDir()
	t.Setenv("HOME", home)
	return cwd, home
}

func TestRun_ExecutableFallback_RefusesUnderYes(t *testing.T) {
	cwd, _ := setupFallbackRepo(t)
	t.Chdir(cwd)

	var stdout, stderr bytes.Buffer
	code := run([]string{"--dry-run", "--all", "--yes", "--os", "linux", "--desktop", "none"}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code == 0 {
		t.Fatalf("expected a non-zero exit code refusing an auto-detected repo under --yes, got 0")
	}
	if !strings.Contains(stderr.String(), "--repo") {
		t.Errorf("stderr = %q, want it to tell the user to pass --repo explicitly", stderr.String())
	}
}

func TestRun_ExecutableFallback_RefusesWithoutTTY(t *testing.T) {
	cwd, _ := setupFallbackRepo(t)
	t.Chdir(cwd)

	var stdout, stderr bytes.Buffer
	code := run([]string{"--dry-run", "--all", "--os", "linux", "--desktop", "none"}, &bytes.Buffer{}, &stdout, &stderr, false)
	if code == 0 {
		t.Fatalf("expected a non-zero exit code without a TTY to confirm, got 0")
	}
}

func TestRun_ExecutableFallback_ProceedsOnConfirm(t *testing.T) {
	cwd, home := setupFallbackRepo(t)
	t.Chdir(cwd)

	stdin := strings.NewReader("y\n")
	var stdout, stderr bytes.Buffer
	code := run([]string{"--dry-run", "--all", "--os", "linux", "--desktop", "none"}, stdin, &stdout, &stderr, true)
	if code != 0 {
		t.Fatalf("exit code = %d, stderr = %s", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), "Use this repo?") {
		t.Errorf("stdout = %q, want a confirmation prompt", stdout.String())
	}
	if _, err := os.Lstat(filepath.Join(home, ".config", "nvim")); !os.IsNotExist(err) {
		t.Errorf("dry-run touched %q", filepath.Join(home, ".config", "nvim"))
	}
}

func TestRun_ExecutableFallback_AbortsOnDecline(t *testing.T) {
	cwd, _ := setupFallbackRepo(t)
	t.Chdir(cwd)

	stdin := strings.NewReader("n\n")
	var stdout, stderr bytes.Buffer
	code := run([]string{"--dry-run", "--all", "--os", "linux", "--desktop", "none"}, stdin, &stdout, &stderr, true)
	if code != 0 {
		t.Fatalf("exit code = %d, stderr = %s", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), "Aborted") {
		t.Errorf("stdout = %q, want an abort message", stdout.String())
	}
}

package app

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func writeRepo(t *testing.T, manifestTOML string) string {
	t.Helper()
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(repo, "modules.toml"), []byte(manifestTOML), 0o644); err != nil {
		t.Fatal(err)
	}
	return repo
}

const minimalManifest = `
[[modules]]
id = "nvim"
name = "Neovim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`

func TestLoad_AbsolutizesLinkSrc(t *testing.T) {
	repo := writeRepo(t, minimalManifest)

	a, err := Load(repo)
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	mod, ok := a.Manifest.ModuleByID("nvim")
	if !ok {
		t.Fatal("nvim module not found")
	}
	want := filepath.Join(repo, "common", "nvim")
	if mod.Links[0].Src != want {
		t.Errorf("Src = %q, want %q", mod.Links[0].Src, want)
	}
}

func TestPlan_BuildsActionsForSelection(t *testing.T) {
	repo := writeRepo(t, minimalManifest)
	a, err := Load(repo)
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	home := t.TempDir()
	platform := domain.Platform{OS: domain.Linux, Env: map[string]string{"HOME": home}}

	plan, err := a.Plan(platform, nil)
	if err != nil {
		t.Fatalf("Plan error: %v", err)
	}
	if len(plan.Actions) != 1 || plan.Actions[0].Kind != domain.ActionLinkCreate {
		t.Fatalf("got %+v, want one link-create action", plan.Actions)
	}
	wantDst := filepath.Join(home, ".config", "nvim")
	if plan.Actions[0].Dst != wantDst {
		t.Errorf("Dst = %q, want %q", plan.Actions[0].Dst, wantDst)
	}
}

func TestApply_CreatesLinkAndReportsProgress(t *testing.T) {
	repo := writeRepo(t, minimalManifest)
	a, err := Load(repo)
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	home := t.TempDir()
	platform := domain.Platform{OS: domain.Linux, Env: map[string]string{"HOME": home}}
	plan, err := a.Plan(platform, nil)
	if err != nil {
		t.Fatalf("Plan error: %v", err)
	}

	var events []Event
	if err := a.Apply(plan, false, func(e Event) { events = append(events, e) }); err != nil {
		t.Fatalf("Apply error: %v", err)
	}

	if len(events) != 1 || events[0].Err != nil {
		t.Fatalf("events = %+v, want one successful event", events)
	}

	dst := filepath.Join(home, ".config", "nvim")
	target, err := os.Readlink(dst)
	if err != nil {
		t.Fatalf("Readlink error: %v", err)
	}
	if target != filepath.Join(repo, "common", "nvim") {
		t.Errorf("target = %q", target)
	}
}

func TestApply_DryRunTouchesNothing(t *testing.T) {
	repo := writeRepo(t, minimalManifest)
	a, err := Load(repo)
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	home := t.TempDir()
	platform := domain.Platform{OS: domain.Linux, Env: map[string]string{"HOME": home}}
	plan, err := a.Plan(platform, nil)
	if err != nil {
		t.Fatalf("Plan error: %v", err)
	}

	if err := a.Apply(plan, true, nil); err != nil {
		t.Fatalf("Apply error: %v", err)
	}
	dst := filepath.Join(home, ".config", "nvim")
	if _, err := os.Lstat(dst); !os.IsNotExist(err) {
		t.Errorf("dry-run created %q", dst)
	}
}

func TestResolvePostInstall_AbsolutizesRepoRelativeScript(t *testing.T) {
	repo := t.TempDir()
	scriptDir := filepath.Join(repo, "os", "mac", "herdr")
	if err := os.MkdirAll(scriptDir, 0o755); err != nil {
		t.Fatal(err)
	}
	scriptPath := filepath.Join(scriptDir, "install.sh")
	if err := os.WriteFile(scriptPath, []byte("#!/bin/sh\n"), 0o755); err != nil {
		t.Fatal(err)
	}

	p := domain.PostInstall{Command: "os/mac/herdr/install.sh"}
	got := resolvePostInstall(p, repo)
	if got.Command != scriptPath {
		t.Errorf("Command = %q, want %q", got.Command, scriptPath)
	}
}

func TestResolvePostInstall_LeavesLiteralShellCommandAlone(t *testing.T) {
	repo := t.TempDir()
	p := domain.PostInstall{Command: "git clone --depth=1 https://example.invalid/x ~/.local/x"}
	got := resolvePostInstall(p, repo)
	if got.Command != p.Command {
		t.Errorf("Command = %q, want unchanged %q", got.Command, p.Command)
	}
}

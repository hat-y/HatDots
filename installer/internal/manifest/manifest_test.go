package manifest

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func TestParse_MinimalModule(t *testing.T) {
	data := []byte(`
[[modules]]
id = "nvim"
name = "Neovim"
description = "Neovim editor config"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`)
	m, err := Parse(data)
	if err != nil {
		t.Fatalf("Parse error: %v", err)
	}
	if len(m.Modules) != 1 {
		t.Fatalf("got %d modules, want 1", len(m.Modules))
	}
	mod := m.Modules[0]
	if mod.ID != "nvim" || !mod.Required {
		t.Errorf("mod = %+v, want id=nvim required=true", mod)
	}
	if len(mod.Links) != 1 || mod.Links[0].Src != "common/nvim" || mod.Links[0].Dst != "~/.config/nvim" {
		t.Errorf("links = %+v", mod.Links)
	}
}

func TestParse_NotDefaultDesktop(t *testing.T) {
	data := []byte(`
[[modules]]
id = "kde"
default = true
not_default_desktop = ["omarchy"]
`)
	m, err := Parse(data)
	if err != nil {
		t.Fatalf("Parse error: %v", err)
	}
	mod := m.Modules[0]
	if !mod.Default {
		t.Error("mod.Default = false, want true")
	}
	if !reflectDesktopEqual(mod.NotDefaultDesktop, domain.Omarchy) {
		t.Errorf("mod.NotDefaultDesktop = %v, want [omarchy]", mod.NotDefaultDesktop)
	}
}

func TestParse_LinkOSAndDesktopFilters(t *testing.T) {
	data := []byte(`
[[modules]]
id = "tmux"
os = ["linux", "mac"]

  [[modules.links]]
  src = "common/tmux/tmux.conf"
  dst = "~/.config/tmux/tmux.conf"
  dst_mac = "~/.tmux.conf"

  [[modules.links]]
  src = "os/omarchy/tmux/omarchy.tmux.conf"
  dst = "~/.config/hatdots/omarchy.tmux.conf"
  os = ["linux"]
  desktop = ["omarchy"]
`)
	m, err := Parse(data)
	if err != nil {
		t.Fatalf("Parse error: %v", err)
	}
	mod := m.Modules[0]
	if !reflectOSEqual(mod.OS, domain.Linux, domain.Mac) {
		t.Errorf("mod.OS = %v", mod.OS)
	}
	l0 := mod.Links[0]
	if l0.ResolveDst(domain.Linux) != "~/.config/tmux/tmux.conf" {
		t.Errorf("linux dst = %q", l0.ResolveDst(domain.Linux))
	}
	if l0.ResolveDst(domain.Mac) != "~/.tmux.conf" {
		t.Errorf("mac dst = %q", l0.ResolveDst(domain.Mac))
	}
	l1 := mod.Links[1]
	if !reflectOSEqual(l1.OS, domain.Linux) {
		t.Errorf("l1.OS = %v", l1.OS)
	}
	if !reflectDesktopEqual(l1.Desktop, domain.Omarchy) {
		t.Errorf("l1.Desktop = %v", l1.Desktop)
	}
}

func TestParse_PackagesPerManager(t *testing.T) {
	data := []byte(`
[[modules]]
id = "nvim"

[modules.packages]
pacman = ["neovim"]
brew = ["neovim"]
winget = ["Neovim.Neovim"]
`)
	m, err := Parse(data)
	if err != nil {
		t.Fatalf("Parse error: %v", err)
	}
	mod := m.Modules[0]
	if len(mod.Packages) != 3 {
		t.Fatalf("got %d package specs, want 3: %+v", len(mod.Packages), mod.Packages)
	}
	found := map[domain.PkgManager][]string{}
	for _, p := range mod.Packages {
		found[p.Manager] = p.Names
	}
	if !equalStrings(found[domain.Pacman], []string{"neovim"}) {
		t.Errorf("pacman = %v", found[domain.Pacman])
	}
	if !equalStrings(found[domain.Winget], []string{"Neovim.Neovim"}) {
		t.Errorf("winget = %v", found[domain.Winget])
	}
}

func TestParse_CasksAreBrewWithCaskFlag(t *testing.T) {
	data := []byte(`
[[modules]]
id = "ghostty"

[modules.casks]
brew = ["ghostty"]
`)
	m, err := Parse(data)
	if err != nil {
		t.Fatalf("Parse error: %v", err)
	}
	mod := m.Modules[0]
	if len(mod.Packages) != 1 || mod.Packages[0].Manager != domain.Brew || !mod.Packages[0].Cask {
		t.Fatalf("packages = %+v, want one brew cask entry", mod.Packages)
	}
}

func TestParse_PostInstall(t *testing.T) {
	data := []byte(`
[[modules]]
id = "herdr"

  [[modules.post_install]]
  command = "os/mac/herdr/install.sh"
  os = ["mac"]
`)
	m, err := Parse(data)
	if err != nil {
		t.Fatalf("Parse error: %v", err)
	}
	mod := m.Modules[0]
	if len(mod.PostInstall) != 1 || mod.PostInstall[0].Command != "os/mac/herdr/install.sh" {
		t.Fatalf("post_install = %+v", mod.PostInstall)
	}
}

func TestParse_InvalidOSValueIsError(t *testing.T) {
	data := []byte(`
[[modules]]
id = "x"
os = ["solaris"]
`)
	_, err := Parse(data)
	if err == nil || !strings.Contains(err.Error(), "solaris") {
		t.Fatalf("err = %v, want an error mentioning the invalid os value", err)
	}
}

func TestValidate_DuplicateIDsRejected(t *testing.T) {
	m := domain.Manifest{Modules: []domain.Module{{ID: "a"}, {ID: "a"}}}
	if err := Validate(m, t.TempDir()); err == nil {
		t.Fatal("expected a duplicate-id error")
	}
}

func TestValidate_MissingSrcRejected(t *testing.T) {
	repo := t.TempDir()
	m := domain.Manifest{Modules: []domain.Module{
		{ID: "nvim", Links: []domain.Link{{Src: "common/nvim", Dst: "~/.config/nvim"}}},
	}}
	err := Validate(m, repo)
	if err == nil || !strings.Contains(err.Error(), "common/nvim") {
		t.Fatalf("err = %v, want an error naming the missing src", err)
	}
}

func TestValidate_SrcEscapingRepoRootRejected(t *testing.T) {
	repo := t.TempDir()
	// Create the exact target the escaping src would resolve to, so the
	// only possible reason Validate can fail is the escape check itself
	// — not a coincidental "missing src" (if it existed, a naive
	// exists-check-only validator would wrongly accept it).
	target := filepath.Clean(filepath.Join(repo, "../../etc"))
	if err := os.MkdirAll(target, 0o755); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(target) })

	m := domain.Manifest{Modules: []domain.Module{
		{ID: "evil", Links: []domain.Link{{Src: "../../etc", Dst: "~/.config/evil"}}},
	}}
	err := Validate(m, repo)
	if err == nil {
		t.Fatal("expected an error for a src that escapes the repo root, got nil")
	}
	if !strings.Contains(err.Error(), "../../etc") && !strings.Contains(err.Error(), "escapes") {
		t.Errorf("err = %v, want it to name the offending src or say it escapes the repo", err)
	}
}

func TestValidate_AbsoluteSrcRejected(t *testing.T) {
	repo := t.TempDir()
	// filepath.Join(repo, "/etc/passwd") treats the leading "/" as just
	// another path segment, landing under repo — so create that exact
	// spot for real, forcing the absolute-src check itself to be what
	// rejects this, not a coincidental "missing src".
	target := filepath.Join(repo, "etc", "passwd")
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(target, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}

	m := domain.Manifest{Modules: []domain.Module{
		{ID: "evil", Links: []domain.Link{{Src: "/etc/passwd", Dst: "~/.config/evil"}}},
	}}
	if err := Validate(m, repo); err == nil {
		t.Fatal("expected an error for an absolute src, got nil")
	}
}

func TestValidate_ExistingSrcAccepted(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	m := domain.Manifest{Modules: []domain.Module{
		{ID: "nvim", Required: true, Links: []domain.Link{{Src: "common/nvim", Dst: "~/.config/nvim"}}},
	}}
	if err := Validate(m, repo); err != nil {
		t.Fatalf("Validate error: %v", err)
	}
}

func TestValidate_DuplicateDstOnSamePlatformRejected(t *testing.T) {
	repo := t.TempDir()
	for _, p := range []string{"a", "b"} {
		if err := os.MkdirAll(filepath.Join(repo, p), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	m := domain.Manifest{Modules: []domain.Module{
		{ID: "one", Links: []domain.Link{{Src: "a", Dst: "~/.config/same"}}},
		{ID: "two", Links: []domain.Link{{Src: "b", Dst: "~/.config/same"}}},
	}}
	err := Validate(m, repo)
	if err == nil || !strings.Contains(err.Error(), "same") {
		t.Fatalf("err = %v, want a duplicate-dst error", err)
	}
}

func TestValidate_DuplicateDstAllowedWhenOSFiltersDontOverlap(t *testing.T) {
	repo := t.TempDir()
	for _, p := range []string{"a", "b"} {
		if err := os.MkdirAll(filepath.Join(repo, p), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	m := domain.Manifest{Modules: []domain.Module{
		{ID: "one", Links: []domain.Link{{Src: "a", Dst: "~/.config/hatdots/os.x", OS: []domain.OS{domain.Linux}}}},
		{ID: "two", Links: []domain.Link{{Src: "b", Dst: "~/.config/hatdots/os.x", OS: []domain.OS{domain.Mac}}}},
	}}
	if err := Validate(m, repo); err != nil {
		t.Fatalf("Validate error: %v, want no error since the two links never apply to the same platform", err)
	}
}

func TestValidate_RequiredModuleMustSupportEveryOSItLists(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "fish"), 0o755); err != nil {
		t.Fatal(err)
	}
	m := domain.Manifest{Modules: []domain.Module{
		{
			ID:       "fish",
			Required: true,
			OS:       []domain.OS{domain.Linux, domain.Mac},
			Links:    []domain.Link{{Src: "common/fish", Dst: "~/.config/fish/config.fish", OS: []domain.OS{domain.Linux}}},
		},
	}}
	err := Validate(m, repo)
	if err == nil || !strings.Contains(err.Error(), "mac") {
		t.Fatalf("err = %v, want an error about required module fish not covering mac", err)
	}
}

func reflectOSEqual(got []domain.OS, want ...domain.OS) bool {
	if len(got) != len(want) {
		return false
	}
	for i := range got {
		if got[i] != want[i] {
			return false
		}
	}
	return true
}

func reflectDesktopEqual(got []domain.Desktop, want ...domain.Desktop) bool {
	if len(got) != len(want) {
		return false
	}
	for i := range got {
		if got[i] != want[i] {
			return false
		}
	}
	return true
}

func TestLoad_RejectsMissingSchemaMarker(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	data := []byte(`
[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`)
	path := filepath.Join(repo, "modules.toml")
	if err := os.WriteFile(path, data, 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := Load(path); err == nil {
		t.Fatal("expected an error loading a modules.toml with no schema marker, got nil")
	}
}

func TestLoad_AcceptsCorrectSchemaMarker(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, "common", "nvim"), 0o755); err != nil {
		t.Fatal(err)
	}
	data := []byte(`
schema = "hatdots/v1"

[[modules]]
id = "nvim"
required = true

  [[modules.links]]
  src = "common/nvim"
  dst = "~/.config/nvim"
`)
	path := filepath.Join(repo, "modules.toml")
	if err := os.WriteFile(path, data, 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := Load(path); err != nil {
		t.Fatalf("Load error: %v", err)
	}
}

func TestHasSchemaMarker(t *testing.T) {
	dir := t.TempDir()

	missing := filepath.Join(dir, "does-not-exist.toml")
	if HasSchemaMarker(missing) {
		t.Error("HasSchemaMarker(missing file) = true, want false")
	}

	wrong := filepath.Join(dir, "wrong.toml")
	if err := os.WriteFile(wrong, []byte("schema = \"something-else\"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if HasSchemaMarker(wrong) {
		t.Error("HasSchemaMarker(wrong schema) = true, want false")
	}

	none := filepath.Join(dir, "none.toml")
	if err := os.WriteFile(none, []byte("[[modules]]\nid = \"x\"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if HasSchemaMarker(none) {
		t.Error("HasSchemaMarker(no schema field at all) = true, want false")
	}

	correct := filepath.Join(dir, "correct.toml")
	if err := os.WriteFile(correct, []byte("schema = \"hatdots/v1\"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if !HasSchemaMarker(correct) {
		t.Error("HasSchemaMarker(correct schema) = false, want true")
	}
}

func equalStrings(got, want []string) bool {
	if len(got) != len(want) {
		return false
	}
	for i := range got {
		if got[i] != want[i] {
			return false
		}
	}
	return true
}

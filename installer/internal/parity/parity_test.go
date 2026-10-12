// Package parity proves the phase-4 installer's real manifest (modules.toml
// at the repo root) is at least as complete as the three shell scripts it
// replaces: for each platform, every (src, dst) link pair the old script
// creates must also appear in the plan built from modules.toml, unless it
// is explicitly listed below as intentionally dropped, with a reason.
//
// The fixture tables are hand-extracted from reading link-linux.sh,
// link-mac.sh and link-windows.ps1 (never executed) — each entry's comment
// names the script and the line(s) it came from, as of this writing.
package parity

import (
	"path/filepath"
	"runtime"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
	"github.com/hat-y/HatDots/installer/internal/manifest"
)

// linkPair is one (src, dst) pair, with dst still a template ("~/..."):
// expand() resolves it against a fixed per-test env before comparing.
type linkPair struct {
	src string
	dst string
}

func (p linkPair) expand(env map[string]string) linkPair {
	return linkPair{src: p.src, dst: domain.ExpandPath(p.dst, env)}
}

// droppedPair documents one old-script pair that modules.toml does NOT
// reproduce, and why. Every entry here is a deliberate decision recorded
// in odd/tasks/hatdots-unify.md's "Known deviations from the old
// installers" note, not an oversight.
type droppedPair struct {
	pair   linkPair
	reason string
}

// linuxEnv/macEnv/windowsEnv are fixed, platform-plausible environments
// used only to expand "~"/"$VAR" templates deterministically for
// comparison; they never touch the real filesystem or the real $HOME.
func linuxEnv() map[string]string { return map[string]string{"HOME": "/home/u"} }
func macEnv() map[string]string   { return map[string]string{"HOME": "/Users/u"} }
func windowsEnv() map[string]string {
	return map[string]string{"HOME": "/home/u", "LOCALAPPDATA": `C:\Users\u\AppData\Local`}
}

// ─── link-linux.sh fixture ─────────────────────────────────────────────────

// linuxPairs are created on every Linux machine regardless of desktop
// (link-linux.sh has no desktop branch for these).
var linuxPairs = []linkPair{
	{"common/nvim", "~/.config/nvim"},                               // link-linux.sh:117
	{"common/tmux/tmux.conf", "~/.config/tmux/tmux.conf"},           // link-linux.sh:118
	{"common/bin/hat-sf-install", "~/.local/bin/hat-sf-install"},    // link-linux.sh:123
	{"os/linux/ghostty/os.ghostty", "~/.config/hatdots/os.ghostty"}, // link-linux.sh:131
	{"common/zsh/.p10k.zsh", "~/.p10k.zsh"},                         // link-linux.sh:138-140 (was safe_copy, not safe_link)
}

// linuxOmarchyOnlyPairs are additionally created only when
// ~/.local/share/omarchy exists (link-linux.sh:132-135).
var linuxOmarchyOnlyPairs = []linkPair{
	{"os/omarchy/tmux/omarchy.tmux.conf", "~/.config/hatdots/omarchy.tmux.conf"}, // link-linux.sh:133
	{"os/omarchy/ghostty/omarchy.ghostty", "~/.config/hatdots/omarchy.ghostty"},  // link-linux.sh:134
}

var linuxDropped = []droppedPair{
	{
		linkPair{"common/ghostty/shaders", "~/.config/ghostty/shaders"}, // link-linux.sh:119
		"superseded_by_whole_dir_link: the ghostty module now symlinks the whole common/ghostty directory (config+shaders+themes) to ~/.config/ghostty on every OS that has ghostty, which still covers ~/.config/ghostty/shaders as a subdirectory. This also resolves the phase-3 tracker's documented known issue that common/ghostty/config itself was never linked on Linux.",
	},
	{
		linkPair{"<heredoc>", "~/.config/ghostty/config"}, // link-linux.sh:146-195, only if the file didn't already exist
		"generated_config_superseded_by_tracked_file: common/ghostty/config is the tracked source of truth and is linked directly by the whole-dir link above; the one-off heredoc'd config (a different, drifted file) is dropped.",
	},
	{
		linkPair{"<heredoc>", "~/.local/bin/hatdots-launch-terminal"}, // link-linux.sh:208-216
		"superseded_by_ghostty_multiplexer_new: common/ghostty/config's own `command =` line now runs the tracked common/bin/ghostty-multiplexer-new (linked by the ghostty module) instead of a generated per-machine launcher script.",
	},
	{
		linkPair{"<heredoc>", "~/.local/bin/hatdots-launch-terminal-tmux"}, // link-linux.sh:218-231
		"superseded_by_ghostty_multiplexer_new: same as hatdots-launch-terminal above.",
	},
	{
		linkPair{"<heredoc>", "~/.local/bin/tmux-session-layout"}, // link-linux.sh:233-251
		"superseded_by_herdr: common/bin/ghostty-multiplexer-new only calls tmux-session-layout as an optional fallback if it happens to be on PATH, and otherwise falls back to a plain `tmux new-session`; the hardcoded 3-window layout was never promoted to a tracked file. Herdr (see openspec/changes/add-herdr-multiplexor) is now the primary multiplexer; a tmux-only 3-window layout script is no longer the intended UX.",
	},
}

// ─── link-mac.sh fixture ────────────────────────────────────────────────────

var macPairs = []linkPair{
	{"common/nvim", "~/.config/nvim"},                                // link-mac.sh:103
	{"common/zsh/.zshrc", "~/.zshrc"},                                // link-mac.sh:106
	{"common/zsh/.p10k.zsh", "~/.p10k.zsh"},                          // link-mac.sh:107
	{"common/ghostty", "~/.config/ghostty"},                          // link-mac.sh:110
	{"common/tmux/tmux.conf", "~/.tmux.conf"},                        // link-mac.sh:113
	{"common/bin/tmux-work", "~/.local/bin/tmux-work"},               // link-mac.sh:114
	{"os/mac/bin/ghostty-tmux-new", "~/.local/bin/ghostty-tmux-new"}, // link-mac.sh:115
	{"common/bin/hat-sf-install", "~/.local/bin/hat-sf-install"},     // link-mac.sh:118
	{"os/mac/zsh/os.zsh", "~/.config/hatdots/os.zsh"},                // link-mac.sh:122
	{"os/mac/ghostty/os.ghostty", "~/.config/hatdots/os.ghostty"},    // link-mac.sh:123
	{"common/newsboat/config", "~/.config/newsboat/config"},          // link-mac.sh:126
	{"common/newsboat/urls", "~/.config/newsboat/urls"},              // link-mac.sh:127
	{"os/mac/newsboat/hat-news", "~/.local/bin/hat-news"},            // link-mac.sh:128
	{"os/mac/newsboat/os.newsboat", "~/.config/hatdots/os.newsboat"}, // link-mac.sh:129
	{"common/herdr/config.toml", "~/.config/herdr/config.toml"},      // link-mac.sh:133
}

var macDropped = []droppedPair{} // nothing dropped: every mac pair is carried over 1:1.

// ─── link-windows.ps1 fixture ───────────────────────────────────────────────

var windowsPairs = []linkPair{
	{"common/nvim", "%LOCALAPPDATA%/nvim"},               // link-windows.ps1:140/147/157
	{"os/windows/wezterm/wezterm.lua", "~/.wezterm.lua"}, // link-windows.ps1:141/148/158
	{"os/windows/powershell/Microsoft.PowerShell_profile.ps1", "~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"}, // link-windows.ps1:142/149/159
	{"common/starship/starship.toml", "~/.config/starship.toml"},                                                          // link-windows.ps1:143/150/160
}

var windowsDropped = []droppedPair{} // nothing dropped: every windows pair is carried over 1:1.

// ─── plumbing ───────────────────────────────────────────────────────────────

func repoRoot(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	// installer/internal/parity/parity_test.go -> repo root is ../../..
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", ".."))
}

func loadRealManifest(t *testing.T) domain.Manifest {
	t.Helper()
	root := repoRoot(t)
	m, err := manifest.Load(filepath.Join(root, "modules.toml"))
	if err != nil {
		t.Fatalf("loading the real modules.toml: %v", err)
	}
	return m
}

// selectableModuleIDs mirrors what `hatdots --all` selects: every module
// compatible with platform (BuildPlan itself rejects selecting an
// incompatible module id, exactly like a user's explicit --only would).
func selectableModuleIDs(m domain.Manifest, platform domain.Platform) []string {
	var ids []string
	for _, mod := range m.Modules {
		if mod.SupportsPlatform(platform) {
			ids = append(ids, mod.ID)
		}
	}
	return ids
}

// alwaysMissingFS is a domain.FSState fake that always reports "nothing is
// there yet", so every applicable link becomes an ActionLinkCreate. The
// parity test only cares about which (src, dst) pairs the plan contains,
// not what kind of link action they'd be on a particular machine.
type alwaysMissingFS struct{}

func (alwaysMissingFS) Inspect(dst, expandedSrc string) (domain.DstState, error) {
	return domain.DstMissing, nil
}

func planPairs(t *testing.T, m domain.Manifest, platform domain.Platform) map[linkPair]bool {
	t.Helper()
	plan, err := domain.BuildPlan(m, platform, selectableModuleIDs(m, platform), alwaysMissingFS{})
	if err != nil {
		t.Fatalf("BuildPlan(%+v): %v", platform, err)
	}
	set := map[linkPair]bool{}
	for _, a := range plan.Actions {
		if a.Kind == domain.ActionPackageInstall || a.Kind == domain.ActionPostInstall {
			continue
		}
		set[linkPair{src: a.Src, dst: a.Dst}] = true
	}
	return set
}

func assertAllPresent(t *testing.T, got map[linkPair]bool, want []linkPair, dropped []droppedPair, env map[string]string) {
	t.Helper()
	for _, w := range want {
		expanded := w.expand(env)
		if !got[expanded] {
			t.Errorf("old-script pair not covered by the new manifest's plan: src=%q dst=%q (expanded dst=%q)", w.src, w.dst, expanded.dst)
		}
	}
	// Every dropped pair must have a non-empty reason recorded (guards
	// against a silently-empty "intentionally dropped" entry).
	for _, d := range dropped {
		if d.reason == "" {
			t.Errorf("dropped pair %+v has no reason recorded", d.pair)
		}
	}
}

// ─── the four required parity checks ────────────────────────────────────────

func TestParity_LinuxOmarchy(t *testing.T) {
	m := loadRealManifest(t)
	env := linuxEnv()
	platform := domain.Platform{OS: domain.Linux, Desktop: domain.Omarchy, Env: env}
	got := planPairs(t, m, platform)

	want := append(append([]linkPair{}, linuxPairs...), linuxOmarchyOnlyPairs...)
	assertAllPresent(t, got, want, linuxDropped, env)
}

func TestParity_LinuxNoDesktop(t *testing.T) {
	m := loadRealManifest(t)
	env := linuxEnv()
	platform := domain.Platform{OS: domain.Linux, Desktop: domain.NoDesktop, Env: env}
	got := planPairs(t, m, platform)

	assertAllPresent(t, got, linuxPairs, linuxDropped, env)

	// The omarchy-only pairs must NOT show up without the omarchy desktop.
	for _, w := range linuxOmarchyOnlyPairs {
		expanded := w.expand(env)
		if got[expanded] {
			t.Errorf("omarchy-only pair present without the omarchy desktop: %+v", expanded)
		}
	}
}

func TestParity_Mac(t *testing.T) {
	m := loadRealManifest(t)
	env := macEnv()
	platform := domain.Platform{OS: domain.Mac, Desktop: domain.NoDesktop, Env: env}
	got := planPairs(t, m, platform)

	assertAllPresent(t, got, macPairs, macDropped, env)
}

func TestParity_Windows(t *testing.T) {
	m := loadRealManifest(t)
	env := windowsEnv()
	platform := domain.Platform{OS: domain.Windows, Desktop: domain.NoDesktop, Env: env}
	got := planPairs(t, m, platform)

	assertAllPresent(t, got, windowsPairs, windowsDropped, env)
}

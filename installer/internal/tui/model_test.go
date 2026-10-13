package tui

import (
	"errors"
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func key(s string) tea.KeyMsg {
	switch s {
	case "enter":
		return tea.KeyMsg{Type: tea.KeyEnter}
	case "esc":
		return tea.KeyMsg{Type: tea.KeyEsc}
	case "up":
		return tea.KeyMsg{Type: tea.KeyUp}
	case "down":
		return tea.KeyMsg{Type: tea.KeyDown}
	case " ":
		return tea.KeyMsg{Type: tea.KeySpace, Runes: []rune(" ")}
	case "ctrl+c":
		return tea.KeyMsg{Type: tea.KeyCtrlC}
	default:
		return tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune(s)}
	}
}

func update(t *testing.T, m Model, msg tea.Msg) Model {
	t.Helper()
	next, _ := m.Update(msg)
	got, ok := next.(Model)
	if !ok {
		t.Fatalf("Update returned %T, want Model", next)
	}
	return got
}

func TestNew_DefaultSelectionLocksRequiredAndSeedsDefaults(t *testing.T) {
	port := newFixturePort()
	m := New(port, WithoutAnimation())

	if !m.selected["nvim"] {
		t.Error("required module nvim should start selected")
	}
	if !m.selected["tmux"] {
		t.Error("default-selected module tmux should start selected")
	}
	if m.selected["starship"] {
		t.Error("non-default module starship should start unselected")
	}
}

func TestUpdateDetect_EnterGoesToSelect(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter"))
	if m.screen != screenSelect {
		t.Errorf("screen = %v, want screenSelect", m.screen)
	}
}

func TestUpdateDetect_QuitsOnQ(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	_, cmd := m.Update(key("q"))
	if cmd == nil {
		t.Fatal("want a quit command")
	}
}

func TestUpdateSelect_SpaceTogglesOptionalModule(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter")) // -> select screen, cursor on nvim (index 0)
	m = update(t, m, key("down"))  // cursor -> tmux (index 1)

	if !m.selected["tmux"] {
		t.Fatal("precondition: tmux starts selected")
	}
	m = update(t, m, key(" "))
	if m.selected["tmux"] {
		t.Error("space should have deselected tmux")
	}
	m = update(t, m, key(" "))
	if !m.selected["tmux"] {
		t.Error("space should have re-selected tmux")
	}
}

// Required modules are locked: space must never change their selection
// state, however many times it is pressed, however the cursor got there.
func TestUpdateSelect_SpaceCannotToggleRequiredModule(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter")) // -> select screen, cursor on nvim (required, index 0)

	if !m.selected["nvim"] {
		t.Fatal("precondition: nvim starts selected")
	}
	m = update(t, m, key(" "))
	if !m.selected["nvim"] {
		t.Error("space toggled a required module")
	}
}

func TestUpdateSelect_AToggleAllTogglesOnlyOptionalModules(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter"))

	m = update(t, m, key("a")) // not everything optional was on (starship wasn't) -> turn all on
	if !m.selected["tmux"] || !m.selected["starship"] {
		t.Fatalf("want every optional module selected, got tmux=%v starship=%v", m.selected["tmux"], m.selected["starship"])
	}
	if !m.selected["nvim"] {
		t.Error("required module must stay selected")
	}

	m = update(t, m, key("a")) // everything optional was on -> turn all off
	if m.selected["tmux"] || m.selected["starship"] {
		t.Errorf("want every optional module deselected, got tmux=%v starship=%v", m.selected["tmux"], m.selected["starship"])
	}
	if !m.selected["nvim"] {
		t.Error("required module must stay selected even after toggle-all-off")
	}
}

func TestUpdateSelect_EnterBuildsPlanAndGoesToPreview(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter")) // -> select
	m = update(t, m, key("enter")) // -> preview, with default selection (nvim + tmux)

	if m.screen != screenPreview {
		t.Fatalf("screen = %v, want screenPreview", m.screen)
	}
	if m.planErr != nil {
		t.Fatalf("planErr = %v", m.planErr)
	}
	if len(m.plan.Actions) != 2 {
		t.Fatalf("got %d actions, want 2 (nvim required + tmux default)", len(m.plan.Actions))
	}
}

func TestUpdatePreview_EscGoesBackToSelect(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter"))
	m = update(t, m, key("enter")) // -> preview
	m = update(t, m, key("esc"))
	if m.screen != screenSelect {
		t.Errorf("screen = %v, want screenSelect", m.screen)
	}
}

func TestUpdatePreview_DTogglesDryRun(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter"))
	m = update(t, m, key("enter")) // -> preview
	if m.dryRun {
		t.Fatal("precondition: dryRun starts off")
	}
	m = update(t, m, key("d"))
	if !m.dryRun {
		t.Error("d should toggle dryRun on")
	}
}

// When --dry-run was given on the command line (tui.WithInitialDryRun(true)),
// dry-run is authoritative: the preview screen's "d" key must not be able
// to turn it back off.
func TestUpdatePreview_DCannotUnlockDryRunGivenOnCommandLine(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation(), WithInitialDryRun(true))
	m = update(t, m, key("enter"))
	m = update(t, m, key("enter")) // -> preview, dryRun already true (locked)
	if !m.dryRun {
		t.Fatal("precondition: dryRun starts on when given on the command line")
	}
	m = update(t, m, key("d"))
	if !m.dryRun {
		t.Error("d must not unlock/turn off dry-run when it was set via --dry-run")
	}
}

// Without --dry-run on the command line, "d" must still freely toggle.
func TestUpdatePreview_DStillTogglesWhenNotLockedByCommandLine(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation(), WithInitialDryRun(false))
	m = update(t, m, key("enter"))
	m = update(t, m, key("enter")) // -> preview
	m = update(t, m, key("d"))
	if !m.dryRun {
		t.Error("d should still be able to turn dryRun on when not locked")
	}
	m = update(t, m, key("d"))
	if m.dryRun {
		t.Error("d should still be able to turn dryRun back off when not locked")
	}
}

func TestApply_DryRunCompletesWithoutTerminalCommandsAndReachesResult(t *testing.T) {
	port := newFixturePort()
	m := New(port, WithoutAnimation())
	m = update(t, m, key("enter")) // -> select
	m = update(t, m, key("enter")) // -> preview
	m = update(t, m, key("d"))     // dry run on
	m, cmd := applyUpdate(t, m, key("enter"))

	m = drain(t, m, cmd)

	if m.screen != screenResult {
		t.Fatalf("screen = %v, want screenResult", m.screen)
	}
	if len(m.results) != 2 {
		t.Fatalf("got %d results, want 2", len(m.results))
	}
	for _, r := range m.results {
		if r.err != nil {
			t.Errorf("unexpected error for %s: %v", r.action.ModuleID, r.err)
		}
	}
}

// A real tmux-with-dry-run smoke run surfaced this: package-install
// actions have no Dst (only Manager/Packages), so the result screen
// printed a blank line for every package/post-install entry instead of
// describing what it did.
func TestViewResult_PackageInstallEntryShowsManagerAndPackages(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m.screen = screenResult
	m.results = []actionResult{
		{action: domain.Action{Kind: domain.ActionPackageInstall, ModuleID: "tmux", Manager: domain.Pacman, Packages: []string{"tmux"}}},
	}
	out := m.viewResult()
	if !strings.Contains(out, "pacman") || !strings.Contains(out, "tmux") {
		t.Errorf("viewResult() = %q, want it to mention the manager and package name", out)
	}
}

func TestSummarize_BucketsByKindAndFailure(t *testing.T) {
	results := []actionResult{
		{action: domain.Action{Kind: domain.ActionLinkCreate, ModuleID: "nvim"}},
		{action: domain.Action{Kind: domain.ActionLinkReplace, ModuleID: "tmux"}},
		{action: domain.Action{Kind: domain.ActionBackupThenLink, ModuleID: "ghostty"}},
		{action: domain.Action{Kind: domain.ActionLinkSkipIdentical, ModuleID: "fish"}},
		{action: domain.Action{Kind: domain.ActionPostInstall, ModuleID: "herdr"}},
		{action: domain.Action{Kind: domain.ActionLinkCreate, ModuleID: "broken"}, err: errors.New("boom")},
	}
	s := summarize(results)
	if len(s.created) != 1 || len(s.replaced) != 1 || len(s.backedUp) != 1 || len(s.skipped) != 1 || len(s.other) != 1 || len(s.failed) != 1 {
		t.Fatalf("got %+v", s)
	}
}

// applyUpdate is like update but also returns the Cmd, for tests that
// need to drive the message loop manually (entering the apply screen
// issues a Cmd that must run to produce the actionDoneMsg chain).
func applyUpdate(t *testing.T, m Model, msg tea.Msg) (Model, tea.Cmd) {
	t.Helper()
	next, cmd := m.Update(msg)
	got, ok := next.(Model)
	if !ok {
		t.Fatalf("Update returned %T, want Model", next)
	}
	return got, cmd
}

// drain runs cmd and feeds every resulting message back into m.Update,
// following any further Cmd it returns, until nothing is left to run.
// This simulates Bubbletea's own event loop for a model whose apply
// screen chains several Cmds/Msgs in sequence (tests use
// WithoutAnimation, so no tea.Batch/spinner ticking ever enters the
// chain here).
func drain(t *testing.T, m Model, cmd tea.Cmd) Model {
	t.Helper()
	for i := 0; i < 1000 && cmd != nil; i++ {
		m, cmd = applyUpdate(t, m, cmd())
	}
	if cmd != nil {
		t.Fatal("drain: exceeded iteration limit, possible infinite loop")
	}
	return m
}

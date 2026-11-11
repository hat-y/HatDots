package tui

import (
	"errors"
	"reflect"
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

func TestNew_InitialSelectionReplacesDefaults(t *testing.T) {
	// --only starship: the CLI seeds exactly that optional module, so the
	// default-on tmux must start unselected; required nvim stays locked on.
	m := New(newFixturePort(), WithoutAnimation(), WithInitialSelection([]string{"starship"}))

	if got, want := m.SelectedIDs(), []string{"nvim", "starship"}; !reflect.DeepEqual(got, want) {
		t.Errorf("SelectedIDs() = %v, want %v", got, want)
	}
}

func TestNew_SelectedIDsFollowsManifestOrder(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	if got, want := m.SelectedIDs(), []string{"nvim", "tmux"}; !reflect.DeepEqual(got, want) {
		t.Errorf("SelectedIDs() = %v, want %v", got, want)
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

// Applying is a destructive action: it must require the distinct "y"
// key, never "enter" (too easy to hit by accident while just browsing
// the preview).
func TestUpdatePreview_EnterDoesNotApply(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter")) // -> select
	m = update(t, m, key("enter")) // -> preview
	m = update(t, m, key("enter"))
	if m.screen != screenPreview {
		t.Errorf("screen = %v, want screenPreview (enter must not apply)", m.screen)
	}
	if m.applying {
		t.Error("enter on the preview screen must not start applying")
	}
}

func TestUpdatePreview_YApplies(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m = update(t, m, key("enter")) // -> select
	m = update(t, m, key("enter")) // -> preview
	m = update(t, m, key("y"))
	if m.screen != screenApply {
		t.Errorf("screen = %v, want screenApply", m.screen)
	}
	if !m.applying {
		t.Error("y on the preview screen must start applying")
	}
}

// Several rapid "enter" presses starting from the very first screen must
// never reach the apply screen: enter advances detect->select and
// select->preview, but on preview it must be a no-op (see
// TestUpdatePreview_EnterDoesNotApply) — not "apply once more, which
// happens to also be enter".
func TestRapidEnterFromDetect_NeverReachesApply(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	for i := 0; i < 5; i++ {
		m = update(t, m, key("enter"))
		if m.screen == screenApply || m.applying {
			t.Fatalf("reached the apply screen after %d rapid enter presses; screen=%v applying=%v", i+1, m.screen, m.applying)
		}
	}
	if m.screen != screenPreview {
		t.Errorf("screen = %v, want screenPreview after 5 enters (detect->select->preview, then stuck)", m.screen)
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
	m, cmd := applyUpdate(t, m, key("y"))

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

// Results must be truthful about what actually happened: when dry-run
// was on, nothing was really created/replaced/backed up — the apply and
// result screens must say so instead of reusing the past-tense wording
// that implies a real change.
func TestViewApply_TitleShowsDryRun(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m.screen = screenApply
	m.dryRun = true
	out := m.viewApply()
	if !strings.Contains(out, "(dry run)") {
		t.Errorf("viewApply() = %q, want the title to say (dry run)", out)
	}
}

func TestViewApply_TitleOmitsDryRunWhenReal(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m.screen = screenApply
	m.dryRun = false
	out := m.viewApply()
	if strings.Contains(out, "(dry run)") {
		t.Errorf("viewApply() = %q, want no (dry run) marker for a real apply", out)
	}
}

func TestViewResult_DryRunTitleAndLabels(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m.screen = screenResult
	m.dryRun = true
	m.results = []actionResult{
		{action: domain.Action{Kind: domain.ActionLinkCreate, ModuleID: "nvim", Dst: "/home/u/.config/nvim"}},
		{action: domain.Action{Kind: domain.ActionLinkReplace, ModuleID: "tmux", Dst: "/home/u/.config/tmux/tmux.conf"}},
		{action: domain.Action{Kind: domain.ActionBackupThenLink, ModuleID: "starship", Dst: "/home/u/.config/starship.toml"}},
	}
	out := m.viewResult()
	if !strings.Contains(out, "(dry run)") {
		t.Errorf("viewResult() = %q, want the title to say (dry run)", out)
	}
	if !strings.Contains(out, "Would create") {
		t.Errorf("viewResult() = %q, want \"Would create\" instead of \"Created\" during a dry run", out)
	}
	if !strings.Contains(out, "Would replace") {
		t.Errorf("viewResult() = %q, want \"Would replace\" instead of \"Replaced\" during a dry run", out)
	}
	if !strings.Contains(out, "Would back up") {
		t.Errorf("viewResult() = %q, want \"Would back up\" instead of \"Backed up\" during a dry run", out)
	}
	if strings.Contains(out, "Created (") || strings.Contains(out, "Replaced (") {
		t.Errorf("viewResult() = %q, still uses the real-apply past-tense labels during a dry run", out)
	}
}

func TestViewResult_RealApplyKeepsPastTenseLabels(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	m.screen = screenResult
	m.dryRun = false
	m.results = []actionResult{
		{action: domain.Action{Kind: domain.ActionLinkCreate, ModuleID: "nvim", Dst: "/home/u/.config/nvim"}},
	}
	out := m.viewResult()
	if strings.Contains(out, "(dry run)") {
		t.Errorf("viewResult() = %q, want no (dry run) marker for a real apply", out)
	}
	if !strings.Contains(out, "Created (") {
		t.Errorf("viewResult() = %q, want the real-apply \"Created\" label", out)
	}
	if strings.Contains(out, "Would create") {
		t.Errorf("viewResult() = %q, must not say \"Would create\" for a real apply", out)
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

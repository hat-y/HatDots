package tui

import (
	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

// screen identifies which of the TUI's five screens is active.
type screen int

const (
	screenDetect screen = iota
	screenSelect
	screenPreview
	screenApply
	screenResult
)

// actionResult pairs one plan action with the outcome of applying it.
type actionResult struct {
	action domain.Action
	err    error
}

// Model is the whole state of the installer TUI. It is a pure
// presentation layer: every field here is either UI state (cursor,
// screen, toggles) or data already produced by Port — no field is ever
// computed by business rules that belong in internal/domain or
// internal/app.
type Model struct {
	port Port

	screen        screen
	width, height int

	manifest domain.Manifest
	platform domain.Platform
	repoRoot string

	// select screen
	items    []domain.Module // platform-compatible modules, manifest order
	selected map[string]bool
	cursor   int

	// preview/apply
	dryRun       bool
	dryRunLocked bool // true when --dry-run was given on the command line
	plan         domain.Plan
	planErr      error

	// apply screen
	applying bool
	applyIdx int
	results  []actionResult
	spin     spinner.Model
	prog     progress.Model
	animate  bool

	quitting bool
}

// Option configures a new Model.
type Option func(*Model)

// WithoutAnimation disables the spinner's self-driven ticking. Production
// use always animates; tests use this so a captured View() is a
// deterministic single frame instead of racing a real-time ticker.
func WithoutAnimation() Option {
	return func(m *Model) { m.animate = false }
}

// WithInitialDryRun seeds the preview screen's dry-run toggle. The CLI
// uses this to carry an explicit --dry-run flag into the TUI instead of
// silently dropping it once an interactive session takes over. --dry-run
// is authoritative when given: v also locks the toggle, so "d" on the
// preview screen can no longer turn dry-run back off (see
// updatePreview) — a command-line safety flag must not be silently
// undoable by one stray keypress. Called with false (the common case,
// --dry-run not given), the toggle starts off and stays freely
// togglable.
func WithInitialDryRun(v bool) Option {
	return func(m *Model) {
		m.dryRun = v
		m.dryRunLocked = v
	}
}

// New builds the initial Model, on the detect screen, for port.
func New(port Port, opts ...Option) Model {
	m := Model{
		port:     port,
		screen:   screenDetect,
		manifest: port.Manifest(),
		platform: port.Platform(),
		repoRoot: port.RepoRoot(),
		spin:     spinner.New(spinner.WithSpinner(spinner.Dot)),
		prog:     progress.New(progress.WithDefaultGradient()),
		animate:  true,
		width:    80,
		height:   24,
	}
	for _, opt := range opts {
		opt(&m)
	}
	m.items = compatibleModules(m.manifest, m.platform)
	m.selected = defaultSelected(m.items, port.DefaultSelection())
	return m
}

// compatibleModules returns every module (required or optional) that
// supports platform, in manifest order — exactly what the select screen
// shows. Compatibility itself is domain.Module.SupportsPlatform; this
// function only filters, it does not decide compatibility.
func compatibleModules(manifest domain.Manifest, platform domain.Platform) []domain.Module {
	var out []domain.Module
	for _, mod := range manifest.Modules {
		if mod.SupportsPlatform(platform) {
			out = append(out, mod)
		}
	}
	return out
}

// defaultSelected seeds the selection map: every required module is
// always selected (and locked, see updateSelect), every optional module
// starts selected iff its id is in defaults (Port.DefaultSelection, i.e.
// domain.DefaultSelection for this platform).
func defaultSelected(items []domain.Module, defaults []string) map[string]bool {
	def := map[string]bool{}
	for _, id := range defaults {
		def[id] = true
	}
	selected := map[string]bool{}
	for _, mod := range items {
		selected[mod.ID] = mod.Required || def[mod.ID]
	}
	return selected
}

// Init does nothing: the TUI waits for the user to act on the detect
// screen before anything else happens.
func (m Model) Init() tea.Cmd {
	return nil
}

// Update is Bubbletea's single state-transition entry point.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.prog.Width = progressWidth(m.width)
		return m, nil

	case tea.KeyMsg:
		return m.handleKey(msg)

	case spinner.TickMsg:
		if m.screen != screenApply || !m.applying {
			return m, nil
		}
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd

	case execStepMsg:
		return m.handleExecStep(msg)

	case actionDoneMsg:
		return m.handleActionDone(msg)

	case applyFinishedMsg:
		m.applying = false
		m.screen = screenResult
		return m, nil
	}
	return m, nil
}

func (m Model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if msg.String() == "ctrl+c" {
		m.quitting = true
		return m, tea.Quit
	}

	switch m.screen {
	case screenDetect:
		return m.updateDetect(msg)
	case screenSelect:
		return m.updateSelect(msg)
	case screenPreview:
		return m.updatePreview(msg)
	case screenApply:
		return m, nil // no interaction while a plan is being applied
	case screenResult:
		return m.updateResult(msg)
	}
	return m, nil
}

// View renders the active screen.
func (m Model) View() string {
	if m.quitting {
		return ""
	}
	switch m.screen {
	case screenDetect:
		return m.viewDetect()
	case screenSelect:
		return m.viewSelect()
	case screenPreview:
		return m.viewPreview()
	case screenApply:
		return m.viewApply()
	case screenResult:
		return m.viewResult()
	}
	return ""
}

func progressWidth(termWidth int) int {
	w := termWidth - 10
	if w < 10 {
		w = 10
	}
	if w > 60 {
		w = 60
	}
	return w
}

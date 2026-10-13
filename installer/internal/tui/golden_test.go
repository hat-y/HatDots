package tui

import (
	"bytes"
	"io"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/exp/teatest"
	"github.com/muesli/termenv"
)

// termWidth/termHeight are the fixed, deterministic terminal size every
// golden test runs at (see internal/tui's task: "fixed manifest/plan,
// deterministic sizes").
const (
	termWidth  = 80
	termHeight = 24
)

func init() {
	// Force a colorless profile for the whole package's golden tests: the
	// real detected profile depends on the terminal/CI environment
	// (COLORTERM, TERM, NO_COLOR...), which would make the captured ANSI
	// transcripts non-reproducible across machines.
	lipgloss.SetColorProfile(termenv.Ascii)
}

// runSessionUntil drives a *teatest.TestModel through keys, waits for
// marker to appear in the rendered output (the screen under test has
// actually been painted — Bubbletea's renderer flushes on its own timer,
// so quitting immediately after Send without waiting can race ahead of
// the first real frame), sends quitKey, waits for the program to exit,
// and returns the full byte transcript (every frame painted plus the
// terminal-cleanup sequence on exit).
func runSessionUntil(t *testing.T, m tea.Model, marker string, quitKey tea.KeyMsg, keys ...tea.KeyMsg) []byte {
	t.Helper()
	tm := teatest.NewTestModel(t, m, teatest.WithInitialTermSize(termWidth, termHeight))

	var captured bytes.Buffer
	tee := io.TeeReader(tm.Output(), &captured)

	for _, k := range keys {
		tm.Send(k)
	}
	teatest.WaitFor(t, tee, func(bts []byte) bool {
		return bytes.Contains(bts, []byte(marker))
	}, teatest.WithDuration(5*time.Second))

	tm.Send(quitKey)
	tm.WaitFinished(t, teatest.WithFinalTimeout(5*time.Second))

	// Drain whatever cleanup bytes were written after the marker matched;
	// bytes.Buffer.Read never blocks for more data, so this returns as
	// soon as what's already there is consumed.
	if _, err := io.Copy(&captured, tee); err != nil && err != io.EOF {
		t.Fatalf("draining trailing output: %v", err)
	}
	return captured.Bytes()
}

func TestGolden_DetectScreen(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	out := runSessionUntil(t, m, "HatDots installer", key("q"))
	teatest.RequireEqualOutput(t, out)
}

func TestGolden_SelectScreen(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	out := runSessionUntil(t, m, "Select modules", key("q"), key("enter"), key("down"))
	teatest.RequireEqualOutput(t, out)
}

func TestGolden_PreviewScreen(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	out := runSessionUntil(t, m, "Preview", key("q"), key("enter"), key("enter"))
	teatest.RequireEqualOutput(t, out)
}

func TestGolden_ApplyAndResultScreen(t *testing.T) {
	m := New(newFixturePort(), WithoutAnimation())
	// enter -> select, enter -> preview, "d" dry-run on (no terminal
	// commands, no real exec), "y" -> apply (not enter: applying requires
	// the distinct y key); it chains through the fake port's synchronous
	// actions to the result screen on its own.
	out := runSessionUntil(t, m, "Result", key("q"),
		key("enter"), key("enter"), key("d"), key("y"))
	teatest.RequireEqualOutput(t, out)
}

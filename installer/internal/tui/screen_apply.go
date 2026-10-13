package tui

import (
	"fmt"
	"strings"
)

func (m Model) viewApply() string {
	var b strings.Builder
	title := "Applying"
	if m.dryRun {
		// Truthful labeling: a dry run never really creates, replaces,
		// backs up, or runs anything — say so instead of implying a
		// real apply is in progress.
		title += " (dry run)"
	}
	b.WriteString(titleStyle.Render(title))
	b.WriteString("\n\n")

	total := len(m.plan.Actions)
	done := len(m.results)
	var percent float64
	if total > 0 {
		percent = float64(done) / float64(total)
	}
	b.WriteString(m.prog.ViewAs(percent))
	b.WriteString("\n\n")

	if done < total {
		action := m.plan.Actions[done]
		b.WriteString(fmt.Sprintf("%s %s %s (%d/%d)\n", m.spin.View(), action.Kind, action.ModuleID, done+1, total))
	} else {
		b.WriteString(fmt.Sprintf("done (%d/%d)\n", done, total))
	}

	for _, r := range m.results {
		line := fmt.Sprintf("  %s %s %s", resultGlyph(r.err), r.action.Kind, r.action.ModuleID)
		if r.err != nil {
			line += ": " + r.err.Error()
			b.WriteString(errStyle.Render(line) + "\n")
		} else {
			b.WriteString(okStyle.Render(line) + "\n")
		}
	}

	return b.String()
}

func resultGlyph(err error) string {
	if err != nil {
		return "✗"
	}
	return "✓"
}

package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func (m Model) updateResult(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	m.quitting = true
	return m, tea.Quit
}

// resultSummary buckets every finished action by outcome. "created",
// "replaced", "backed up" and "skipped" mirror the link-action kinds
// domain.BuildPlan already decided (see domain.DstState); "other" covers
// package-install/post-install steps, which have no link-shaped bucket
// of their own. Any action that errored lands in "failed" instead of its
// usual bucket, regardless of kind.
type resultSummary struct {
	created  []domain.Action
	replaced []domain.Action
	backedUp []domain.Action
	skipped  []domain.Action
	other    []domain.Action
	failed   []actionResult
}

func summarize(results []actionResult) resultSummary {
	var s resultSummary
	for _, r := range results {
		if r.err != nil {
			s.failed = append(s.failed, r)
			continue
		}
		switch r.action.Kind {
		case domain.ActionLinkCreate:
			s.created = append(s.created, r.action)
		case domain.ActionLinkReplace:
			s.replaced = append(s.replaced, r.action)
		case domain.ActionBackupThenLink:
			s.backedUp = append(s.backedUp, r.action)
		case domain.ActionLinkSkipIdentical:
			s.skipped = append(s.skipped, r.action)
		default:
			s.other = append(s.other, r.action)
		}
	}
	return s
}

func (m Model) viewResult() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("Result"))
	b.WriteString("\n\n")

	s := summarize(m.results)

	writeGroup(&b, "Created", s.created, linkPath)
	writeGroup(&b, "Replaced", s.replaced, linkPath)
	writeGroup(&b, "Backed up (backup kept)", s.backedUp, linkPath)
	writeGroup(&b, "Skipped (already linked)", s.skipped, linkPath)
	writeGroup(&b, "Packages / post-install", s.other, describeAction)

	if len(s.failed) > 0 {
		b.WriteString(errStyle.Render("Failed:"))
		b.WriteString("\n")
		for _, r := range s.failed {
			b.WriteString(fmt.Sprintf("  %s %s: %s\n", r.action.Kind, r.action.ModuleID, r.err.Error()))
		}
		b.WriteString(hintStyle.Render("  Re-run hatdots to retry the failed step(s); fix any reported issue first.\n"))
		b.WriteString("\n")
	}

	b.WriteString(hintStyle.Render("any key: quit"))
	return b.String()
}

// linkPath describes a link-kind action by its destination. It is only
// ever called for the four link-shaped buckets (created/replaced/
// backed-up/skipped), which domain.BuildPlan always gives a non-empty
// Dst, unlike package-install/post-install actions.
func linkPath(a domain.Action) string { return a.Dst }

func writeGroup(b *strings.Builder, label string, actions []domain.Action, describe func(domain.Action) string) {
	if len(actions) == 0 {
		return
	}
	b.WriteString(okStyle.Render(fmt.Sprintf("%s (%d):", label, len(actions))))
	b.WriteString("\n")
	for _, a := range actions {
		b.WriteString(fmt.Sprintf("  %s\n", describe(a)))
	}
	b.WriteString("\n")
}

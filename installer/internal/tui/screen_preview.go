package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func (m Model) updatePreview(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q":
		m.quitting = true
		return m, tea.Quit

	case "esc":
		m.screen = screenSelect
		return m, nil

	case "d":
		m.dryRun = !m.dryRun
		return m, nil

	case "enter":
		if m.planErr != nil {
			return m, nil
		}
		m.screen = screenApply
		m.applying = true
		m.applyIdx = 0
		m.results = nil
		cmd := m.runAction(0)
		if m.animate {
			return m, tea.Batch(cmd, m.spin.Tick)
		}
		return m, cmd
	}
	return m, nil
}

func (m Model) viewPreview() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("Preview"))
	b.WriteString("\n\n")

	if m.planErr != nil {
		b.WriteString(errStyle.Render("plan error: " + m.planErr.Error()))
		b.WriteString("\n\n")
		b.WriteString(hintStyle.Render("esc: back   q: quit"))
		return b.String()
	}

	byModule := groupByModule(m.plan)
	for _, g := range byModule {
		b.WriteString(fmt.Sprintf("  %s\n", g.moduleID))
		for _, a := range g.actions {
			b.WriteString("    " + describeAction(a) + "\n")
		}
	}

	var toBackUp []string
	for _, a := range m.plan.Actions {
		if a.Kind == domain.ActionBackupThenLink {
			toBackUp = append(toBackUp, a.Dst)
		}
	}
	if len(toBackUp) > 0 {
		b.WriteString("\n")
		b.WriteString(warnStyle.Render("These files will be replaced (backup kept):"))
		b.WriteString("\n")
		for _, dst := range toBackUp {
			b.WriteString("  " + dst + "\n")
		}
	}

	b.WriteString("\n")
	b.WriteString(fmt.Sprintf("Dry run: %s\n", dryRunLabel(m.dryRun)))
	b.WriteString("\n")
	b.WriteString(hintStyle.Render("d: toggle dry-run   enter: apply   esc: back   q: quit"))
	return b.String()
}

func dryRunLabel(on bool) string {
	if on {
		return "on (nothing will be changed)"
	}
	return "off"
}

type moduleGroup struct {
	moduleID string
	actions  []domain.Action
}

// groupByModule groups plan's actions by ModuleID, preserving the plan's
// own action order within and across modules (the plan is already
// manifest-ordered — this only re-buckets it for display).
func groupByModule(plan domain.Plan) []moduleGroup {
	index := map[string]int{}
	var groups []moduleGroup
	for _, a := range plan.Actions {
		i, ok := index[a.ModuleID]
		if !ok {
			i = len(groups)
			index[a.ModuleID] = i
			groups = append(groups, moduleGroup{moduleID: a.ModuleID})
		}
		groups[i].actions = append(groups[i].actions, a)
	}
	return groups
}

func describeAction(a domain.Action) string {
	switch a.Kind {
	case domain.ActionPackageInstall:
		cask := ""
		if a.Cask {
			cask = " (cask)"
		}
		return fmt.Sprintf("%-22s %s%s %v", a.Kind, a.Manager, cask, a.Packages)
	case domain.ActionPostInstall:
		return fmt.Sprintf("%-22s %s", a.Kind, a.Command)
	default:
		return fmt.Sprintf("%-22s %s -> %s", a.Kind, a.Dst, a.Src)
	}
}

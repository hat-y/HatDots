package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

// updateSelect handles the module-selection screen: required modules are
// always shown checked and cannot be toggled; optional modules toggle
// with space, and "a" toggles every optional module at once. Which
// modules are required/optional/default-selected is entirely
// Port/domain data (Module.Required, Port.DefaultSelection) — this
// function only reacts to key presses.
func (m Model) updateSelect(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "esc":
		m.quitting = true
		return m, tea.Quit

	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
		return m, nil

	case "down", "j":
		if len(m.items) > 0 && m.cursor < len(m.items)-1 {
			m.cursor++
		}
		return m, nil

	case " ":
		if len(m.items) == 0 {
			return m, nil
		}
		mod := m.items[m.cursor]
		if !mod.Required {
			m.selected[mod.ID] = !m.selected[mod.ID]
		}
		return m, nil

	case "a":
		allOn := allOptionalSelected(m.items, m.selected)
		for _, mod := range m.items {
			if mod.Required {
				continue
			}
			m.selected[mod.ID] = !allOn
		}
		return m, nil

	case "enter":
		var sel []string
		for _, mod := range m.items {
			if !mod.Required && m.selected[mod.ID] {
				sel = append(sel, mod.ID)
			}
		}
		plan, err := m.port.Plan(sel)
		m.plan = plan
		m.planErr = err
		m.screen = screenPreview
		return m, nil
	}
	return m, nil
}

func allOptionalSelected(items []domain.Module, selected map[string]bool) bool {
	for _, mod := range items {
		if mod.Required {
			continue
		}
		if !selected[mod.ID] {
			return false
		}
	}
	return true
}

func (m Model) viewSelect() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("Select modules"))
	b.WriteString("\n\n")

	for i, mod := range m.items {
		glyph := unselectedGlyph
		if m.selected[mod.ID] {
			glyph = selectedGlyph
		}
		line := fmt.Sprintf("%s %-14s %s", glyph, mod.ID, mod.Description)
		if mod.Required {
			line = fmt.Sprintf("%s %-14s %s", lockedGlyph, mod.ID, mod.Description)
			line = lockedStyle.Render(line)
		}
		cursor := "  "
		if i == m.cursor {
			cursor = cursorStyle.Render("> ")
			if !mod.Required {
				line = cursorStyle.Render(fmt.Sprintf("%s %-14s %s", glyph, mod.ID, mod.Description))
			}
		}
		b.WriteString(cursor + line + "\n")
	}

	b.WriteString("\n")
	b.WriteString(hintStyle.Render("space: toggle   a: toggle all optional   enter: preview   esc: quit"))
	return b.String()
}

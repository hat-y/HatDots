package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func (m Model) updateDetect(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "esc":
		m.quitting = true
		return m, tea.Quit
	case "enter", " ":
		m.screen = screenSelect
		return m, nil
	}
	return m, nil
}

func (m Model) viewDetect() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("HatDots installer"))
	b.WriteString("\n\n")
	b.WriteString(fmt.Sprintf("  OS:              %s\n", m.platform.OS))
	b.WriteString(fmt.Sprintf("  Desktop:         %s\n", desktopLabel(m.platform.Desktop)))
	b.WriteString(fmt.Sprintf("  Package manager: %s\n", pkgManagerLabel(m.platform.PkgManager, m.platform.AURHelper)))
	b.WriteString(fmt.Sprintf("  Repo:            %s\n", m.repoRoot))
	b.WriteString("\n")
	b.WriteString(hintStyle.Render("enter: continue   q: quit"))
	return b.String()
}

func desktopLabel(d domain.Desktop) string {
	if d == domain.NoDesktop {
		return "none"
	}
	return string(d)
}

func pkgManagerLabel(mgr domain.PkgManager, aurHelper string) string {
	if mgr == domain.UnknownPkgManager {
		return "none detected"
	}
	if mgr == domain.AUR && aurHelper != "" {
		return fmt.Sprintf("%s (%s)", mgr, aurHelper)
	}
	return string(mgr)
}

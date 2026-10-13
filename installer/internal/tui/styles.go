package tui

import "github.com/charmbracelet/lipgloss"

var (
	titleStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("63"))
	hintStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	errStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("203"))
	okStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("78"))
	warnStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("214"))

	cursorStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("63")).Bold(true)
	lockedStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	selectedGlyph   = "[x]"
	unselectedGlyph = "[ ]"
	lockedGlyph     = "[x] (required)"
)

package tui

import (
	tea "github.com/charmbracelet/bubbletea"
)

// Run launches the interactive installer TUI over port, with stdio
// wired to the real terminal (os.Stdin/Stdout) and the alt screen
// enabled. It returns once the user quits, successfully or not.
func Run(port Port, opts ...Option) error {
	p := tea.NewProgram(New(port, opts...), tea.WithAltScreen())
	_, err := p.Run()
	return err
}

package tui

import (
	"os/exec"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/hat-y/HatDots/installer/internal/pkg"
)

// actionDoneMsg reports that the action at idx (in m.plan.Actions) has
// finished, whatever path it took to get there (a direct ApplyAction
// call or a chain of terminal commands).
type actionDoneMsg struct {
	idx int
	err error
}

// execStepMsg reports that one terminal command (step) of action idx's
// Port.TerminalCommands finished.
type execStepMsg struct {
	idx  int
	step int
	err  error
}

// applyFinishedMsg signals every action in the plan has been processed;
// the model moves to the result screen.
type applyFinishedMsg struct{}

// runAction returns the Cmd that carries out plan.Actions[idx]: either a
// chain of real-terminal commands (package installs, post-install
// scripts — see Port.TerminalCommands) run through tea.ExecProcess so the
// TUI suspends and the user can answer an interactive sudo prompt, or a
// direct, non-interactive Port.ApplyAction call for everything else
// (links, and any action at all when dryRun is set, since a dry run never
// needs a real terminal).
func (m Model) runAction(idx int) tea.Cmd {
	if idx >= len(m.plan.Actions) {
		return func() tea.Msg { return applyFinishedMsg{} }
	}
	action := m.plan.Actions[idx]

	if !m.dryRun {
		if cmds := m.port.TerminalCommands(action); len(cmds) > 0 {
			return m.execStep(idx, cmds, 0)
		}
	}

	port := m.port
	dryRun := m.dryRun
	return func() tea.Msg {
		err := port.ApplyAction(action, dryRun)
		return actionDoneMsg{idx: idx, err: err}
	}
}

// execStep runs cmds[step] via tea.ExecProcess. cmds is recomputed by the
// caller from Port.TerminalCommands on every step (it is a pure function
// of the action), so the model itself never has to stash the pending
// command list.
func (m Model) execStep(idx int, cmds []pkg.Command, step int) tea.Cmd {
	c := exec.Command(cmds[step].Name, cmds[step].Args...)
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return execStepMsg{idx: idx, step: step, err: err}
	})
}

func (m Model) handleExecStep(msg execStepMsg) (tea.Model, tea.Cmd) {
	if msg.err != nil {
		return m.handleActionDone(actionDoneMsg{idx: msg.idx, err: msg.err})
	}
	action := m.plan.Actions[msg.idx]
	cmds := m.port.TerminalCommands(action)
	if msg.step+1 < len(cmds) {
		return m, m.execStep(msg.idx, cmds, msg.step+1)
	}
	return m.handleActionDone(actionDoneMsg{idx: msg.idx, err: nil})
}

func (m Model) handleActionDone(msg actionDoneMsg) (tea.Model, tea.Cmd) {
	action := m.plan.Actions[msg.idx]
	m.results = append(m.results, actionResult{action: action, err: msg.err})
	next := msg.idx + 1
	m.applyIdx = next
	return m, m.runAction(next)
}

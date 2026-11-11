// Package tui is a Bubbletea presentation adapter over internal/app. It
// contains no business logic of its own: every decision about what a
// module default-selects to, what a plan contains, or what command
// installs a package is made by internal/domain, internal/app, or
// internal/pkg and merely rendered or dispatched here.
package tui

import (
	"github.com/hat-y/HatDots/installer/internal/app"
	"github.com/hat-y/HatDots/installer/internal/domain"
	"github.com/hat-y/HatDots/installer/internal/pkg"
)

// Port is everything the TUI needs from the application core. It exists
// so tests can drive the model against a fixed fake instead of a real
// repo/filesystem/platform, and so the TUI never imports internal/linker
// or internal/platform directly.
type Port interface {
	// Manifest returns the loaded, already-absolutized manifest.
	Manifest() domain.Manifest
	// Platform returns the already-detected target platform (the TUI
	// does not detect anything itself — see cmd/hatdots).
	Platform() domain.Platform
	// RepoRoot returns the repo root the manifest was loaded from.
	RepoRoot() string
	// DefaultSelection returns the optional module ids pre-selected for
	// Platform (domain.DefaultSelection). Required modules are not
	// included; the select screen always shows and locks them.
	DefaultSelection() []string
	// Plan builds the install plan for the given selection of optional
	// module ids (required modules are added automatically).
	Plan(selection []string) (domain.Plan, error)
	// ApplyAction carries out one action directly (link actions, or
	// package/post-install actions under dryRun, which never touch a
	// real terminal).
	ApplyAction(action domain.Action, dryRun bool) error
	// TerminalCommands returns the command(s) that must run in a real,
	// non-alt-screen terminal for action (package installs that may
	// prompt for a sudo password, post-install scripts), or nil when
	// action does not need one. The apply screen runs these through
	// tea.ExecProcess instead of calling ApplyAction.
	TerminalCommands(action domain.Action) []pkg.Command
}

// AppPort adapts a loaded app.App plus an already-detected Platform to
// the Port interface. It is the only file in this package allowed to
// import internal/app's concrete type.
type AppPort struct {
	App  app.App
	Plat domain.Platform
	// Exec probes which packages are already provided before any install
	// command is handed to the terminal. Nil means pkg.RealExecutor.
	Exec pkg.Executor
}

func (p AppPort) executor() pkg.Executor {
	if p.Exec == nil {
		return pkg.RealExecutor{}
	}
	return p.Exec
}

// NewAppPort builds the real Port the CLI hands to the TUI.
func NewAppPort(a app.App, platform domain.Platform) AppPort {
	return AppPort{App: a, Plat: platform}
}

func (p AppPort) Manifest() domain.Manifest { return p.App.Manifest }

func (p AppPort) Platform() domain.Platform { return p.Plat }

func (p AppPort) RepoRoot() string { return p.App.RepoRoot }

func (p AppPort) DefaultSelection() []string {
	return domain.DefaultSelection(p.App.Manifest, p.Plat)
}

func (p AppPort) Plan(selection []string) (domain.Plan, error) {
	return p.App.Plan(p.Plat, selection)
}

func (p AppPort) ApplyAction(action domain.Action, dryRun bool) error {
	return p.App.ApplyAction(action, dryRun)
}

func (p AppPort) TerminalCommands(action domain.Action) []pkg.Command {
	switch action.Kind {
	case domain.ActionPackageInstall:
		// Nothing missing (or the probe failed) returns nil: the apply
		// screen then falls back to ApplyAction, which runs the same
		// probe through pkg.Install and either no-ops or reports the error.
		missing, err := pkg.Unsatisfied(p.executor(), action.Manager, action.Packages)
		if err != nil || len(missing) == 0 {
			return nil
		}
		cmds, err := pkg.BuildCommands(action.Manager, missing, action.Cask, p.Plat.AURHelper)
		if err != nil {
			return nil
		}
		return cmds
	case domain.ActionPostInstall:
		cmd := app.PostInstallCommand(action.Command)
		if cmd.Name == "" {
			return nil
		}
		return []pkg.Command{cmd}
	default:
		return nil
	}
}

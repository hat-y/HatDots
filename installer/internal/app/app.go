// Package app wires the installer's adapters (manifest, platform, linker,
// pkg) around the domain core into the three use cases the CLI (and later
// the TUI) drive: Load, Plan, and Apply.
package app

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/hat-y/HatDots/installer/internal/domain"
	"github.com/hat-y/HatDots/installer/internal/linker"
	"github.com/hat-y/HatDots/installer/internal/manifest"
	"github.com/hat-y/HatDots/installer/internal/pkg"
)

// ManifestFileName is modules.toml's expected name at the repo root.
const ManifestFileName = "modules.toml"

// App holds the manifest for one repo, with every link Src already made
// absolute and every post-install script command resolved to an absolute
// path when it names a real file in the repo.
type App struct {
	RepoRoot string
	Manifest domain.Manifest
}

// Load reads and validates <repoRoot>/modules.toml and absolutizes it.
func Load(repoRoot string) (App, error) {
	path := filepath.Join(repoRoot, ManifestFileName)
	m, err := manifest.Load(path)
	if err != nil {
		return App{}, err
	}
	return App{RepoRoot: repoRoot, Manifest: resolveManifest(m, repoRoot)}, nil
}

// Plan builds the install plan for platform and selection.
func (a App) Plan(platform domain.Platform, selection []string) (domain.Plan, error) {
	return domain.BuildPlan(a.Manifest, platform, selection, linker.FSState{})
}

// Event reports the outcome of applying one action.
type Event struct {
	Action domain.Action
	Err    error
}

// Apply carries out every action in plan. When dryRun is true, nothing
// touches the filesystem or runs a real command; progress (optional) is
// still called so a caller can show what *would* happen. progress may be
// nil.
func (a App) Apply(plan domain.Plan, dryRun bool, progress func(Event)) error {
	for _, action := range plan.Actions {
		err := a.ApplyAction(action, dryRun)
		if progress != nil {
			progress(Event{Action: action, Err: err})
		}
		if err != nil {
			return fmt.Errorf("apply %s (%s): %w", action.Kind, action.ModuleID, err)
		}
	}
	return nil
}

// ApplyAction carries out exactly one action: the same per-action logic
// Apply loops over, exposed separately so a presentation adapter (the
// TUI) can drive a plan one action at a time and substitute its own
// execution strategy for actions that need an interactive terminal
// (package installs, post-install scripts — see internal/tui's
// Port.TerminalCommands) while every other action still goes through
// this one path. dryRun has the same meaning as in Apply.
func (a App) ApplyAction(action domain.Action, dryRun bool) error {
	l := linker.Linker{DryRun: dryRun}
	var exec pkg.Executor = pkg.RealExecutor{}
	if dryRun {
		exec = noopExecutor{}
	}

	switch action.Kind {
	case domain.ActionLinkCreate, domain.ActionLinkReplace, domain.ActionLinkSkipIdentical, domain.ActionBackupThenLink:
		return l.Apply(action)
	case domain.ActionPackageInstall:
		// aurHelper is always "" here: no module in the real manifest
		// needs an AUR-only package yet, and Action does not carry a
		// resolved AUR helper (see installer/README.md's "known
		// limitations"). BuildCommands only consults it for
		// domain.AUR actions, so this is a no-op for every manager we
		// actually ship.
		return pkg.Install(exec, action.Manager, action.Packages, action.Cask, "")
	case domain.ActionPostInstall:
		return runPostInstall(exec, action.Command)
	default:
		return fmt.Errorf("app: unknown action kind: %s", action.Kind)
	}
}

// PostInstallCommand resolves a post-install action's declarative Command
// string into the concrete pkg.Command that would run it: the bare
// executable when command is an absolute path (already resolved by
// resolvePostInstall at Load time), or a literal shell command wrapped in
// "sh -c" otherwise. An empty command returns the zero Command. Exposed so
// the TUI can build the same command tea.ExecProcess needs to run a
// post-install step in a real terminal, without re-deciding the
// path-vs-literal distinction itself.
func PostInstallCommand(command string) pkg.Command {
	if command == "" {
		return pkg.Command{}
	}
	if filepath.IsAbs(command) {
		return pkg.Command{Name: command}
	}
	return pkg.Command{Name: "sh", Args: []string{"-c", command}}
}

func runPostInstall(exec pkg.Executor, command string) error {
	cmd := PostInstallCommand(command)
	if cmd.Name == "" {
		return nil
	}
	return exec.Run(cmd)
}

// noopExecutor backs dry-run Apply calls: it never runs anything.
type noopExecutor struct{}

func (noopExecutor) Run(pkg.Command) error { return nil }

// Probe reports every probed package as satisfied, so a dry-run never
// shells out to a package manager.
func (noopExecutor) Probe(pkg.Command) (string, int, error) { return "", 0, nil }

// resolveManifest returns a copy of m with every link Src and every
// repo-relative post-install script command made absolute against
// repoRoot. A post-install Command is treated as a script path (and
// absolutized) only when it names an existing non-directory file in the
// repo; otherwise it is left as a literal shell command.
func resolveManifest(m domain.Manifest, repoRoot string) domain.Manifest {
	out := domain.Manifest{Modules: make([]domain.Module, len(m.Modules))}
	for i, mod := range m.Modules {
		modCopy := mod
		modCopy.Links = make([]domain.Link, len(mod.Links))
		for j, l := range mod.Links {
			l.Src = filepath.Join(repoRoot, l.Src)
			modCopy.Links[j] = l
		}
		modCopy.PostInstall = make([]domain.PostInstall, len(mod.PostInstall))
		for j, p := range mod.PostInstall {
			modCopy.PostInstall[j] = resolvePostInstall(p, repoRoot)
		}
		out.Modules[i] = modCopy
	}
	return out
}

func resolvePostInstall(p domain.PostInstall, repoRoot string) domain.PostInstall {
	candidate := filepath.Join(repoRoot, p.Command)
	if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
		p.Command = candidate
	}
	return p
}

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
	l := linker.Linker{DryRun: dryRun}
	var exec pkg.Executor = pkg.RealExecutor{}
	if dryRun {
		exec = noopExecutor{}
	}

	report := func(action domain.Action, err error) {
		if progress != nil {
			progress(Event{Action: action, Err: err})
		}
	}

	for _, action := range plan.Actions {
		var err error
		switch action.Kind {
		case domain.ActionLinkCreate, domain.ActionLinkReplace, domain.ActionLinkSkipIdentical, domain.ActionBackupThenLink:
			err = l.Apply(action)
		case domain.ActionPackageInstall:
			// aurHelper is always "" here: no module in the real manifest
			// needs an AUR-only package yet, and Action does not carry a
			// resolved AUR helper (see installer/README.md's "known
			// limitations"). BuildCommands only consults it for
			// domain.AUR actions, so this is a no-op for every manager we
			// actually ship.
			err = pkg.Install(exec, action.Manager, action.Packages, action.Cask, "")
		case domain.ActionPostInstall:
			err = runPostInstall(exec, action.Command)
		default:
			err = fmt.Errorf("app: unknown action kind: %s", action.Kind)
		}
		report(action, err)
		if err != nil {
			return fmt.Errorf("apply %s (%s): %w", action.Kind, action.ModuleID, err)
		}
	}
	return nil
}

func runPostInstall(exec pkg.Executor, command string) error {
	if command == "" {
		return nil
	}
	if filepath.IsAbs(command) {
		return exec.Run(pkg.Command{Name: command})
	}
	return exec.Run(pkg.Command{Name: "sh", Args: []string{"-c", command}})
}

// noopExecutor backs dry-run Apply calls: it never runs anything.
type noopExecutor struct{}

func (noopExecutor) Run(pkg.Command) error { return nil }

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

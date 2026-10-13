package tui

import (
	"fmt"

	"github.com/hat-y/HatDots/installer/internal/domain"
	"github.com/hat-y/HatDots/installer/internal/pkg"
)

// fakePort is a fixed, deterministic Port implementation for tests: no
// filesystem, no real platform detection, no real commands. It mirrors
// just enough of domain.BuildPlan's/app.App's real behavior (required
// modules always included, link-create for anything not pre-seeded as
// existing) to exercise the model without depending on either package's
// internals.
type fakePort struct {
	manifest domain.Manifest
	platform domain.Platform
	repoRoot string
	defaults []string

	// applyErrFor, keyed by ModuleID, makes ApplyAction fail for that
	// module so result-screen bucketing can be tested.
	applyErrFor map[string]error
	applyCalls  []domain.Action
}

func (f *fakePort) Manifest() domain.Manifest  { return f.manifest }
func (f *fakePort) Platform() domain.Platform  { return f.platform }
func (f *fakePort) RepoRoot() string           { return f.repoRoot }
func (f *fakePort) DefaultSelection() []string { return f.defaults }

func (f *fakePort) Plan(selection []string) (domain.Plan, error) {
	effective := map[string]bool{}
	for _, mod := range f.manifest.Modules {
		if mod.Required && mod.SupportsPlatform(f.platform) {
			effective[mod.ID] = true
		}
	}
	for _, id := range selection {
		mod, ok := f.manifest.ModuleByID(id)
		if !ok {
			return domain.Plan{}, fmt.Errorf("fakePort: unknown module %q", id)
		}
		if !mod.SupportsPlatform(f.platform) {
			return domain.Plan{}, fmt.Errorf("fakePort: module %q unsupported on this platform", id)
		}
		effective[id] = true
	}

	var plan domain.Plan
	for _, mod := range f.manifest.Modules {
		if !effective[mod.ID] {
			continue
		}
		for _, l := range mod.Links {
			plan.Actions = append(plan.Actions, domain.Action{
				Kind:     domain.ActionLinkCreate,
				ModuleID: mod.ID,
				Src:      l.Src,
				Dst:      l.Dst,
			})
		}
		for _, p := range mod.Packages {
			plan.Actions = append(plan.Actions, domain.Action{
				Kind:     domain.ActionPackageInstall,
				ModuleID: mod.ID,
				Manager:  p.Manager,
				Packages: p.Names,
				Cask:     p.Cask,
			})
		}
		for _, p := range mod.PostInstall {
			plan.Actions = append(plan.Actions, domain.Action{
				Kind:     domain.ActionPostInstall,
				ModuleID: mod.ID,
				Command:  p.Command,
			})
		}
	}
	return plan, nil
}

func (f *fakePort) ApplyAction(action domain.Action, dryRun bool) error {
	f.applyCalls = append(f.applyCalls, action)
	if dryRun {
		return nil
	}
	if f.applyErrFor != nil {
		if err, ok := f.applyErrFor[action.ModuleID]; ok {
			return err
		}
	}
	return nil
}

func (f *fakePort) TerminalCommands(action domain.Action) []pkg.Command {
	switch action.Kind {
	case domain.ActionPackageInstall:
		return []pkg.Command{{Name: "echo", Args: []string{"install"}}}
	case domain.ActionPostInstall:
		return []pkg.Command{{Name: "echo", Args: []string{"post-install"}}}
	default:
		return nil
	}
}

func fixtureManifest() domain.Manifest {
	return domain.Manifest{Modules: []domain.Module{
		{
			ID:       "nvim",
			Name:     "Neovim",
			Required: true,
			Links:    []domain.Link{{Src: "common/nvim", Dst: "~/.config/nvim"}},
		},
		{
			ID:      "tmux",
			Name:    "tmux",
			Default: true,
			Links:   []domain.Link{{Src: "common/tmux/tmux.conf", Dst: "~/.config/tmux/tmux.conf"}},
		},
		{
			ID:      "starship",
			Name:    "Starship",
			Default: false,
			Links:   []domain.Link{{Src: "common/starship/starship.toml", Dst: "~/.config/starship.toml"}},
		},
	}}
}

func fixturePlatform() domain.Platform {
	return domain.Platform{OS: domain.Linux, Env: map[string]string{"HOME": "/home/test"}}
}

func newFixturePort() *fakePort {
	manifest := fixtureManifest()
	platform := fixturePlatform()
	return &fakePort{
		manifest: manifest,
		platform: platform,
		repoRoot: "/repo",
		defaults: domain.DefaultSelection(manifest, platform),
	}
}

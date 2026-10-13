package domain

import "fmt"

// ActionKind identifies the kind of step a Plan wants carried out.
type ActionKind string

const (
	ActionLinkCreate        ActionKind = "link-create"
	ActionLinkReplace       ActionKind = "link-replace"
	ActionLinkSkipIdentical ActionKind = "link-skip-identical"
	ActionBackupThenLink    ActionKind = "backup-then-link"
	ActionPackageInstall    ActionKind = "package-install"
	ActionPostInstall       ActionKind = "post-install"
)

// Action is one concrete step of a Plan.
type Action struct {
	Kind     ActionKind
	ModuleID string

	// Link-kind fields. Src/Dst are expanded, OS-resolved absolute (or
	// repo-root-relative for Src) paths, not templates.
	Src string
	Dst string

	// Package-kind fields.
	Manager  PkgManager
	Packages []string
	Cask     bool

	// Post-install-kind fields.
	Command string
}

// Plan is an ordered, deterministic sequence of actions.
type Plan struct {
	Actions []Action
}

// DstState describes what currently sits at a link destination.
type DstState int

const (
	// DstMissing: nothing exists at the destination.
	DstMissing DstState = iota
	// DstSymlinkToExpectedSrc: destination is already a symlink pointing
	// at the expected source (idempotent, no-op).
	DstSymlinkToExpectedSrc
	// DstSymlinkElsewhere: destination is a symlink, but not to the
	// expected source.
	DstSymlinkElsewhere
	// DstOther: destination exists and is a real file or directory (not a
	// symlink).
	DstOther
)

// FSState is the port BuildPlan uses to learn what already exists on disk
// at a candidate link destination, without doing any I/O itself. The
// linker adapter implements this against the real filesystem; tests use an
// in-memory fake, which keeps BuildPlan itself pure and fast to test.
type FSState interface {
	Inspect(dst, expandedSrc string) (DstState, error)
}

// BuildPlan computes the ordered set of actions needed to install the
// selection of modules on platform, given manifest and the current
// filesystem state. Required modules are always included in addition to
// selection. Selecting an unknown module id, or a module incompatible with
// platform, is an error.
func BuildPlan(manifest Manifest, platform Platform, selection []string, fs FSState) (Plan, error) {
	effective, err := resolveSelection(manifest, platform, selection)
	if err != nil {
		return Plan{}, err
	}

	var plan Plan
	for _, mod := range manifest.Modules {
		if !effective[mod.ID] {
			continue
		}

		for _, link := range mod.Links {
			if !link.AppliesTo(platform) {
				continue
			}
			action, err := buildLinkAction(mod.ID, link, platform, fs)
			if err != nil {
				return Plan{}, err
			}
			plan.Actions = append(plan.Actions, action)
		}

		for _, pkgSpec := range mod.Packages {
			if pkgSpec.Manager != platform.PkgManager || len(pkgSpec.Names) == 0 {
				continue
			}
			plan.Actions = append(plan.Actions, Action{
				Kind:     ActionPackageInstall,
				ModuleID: mod.ID,
				Manager:  pkgSpec.Manager,
				Packages: pkgSpec.Names,
				Cask:     pkgSpec.Cask,
			})
		}

		for _, post := range mod.PostInstall {
			if !post.AppliesTo(platform) {
				continue
			}
			plan.Actions = append(plan.Actions, Action{
				Kind:     ActionPostInstall,
				ModuleID: mod.ID,
				Command:  post.Command,
			})
		}
	}

	return plan, nil
}

func buildLinkAction(moduleID string, link Link, platform Platform, fs FSState) (Action, error) {
	dstTemplate := link.ResolveDst(platform.OS)
	src := ExpandPath(link.Src, platform.Env)
	dst := ExpandPath(dstTemplate, platform.Env)

	state, err := fs.Inspect(dst, src)
	if err != nil {
		return Action{}, fmt.Errorf("module %s: inspect %s: %w", moduleID, dst, err)
	}

	kind := ActionLinkCreate
	switch state {
	case DstMissing:
		kind = ActionLinkCreate
	case DstSymlinkToExpectedSrc:
		kind = ActionLinkSkipIdentical
	case DstSymlinkElsewhere:
		kind = ActionLinkReplace
	case DstOther:
		kind = ActionBackupThenLink
	}

	return Action{
		Kind:     kind,
		ModuleID: moduleID,
		Src:      src,
		Dst:      dst,
	}, nil
}

// DefaultSelection returns the ids of every optional module that should
// be pre-selected on platform without an explicit --all/--only (see
// Module.IsDefaultFor), in manifest order. Required modules are not
// included here: BuildPlan always adds them on its own.
func DefaultSelection(manifest Manifest, platform Platform) []string {
	var ids []string
	for _, mod := range manifest.Modules {
		if mod.IsDefaultFor(platform) {
			ids = append(ids, mod.ID)
		}
	}
	return ids
}

// resolveSelection validates selection against manifest and platform, and
// returns the full set of module ids (selection plus every applicable
// required module) that BuildPlan should materialize actions for.
func resolveSelection(manifest Manifest, platform Platform, selection []string) (map[string]bool, error) {
	effective := map[string]bool{}

	for _, mod := range manifest.Modules {
		if mod.Required && mod.SupportsPlatform(platform) {
			effective[mod.ID] = true
		}
	}

	for _, id := range selection {
		mod, ok := manifest.ModuleByID(id)
		if !ok {
			return nil, fmt.Errorf("unknown module: %s", id)
		}
		if !mod.SupportsPlatform(platform) {
			return nil, fmt.Errorf("module %s is not supported on %s/%s", id, platform.OS, platform.Desktop)
		}
		effective[id] = true
	}

	return effective, nil
}

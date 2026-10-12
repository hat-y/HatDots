package manifest

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

var allOS = []domain.OS{domain.Linux, domain.Mac, domain.Windows}
var allDesktops = []domain.Desktop{domain.NoDesktop, domain.Omarchy}

// Validate checks structural and cross-module invariants of a parsed
// manifest. repoRoot is the directory modules.toml lives in; link Src
// values are resolved relative to it and must exist.
func Validate(m domain.Manifest, repoRoot string) error {
	if err := validateUniqueIDs(m); err != nil {
		return err
	}
	if err := validateEnumValues(m); err != nil {
		return err
	}
	if err := validateSrcExists(m, repoRoot); err != nil {
		return err
	}
	if err := validateNoDstCollisions(m); err != nil {
		return err
	}
	if err := validateRequiredModulesCoverTheirOS(m); err != nil {
		return err
	}
	return nil
}

func validateUniqueIDs(m domain.Manifest) error {
	seen := map[string]bool{}
	for _, mod := range m.Modules {
		if seen[mod.ID] {
			return fmt.Errorf("duplicate module id: %q", mod.ID)
		}
		seen[mod.ID] = true
	}
	return nil
}

func validateEnumValues(m domain.Manifest) error {
	isValidOS := func(o domain.OS) bool {
		for _, v := range allOS {
			if v == o {
				return true
			}
		}
		return false
	}
	isValidDesktop := func(d domain.Desktop) bool {
		for _, v := range allDesktops {
			if v == d {
				return true
			}
		}
		return false
	}
	for _, mod := range m.Modules {
		for _, o := range mod.OS {
			if !isValidOS(o) {
				return fmt.Errorf("module %s: invalid os value: %q", mod.ID, o)
			}
		}
		for _, d := range mod.Desktop {
			if !isValidDesktop(d) {
				return fmt.Errorf("module %s: invalid desktop value: %q", mod.ID, d)
			}
		}
		for _, l := range mod.Links {
			for _, o := range l.OS {
				if !isValidOS(o) {
					return fmt.Errorf("module %s: link %s: invalid os value: %q", mod.ID, l.Dst, o)
				}
			}
		}
	}
	return nil
}

func validateSrcExists(m domain.Manifest, repoRoot string) error {
	for _, mod := range m.Modules {
		for _, l := range mod.Links {
			if l.Src == "" {
				return fmt.Errorf("module %s: link has an empty src", mod.ID)
			}
			full := filepath.Join(repoRoot, l.Src)
			if _, err := os.Stat(full); err != nil {
				return fmt.Errorf("module %s: link src does not exist in the repo: %s", mod.ID, l.Src)
			}
		}
	}
	return nil
}

// validateNoDstCollisions guards against two different links resolving to
// the same destination on a platform where both would apply. Same-dst
// links are fine as long as their OS/Desktop filters never let both apply
// to the same platform at once (that's exactly how the os.*/omarchy.*
// overlay layers intentionally share one destination name).
func validateNoDstCollisions(m domain.Manifest) error {
	for _, platform := range allPlatforms() {
		bySrc := map[string][]string{} // dst -> owning "module/src" labels
		for _, mod := range m.Modules {
			if !mod.SupportsPlatform(platform) {
				continue
			}
			for _, l := range mod.Links {
				if !l.AppliesTo(platform) {
					continue
				}
				dst := l.ResolveDst(platform.OS)
				label := mod.ID + ":" + l.Src
				bySrc[dst] = append(bySrc[dst], label)
			}
		}
		for dst, labels := range bySrc {
			if len(labels) < 2 {
				continue
			}
			sort.Strings(labels)
			if !allSameSrc(labels) {
				return fmt.Errorf("duplicate link destination %q on %s/%s: %v", dst, platform.OS, platform.Desktop, labels)
			}
		}
	}
	return nil
}

func allSameSrc(labels []string) bool {
	// labels are "moduleID:src"; collisions are only real when the src
	// differs (two modules genuinely fighting over one path). The same
	// module repeating identical src/dst is harmless (and never happens
	// in practice, but isn't worth failing over).
	first := labels[0]
	for _, l := range labels[1:] {
		if l != first {
			return false
		}
	}
	return true
}

func validateRequiredModulesCoverTheirOS(m domain.Manifest) error {
	for _, mod := range m.Modules {
		if !mod.Required || len(mod.OS) == 0 {
			continue
		}
		for _, o := range mod.OS {
			if !moduleHasLinkForOS(mod, o) {
				return fmt.Errorf("required module %s lists os %q but has no link that applies to it", mod.ID, o)
			}
		}
	}
	return nil
}

func moduleHasLinkForOS(mod domain.Module, o domain.OS) bool {
	for _, l := range mod.Links {
		if len(l.OS) == 0 {
			return true
		}
		for _, lo := range l.OS {
			if lo == o {
				return true
			}
		}
	}
	return false
}

func allPlatforms() []domain.Platform {
	var out []domain.Platform
	for _, o := range allOS {
		for _, d := range allDesktops {
			out = append(out, domain.Platform{OS: o, Desktop: d})
		}
	}
	return out
}

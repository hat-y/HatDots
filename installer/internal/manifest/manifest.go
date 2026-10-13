// Package manifest parses and validates the HatDots modules.toml file into
// domain.Manifest.
package manifest

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/BurntSushi/toml"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

type tomlFile struct {
	Modules []tomlModule `toml:"modules"`
}

type tomlModule struct {
	ID                string              `toml:"id"`
	Name              string              `toml:"name"`
	Description       string              `toml:"description"`
	Required          bool                `toml:"required"`
	Default           bool                `toml:"default"`
	NotDefaultDesktop []string            `toml:"not_default_desktop"`
	OS                []string            `toml:"os"`
	Desktop           []string            `toml:"desktop"`
	Packages          map[string][]string `toml:"packages"`
	Casks             map[string][]string `toml:"casks"`
	Links             []tomlLink          `toml:"links"`
	PostInstall       []tomlPostInstall   `toml:"post_install"`
}

type tomlLink struct {
	Src        string   `toml:"src"`
	Dst        string   `toml:"dst"`
	DstLinux   string   `toml:"dst_linux"`
	DstMac     string   `toml:"dst_mac"`
	DstWindows string   `toml:"dst_windows"`
	OS         []string `toml:"os"`
	Desktop    []string `toml:"desktop"`
}

type tomlPostInstall struct {
	Command string   `toml:"command"`
	OS      []string `toml:"os"`
	Desktop []string `toml:"desktop"`
}

// Load reads and parses the modules.toml file at path, then validates it
// against the repository rooted at path's directory (src paths in links
// are repo-relative).
func Load(path string) (domain.Manifest, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return domain.Manifest{}, fmt.Errorf("read manifest: %w", err)
	}
	m, err := Parse(data)
	if err != nil {
		return domain.Manifest{}, err
	}
	repoRoot := filepath.Dir(path)
	if err := Validate(m, repoRoot); err != nil {
		return domain.Manifest{}, err
	}
	return m, nil
}

// Parse converts raw TOML bytes into a domain.Manifest, without touching
// the filesystem (that's Validate's job). It rejects unknown OS/Desktop
// enum values.
func Parse(data []byte) (domain.Manifest, error) {
	var raw tomlFile
	if _, err := toml.Decode(string(data), &raw); err != nil {
		return domain.Manifest{}, fmt.Errorf("decode manifest: %w", err)
	}

	m := domain.Manifest{}
	for _, tm := range raw.Modules {
		mod := domain.Module{
			ID:          tm.ID,
			Name:        tm.Name,
			Description: tm.Description,
			Required:    tm.Required,
			Default:     tm.Default,
		}

		oses, err := parseOSList(tm.OS)
		if err != nil {
			return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
		}
		mod.OS = oses

		desktops, err := parseDesktopList(tm.Desktop)
		if err != nil {
			return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
		}
		mod.Desktop = desktops

		notDefaultDesktops, err := parseDesktopList(tm.NotDefaultDesktop)
		if err != nil {
			return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
		}
		mod.NotDefaultDesktop = notDefaultDesktops

		for _, tl := range tm.Links {
			link, err := parseLink(tl)
			if err != nil {
				return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
			}
			mod.Links = append(mod.Links, link)
		}

		specs, err := parsePackages(tm.Packages, false)
		if err != nil {
			return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
		}
		mod.Packages = append(mod.Packages, specs...)

		caskSpecs, err := parsePackages(tm.Casks, true)
		if err != nil {
			return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
		}
		mod.Packages = append(mod.Packages, caskSpecs...)

		for _, tp := range tm.PostInstall {
			post, err := parsePostInstall(tp)
			if err != nil {
				return domain.Manifest{}, fmt.Errorf("module %s: %w", tm.ID, err)
			}
			mod.PostInstall = append(mod.PostInstall, post)
		}

		m.Modules = append(m.Modules, mod)
	}
	return m, nil
}

func parseLink(tl tomlLink) (domain.Link, error) {
	oses, err := parseOSList(tl.OS)
	if err != nil {
		return domain.Link{}, err
	}
	desktops, err := parseDesktopList(tl.Desktop)
	if err != nil {
		return domain.Link{}, err
	}
	link := domain.Link{Src: tl.Src, Dst: tl.Dst, OS: oses, Desktop: desktops}
	overrides := map[domain.OS]string{}
	if tl.DstLinux != "" {
		overrides[domain.Linux] = tl.DstLinux
	}
	if tl.DstMac != "" {
		overrides[domain.Mac] = tl.DstMac
	}
	if tl.DstWindows != "" {
		overrides[domain.Windows] = tl.DstWindows
	}
	if len(overrides) > 0 {
		link.DstOverrides = overrides
	}
	return link, nil
}

func parsePostInstall(tp tomlPostInstall) (domain.PostInstall, error) {
	oses, err := parseOSList(tp.OS)
	if err != nil {
		return domain.PostInstall{}, err
	}
	desktops, err := parseDesktopList(tp.Desktop)
	if err != nil {
		return domain.PostInstall{}, err
	}
	return domain.PostInstall{Command: tp.Command, OS: oses, Desktop: desktops}, nil
}

func parsePackages(raw map[string][]string, cask bool) ([]domain.PackageSpec, error) {
	if len(raw) == 0 {
		return nil, nil
	}
	// Sort manager keys for deterministic plan ordering across runs.
	keys := make([]string, 0, len(raw))
	for k := range raw {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var specs []domain.PackageSpec
	for _, k := range keys {
		mgr, err := parsePkgManager(k)
		if err != nil {
			return nil, err
		}
		specs = append(specs, domain.PackageSpec{Manager: mgr, Names: raw[k], Cask: cask})
	}
	return specs, nil
}

func parsePkgManager(s string) (domain.PkgManager, error) {
	switch domain.PkgManager(s) {
	case domain.Pacman, domain.AUR, domain.Apt, domain.Dnf, domain.Zypper, domain.Brew, domain.Winget, domain.Scoop:
		return domain.PkgManager(s), nil
	default:
		return "", fmt.Errorf("unknown package manager: %q", s)
	}
}

func parseOSList(raw []string) ([]domain.OS, error) {
	var out []domain.OS
	for _, s := range raw {
		switch domain.OS(s) {
		case domain.Linux, domain.Mac, domain.Windows:
			out = append(out, domain.OS(s))
		default:
			return nil, fmt.Errorf("invalid os value: %q", s)
		}
	}
	return out, nil
}

func parseDesktopList(raw []string) ([]domain.Desktop, error) {
	var out []domain.Desktop
	for _, s := range raw {
		switch domain.Desktop(s) {
		case domain.Omarchy:
			out = append(out, domain.Desktop(s))
		default:
			return nil, fmt.Errorf("invalid desktop value: %q", s)
		}
	}
	return out, nil
}

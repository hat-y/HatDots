// Package domain holds the pure, platform-agnostic core of the HatDots
// installer: module/manifest data types, the planning algorithm, and the
// ports (interfaces) adapters implement. Nothing in this package touches
// the filesystem, the network, or the OS directly.
package domain

// OS identifies a target operating system.
type OS string

const (
	Linux   OS = "linux"
	Mac     OS = "mac"
	Windows OS = "windows"
)

// Desktop identifies an optional desktop environment layered on top of an OS.
// The empty string means "no particular desktop" (desktop-agnostic).
type Desktop string

const (
	NoDesktop Desktop = ""
	Omarchy   Desktop = "omarchy"
)

// PkgManager identifies a package manager capable of installing software.
type PkgManager string

const (
	UnknownPkgManager PkgManager = ""
	Pacman            PkgManager = "pacman"
	AUR               PkgManager = "aur" // yay or paru, see Platform.AURHelper
	Apt               PkgManager = "apt"
	Dnf               PkgManager = "dnf"
	Zypper            PkgManager = "zypper"
	Brew              PkgManager = "brew"
	Winget            PkgManager = "winget"
	Scoop             PkgManager = "scoop"
)

// Platform describes the machine the plan is being built for.
type Platform struct {
	OS         OS
	Desktop    Desktop
	Arch       string
	PkgManager PkgManager
	// AURHelper is the AUR helper binary name ("yay" or "paru"), set only
	// when PkgManager == AUR.
	AURHelper string
	// Env supplies the variables path expansion needs: at minimum "HOME".
	// Windows destinations may also reference "LOCALAPPDATA" etc. Keys are
	// matched without a leading '$'/'%' and without braces.
	Env map[string]string
}

// PackageSpec lists the package names a given manager should install for a
// module. Cask marks a Homebrew cask (relevant only when Manager == Brew).
type PackageSpec struct {
	Manager PkgManager
	Names   []string
	Cask    bool
}

// Link describes one file or directory that a module wants placed on disk.
// Dst (and the OS-specific overrides) may use "~" and "$VAR"/"%VAR%" forms;
// see ExpandPath. OS and Desktop, when non-empty, filter which platforms
// this particular link applies to even when the owning Module itself is
// broader (this is how the os.*/omarchy.*/local.* overlay layers and
// per-OS destination differences are expressed within one module).
type Link struct {
	Src          string
	Dst          string
	DstOverrides map[OS]string
	OS           []OS
	Desktop      []Desktop
}

// ResolveDst returns the destination template for the given OS, honoring
// any per-OS override.
func (l Link) ResolveDst(targetOS OS) string {
	if l.DstOverrides != nil {
		if d, ok := l.DstOverrides[targetOS]; ok {
			return d
		}
	}
	return l.Dst
}

// AppliesTo reports whether this link should be materialized on the given
// platform, applying both its OS and Desktop filters (empty = no filter).
func (l Link) AppliesTo(p Platform) bool {
	if len(l.OS) > 0 && !containsOS(l.OS, p.OS) {
		return false
	}
	if len(l.Desktop) > 0 && !containsDesktop(l.Desktop, p.Desktop) {
		return false
	}
	return true
}

// PostInstall is one declarative, shown-in-the-plan command a module wants
// run after its links/packages are applied (e.g. a LaunchAgent installer).
// Command is interpreted by the caller: either a path relative to the repo
// root (an executable script) or a literal shell command.
type PostInstall struct {
	Command string
	OS      []OS
	Desktop []Desktop
}

// AppliesTo reports whether this post-install step applies to the platform.
func (p PostInstall) AppliesTo(plat Platform) bool {
	if len(p.OS) > 0 && !containsOS(p.OS, plat.OS) {
		return false
	}
	if len(p.Desktop) > 0 && !containsDesktop(p.Desktop, plat.Desktop) {
		return false
	}
	return true
}

// Module is one independently selectable unit of configuration: a logical
// tool or feature (e.g. "nvim", "tmux", "ghostty") together with everything
// needed to install it: packages, links, and optional post-install steps.
type Module struct {
	ID          string
	Name        string
	Description string
	Required    bool
	// Default marks whether this module is pre-selected without an
	// explicit --all/--only (see DefaultSelection) or by an interactive
	// picker (phase 4b).
	Default bool
	// NotDefaultDesktop lists desktops where this module should NOT be
	// default even though Default is true (e.g. a generic-desktop module
	// like "kde" that must not auto-apply on Omarchy, which has its own
	// desktop config). Empty means Default applies on every desktop.
	NotDefaultDesktop []Desktop
	OS                []OS
	Desktop           []Desktop
	Packages          []PackageSpec
	Links             []Link
	PostInstall       []PostInstall
}

// IsDefaultFor reports whether this module should be selected by default
// on platform: it must be platform-compatible, have Default set, and not
// be excluded for platform's desktop via NotDefaultDesktop.
func (m Module) IsDefaultFor(p Platform) bool {
	if !m.Default || !m.SupportsPlatform(p) {
		return false
	}
	return !containsDesktop(m.NotDefaultDesktop, p.Desktop)
}

// SupportsOS reports whether the module declares support for the given OS
// (an empty OS list means "every OS").
func (m Module) SupportsOS(os OS) bool {
	return len(m.OS) == 0 || containsOS(m.OS, os)
}

// SupportsDesktop reports whether the module declares support for the given
// desktop (an empty Desktop list means "any desktop, including none").
func (m Module) SupportsDesktop(d Desktop) bool {
	return len(m.Desktop) == 0 || containsDesktop(m.Desktop, d)
}

// SupportsPlatform reports whether the module applies to the given platform
// at all (both the OS and Desktop filters must pass).
func (m Module) SupportsPlatform(p Platform) bool {
	return m.SupportsOS(p.OS) && m.SupportsDesktop(p.Desktop)
}

// Manifest is the full parsed set of installable modules.
type Manifest struct {
	Modules []Module
}

// ModuleByID returns the module with the given id, or false if none exists.
func (m Manifest) ModuleByID(id string) (Module, bool) {
	for _, mod := range m.Modules {
		if mod.ID == id {
			return mod, true
		}
	}
	return Module{}, false
}

func containsOS(list []OS, want OS) bool {
	for _, v := range list {
		if v == want {
			return true
		}
	}
	return false
}

func containsDesktop(list []Desktop, want Desktop) bool {
	for _, v := range list {
		if v == want {
			return true
		}
	}
	return false
}

// Package platform is the adapter that detects the real operating system,
// desktop environment, Linux distro family, and available package manager.
// It is the one place in the installer allowed to call os.Getenv, read
// /etc/os-release, and probe PATH — everything domain.BuildPlan needs is
// handed to it as plain data instead.
package platform

import (
	"bufio"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

// LookPathFunc resolves a binary name to a path, or returns an error if it
// is not on PATH. It matches exec.LookPath's signature so the real
// detector can pass exec.LookPath directly; tests pass a fake.
type LookPathFunc func(name string) (string, error)

// DetectOS maps the Go runtime's GOOS to our domain.OS enum.
func DetectOS() domain.OS {
	switch runtime.GOOS {
	case "darwin":
		return domain.Mac
	case "windows":
		return domain.Windows
	default:
		return domain.Linux
	}
}

// DetectOmarchy reports domain.Omarchy when home/.local/share/omarchy
// exists, domain.NoDesktop otherwise. home is injectable so tests never
// touch the real $HOME.
func DetectOmarchy(home string) domain.Desktop {
	marker := filepath.Join(home, ".local", "share", "omarchy")
	if info, err := os.Stat(marker); err == nil && info.IsDir() {
		return domain.Omarchy
	}
	return domain.NoDesktop
}

// DetectDistro reads /etc/os-release and returns its ID and ID_LIKE
// fields, used to pick a package manager family on Linux.
func DetectDistro() (id, idLike string, err error) {
	return detectDistroFrom("/etc/os-release")
}

func detectDistroFrom(path string) (id, idLike string, err error) {
	f, err := os.Open(path)
	if err != nil {
		return "", "", err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		key, val, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		val = strings.Trim(val, `"`)
		switch key {
		case "ID":
			id = val
		case "ID_LIKE":
			idLike = val
		}
	}
	return id, idLike, scanner.Err()
}

// DetectPkgManagerFor picks the package manager (and, for pacman, the
// preferred AUR helper) to use on the given OS/distro, probing availability
// with lookup. distroID/distroIDLike are only consulted on Linux; they are
// ignored otherwise (reserved for a future family-based dispatch, e.g.
// preferring dnf vs apt by ID_LIKE rather than raw availability).
func DetectPkgManagerFor(os domain.OS, distroID, distroIDLike string, lookup LookPathFunc) (domain.PkgManager, string) {
	switch os {
	case domain.Mac:
		if has(lookup, "brew") {
			return domain.Brew, ""
		}
		return domain.UnknownPkgManager, ""
	case domain.Windows:
		if has(lookup, "winget") {
			return domain.Winget, ""
		}
		if has(lookup, "scoop") {
			return domain.Scoop, ""
		}
		return domain.UnknownPkgManager, ""
	default: // Linux
		if has(lookup, "pacman") {
			return domain.Pacman, aurHelper(lookup)
		}
		if has(lookup, "apt") {
			return domain.Apt, ""
		}
		if has(lookup, "dnf") {
			return domain.Dnf, ""
		}
		if has(lookup, "zypper") {
			return domain.Zypper, ""
		}
		return domain.UnknownPkgManager, ""
	}
}

// aurHelper returns the preferred AUR helper binary name, preferring paru
// over yay when both are present, or "" when neither is.
func aurHelper(lookup LookPathFunc) string {
	if has(lookup, "paru") {
		return "paru"
	}
	if has(lookup, "yay") {
		return "yay"
	}
	return ""
}

func has(lookup LookPathFunc, name string) bool {
	_, err := lookup(name)
	return err == nil
}

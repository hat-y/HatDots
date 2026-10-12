package platform

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func TestDetectOmarchy_PresentMarkerDir(t *testing.T) {
	home := t.TempDir()
	if err := os.MkdirAll(filepath.Join(home, ".local", "share", "omarchy"), 0o755); err != nil {
		t.Fatal(err)
	}
	if got := DetectOmarchy(home); got != domain.Omarchy {
		t.Errorf("DetectOmarchy = %q, want %q", got, domain.Omarchy)
	}
}

func TestDetectOmarchy_AbsentMarkerDir(t *testing.T) {
	home := t.TempDir()
	if got := DetectOmarchy(home); got != domain.NoDesktop {
		t.Errorf("DetectOmarchy = %q, want no desktop", got)
	}
}

func TestDetectDistro_ReadsOsRelease(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "os-release")
	content := "NAME=\"Arch Linux\"\nID=arch\nID_LIKE=\n"
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	id, idLike, err := detectDistroFrom(path)
	if err != nil {
		t.Fatalf("detectDistroFrom error: %v", err)
	}
	if id != "arch" || idLike != "" {
		t.Errorf("id=%q idLike=%q, want id=arch idLike=\"\"", id, idLike)
	}
}

func TestDetectDistro_IDLikeFallback(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "os-release")
	content := "NAME=\"Manjaro\"\nID=manjaro\nID_LIKE=arch\n"
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	id, idLike, err := detectDistroFrom(path)
	if err != nil {
		t.Fatalf("detectDistroFrom error: %v", err)
	}
	if id != "manjaro" || idLike != "arch" {
		t.Errorf("id=%q idLike=%q, want id=manjaro idLike=arch", id, idLike)
	}
}

func TestDetectPkgManager_PrefersPacmanWithAURHelper(t *testing.T) {
	lookup := fakeLookPath(map[string]bool{"pacman": true, "yay": true})
	mgr, helper := DetectPkgManagerFor(domain.Linux, "arch", "", lookup)
	if mgr != domain.Pacman {
		t.Errorf("mgr = %v, want pacman", mgr)
	}
	if helper != "yay" {
		t.Errorf("helper = %q, want yay", helper)
	}
}

func TestDetectPkgManager_ParuPreferredOverYayWhenBothPresent(t *testing.T) {
	lookup := fakeLookPath(map[string]bool{"pacman": true, "yay": true, "paru": true})
	_, helper := DetectPkgManagerFor(domain.Linux, "arch", "", lookup)
	if helper != "paru" {
		t.Errorf("helper = %q, want paru preferred over yay", helper)
	}
}

func TestDetectPkgManager_FallsBackThroughManagers(t *testing.T) {
	cases := []struct {
		name  string
		avail map[string]bool
		want  domain.PkgManager
	}{
		{"apt", map[string]bool{"apt": true}, domain.Apt},
		{"dnf", map[string]bool{"dnf": true}, domain.Dnf},
		{"zypper", map[string]bool{"zypper": true}, domain.Zypper},
		{"none found", map[string]bool{}, domain.UnknownPkgManager},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			mgr, _ := DetectPkgManagerFor(domain.Linux, "fedora", "", fakeLookPath(tc.avail))
			if mgr != tc.want {
				t.Errorf("mgr = %v, want %v", mgr, tc.want)
			}
		})
	}
}

func TestDetectPkgManager_MacUsesBrew(t *testing.T) {
	mgr, _ := DetectPkgManagerFor(domain.Mac, "", "", fakeLookPath(map[string]bool{"brew": true}))
	if mgr != domain.Brew {
		t.Errorf("mgr = %v, want brew", mgr)
	}
}

func TestDetectPkgManager_WindowsPrefersWingetOverScoop(t *testing.T) {
	mgr, _ := DetectPkgManagerFor(domain.Windows, "", "", fakeLookPath(map[string]bool{"winget": true, "scoop": true}))
	if mgr != domain.Winget {
		t.Errorf("mgr = %v, want winget", mgr)
	}
}

func fakeLookPath(avail map[string]bool) LookPathFunc {
	return func(name string) (string, error) {
		if avail[name] {
			return "/usr/bin/" + name, nil
		}
		return "", os.ErrNotExist
	}
}

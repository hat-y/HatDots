package parity

import (
	"strings"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func TestRealManifest_GentleShellOptionalOnAllOSes(t *testing.T) {
	m := loadRealManifest(t)
	var mod *domain.Module
	for i := range m.Modules {
		if m.Modules[i].ID == "gentle-shell" {
			mod = &m.Modules[i]
		}
	}
	if mod == nil {
		t.Fatal("gentle-shell module missing")
	}
	if mod.Required || mod.Default {
		t.Errorf("gentle-shell required=%v default=%v, want both false", mod.Required, mod.Default)
	}
	if len(mod.OS) != 0 {
		t.Errorf("gentle-shell os filter = %v, want none (all OSes)", mod.OS)
	}

	cases := []struct {
		plat domain.Platform
		want string
	}{
		{domain.Platform{OS: domain.Linux, PkgManager: domain.Pacman, Env: linuxEnv()}, "common/bin/hatdots-install-gentle-shell"},
		{domain.Platform{OS: domain.Mac, PkgManager: domain.Brew, Env: linuxEnv()}, "common/bin/hatdots-install-gentle-shell"},
		{domain.Platform{OS: domain.Windows, PkgManager: domain.Winget, Env: map[string]string{"HOME": "/h", "LOCALAPPDATA": "/h/AppData/Local"}}, "os/windows/scripts/install-gentle-shell.ps1"},
	}
	for _, c := range cases {
		plan, err := domain.BuildPlan(m, c.plat, []string{"gentle-shell"}, alwaysMissingFS{})
		if err != nil {
			t.Fatalf("%s: %v", c.plat.OS, err)
		}
		var posts []string
		for _, a := range plan.Actions {
			if a.ModuleID == "gentle-shell" && a.Kind == domain.ActionPostInstall {
				posts = append(posts, a.Command)
			}
		}
		if len(posts) != 1 || posts[0] != c.want {
			t.Errorf("%s post-install = %v, want [%s]", c.plat.OS, posts, c.want)
		}
	}
}

func TestRealManifest_WindowsCoreToolsHasStarshipBinary(t *testing.T) {
	m := loadRealManifest(t)
	for _, mod := range m.Modules {
		switch mod.ID {
		case "windows-core-tools":
			found := false
			for _, p := range mod.Packages {
				if p.Manager == domain.Winget && strings.Contains(strings.Join(p.Names, ","), "Starship.Starship") {
					found = true
				}
			}
			if !found {
				t.Error("windows-core-tools lacks winget Starship.Starship")
			}
		case "starship":
			if mod.Default {
				t.Error("starship module must stay default=false")
			}
		}
	}
}

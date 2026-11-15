package parity

import (
	"reflect"
	"strings"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

type meetRecSteps struct {
	links    []string // "src -> dst"
	packages []string // "manager[cask]: names"
	posts    []string
}

func meetRecPlan(t *testing.T, plat domain.Platform) meetRecSteps {
	t.Helper()
	plan, err := domain.BuildPlan(loadRealManifest(t), plat, []string{"meet-rec"}, alwaysMissingFS{})
	if err != nil {
		t.Fatalf("BuildPlan(%s): %v", plat.OS, err)
	}
	var s meetRecSteps
	for _, a := range plan.Actions {
		if a.ModuleID != "meet-rec" {
			continue
		}
		switch a.Kind {
		case domain.ActionPostInstall:
			s.posts = append(s.posts, a.Command)
		case domain.ActionPackageInstall:
			kind := string(a.Manager)
			if a.Cask {
				kind += "[cask]"
			}
			s.packages = append(s.packages, kind+": "+strings.Join(a.Packages, ","))
		default:
			if a.Src != "" {
				s.links = append(s.links, a.Src+" -> "+a.Dst)
			}
		}
	}
	return s
}

func TestRealManifest_MeetRecOnLinuxAndMac(t *testing.T) {
	linux := meetRecPlan(t, domain.Platform{OS: domain.Linux, PkgManager: domain.Pacman, Env: linuxEnv()})
	mac := meetRecPlan(t, domain.Platform{OS: domain.Mac, PkgManager: domain.Brew, Env: linuxEnv()})

	for name, s := range map[string]meetRecSteps{"linux": linux, "mac": mac} {
		if len(s.links) != 1 || !strings.HasPrefix(s.links[0], "common/bin/meet-rec -> ") || !strings.HasSuffix(s.links[0], "/.local/bin/meet-rec") {
			t.Errorf("%s links = %v, want common/bin/meet-rec -> ~/.local/bin/meet-rec", name, s.links)
		}
		if !reflect.DeepEqual(s.posts, []string{"common/bin/hatdots-fetch-whisper-models"}) {
			t.Errorf("%s post-install = %v, want the whisper model fetcher", name, s.posts)
		}
	}
	if !reflect.DeepEqual(linux.packages, []string{"pacman: ffmpeg,whisper-cpp,python"}) {
		t.Errorf("linux packages = %v", linux.packages)
	}
	if !reflect.DeepEqual(mac.packages, []string{"brew: ffmpeg,whisper-cpp", "brew[cask]: blackhole-2ch"}) {
		t.Errorf("mac packages = %v", mac.packages)
	}
}

func TestRealManifest_MeetRecNotOnWindows(t *testing.T) {
	m := loadRealManifest(t)
	for _, mod := range m.Modules {
		if mod.ID != "meet-rec" {
			continue
		}
		if !reflect.DeepEqual(mod.OS, []domain.OS{domain.Linux, domain.Mac}) {
			t.Errorf("meet-rec os = %v, want [linux mac]", mod.OS)
		}
		if mod.Required || !mod.Default {
			t.Errorf("meet-rec required=%v default=%v, want optional and default", mod.Required, mod.Default)
		}
		return
	}
	t.Fatal("meet-rec module missing")
}

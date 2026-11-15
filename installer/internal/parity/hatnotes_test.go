package parity

import (
	"reflect"
	"strings"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

func hatNotesSteps(t *testing.T, plat domain.Platform) (links, posts []string) {
	t.Helper()
	plan, err := domain.BuildPlan(loadRealManifest(t), plat, []string{"hatnotes"}, alwaysMissingFS{})
	if err != nil {
		t.Fatalf("BuildPlan(%s): %v", plat.OS, err)
	}
	for _, a := range plan.Actions {
		if a.ModuleID != "hatnotes" {
			continue
		}
		if a.Kind == domain.ActionPostInstall {
			posts = append(posts, a.Command)
		} else if a.Src != "" {
			links = append(links, a.Src+" -> "+a.Dst)
		}
	}
	return links, posts
}

func TestRealManifest_HatNotesPerOS(t *testing.T) {
	cases := []struct {
		plat      domain.Platform
		links     []string // src prefix/dst suffix pairs
		wantPosts []string
	}{
		{
			domain.Platform{OS: domain.Linux, PkgManager: domain.Pacman, Env: linuxEnv()},
			[]string{
				"common/bin/hatnotes-autosync -> /home/u/.local/bin/hatnotes-autosync",
				"os/linux/systemd/hatnotes-autosync.service -> /home/u/.config/systemd/user/hatnotes-autosync.service",
				"os/linux/systemd/hatnotes-autosync.timer -> /home/u/.config/systemd/user/hatnotes-autosync.timer",
			},
			[]string{
				"common/bin/hatdots-clone-hatnotes",
				`if ! systemctl --user show-environment >/dev/null 2>&1; then echo "systemctl --user unavailable (no user bus); skipping hatnotes-autosync timer"; else systemctl --user daemon-reload && systemctl --user enable --now hatnotes-autosync.timer; fi`,
			},
		},
		{
			domain.Platform{OS: domain.Mac, PkgManager: domain.Brew, Env: macEnv()},
			[]string{"common/bin/hatnotes-autosync -> /Users/u/.local/bin/hatnotes-autosync"},
			[]string{"common/bin/hatdots-clone-hatnotes", "os/mac/hatnotes/install.sh"},
		},
		{
			domain.Platform{OS: domain.Windows, PkgManager: domain.Winget, Env: windowsEnv()},
			nil,
			[]string{"os/windows/scripts/install-hatnotes.ps1"},
		},
	}
	for _, c := range cases {
		links, posts := hatNotesSteps(t, c.plat)
		if len(links) != len(c.links) {
			t.Errorf("%s links = %v, want %v", c.plat.OS, links, c.links)
		} else {
			for i := range links {
				if strings.ReplaceAll(links[i], `\`, "/") != c.links[i] {
					t.Errorf("%s link[%d] = %q, want %q", c.plat.OS, i, links[i], c.links[i])
				}
			}
		}
		if !reflect.DeepEqual(posts, c.wantPosts) {
			t.Errorf("%s post-install = %v, want %v", c.plat.OS, posts, c.wantPosts)
		}
	}
}

func TestRealManifest_HatNotesDefaultOptionalAllOSes(t *testing.T) {
	for _, mod := range loadRealManifest(t).Modules {
		if mod.ID != "hatnotes" {
			continue
		}
		if mod.Required || !mod.Default {
			t.Errorf("hatnotes required=%v default=%v, want optional and default", mod.Required, mod.Default)
		}
		if len(mod.OS) != 0 {
			t.Errorf("hatnotes os filter = %v, want none (all OSes)", mod.OS)
		}
		return
	}
	t.Fatal("hatnotes module missing")
}

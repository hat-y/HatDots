package parity

import (
	"strings"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

// herdrInstallSteps returns every package-install or post-install action the
// real manifest plans for the herdr module on platform.
func herdrInstallSteps(t *testing.T, platform domain.Platform) []domain.Action {
	t.Helper()
	m := loadRealManifest(t)
	plan, err := domain.BuildPlan(m, platform, []string{"herdr"}, alwaysMissingFS{})
	if err != nil {
		t.Fatalf("BuildPlan(%+v): %v", platform, err)
	}
	var steps []domain.Action
	for _, a := range plan.Actions {
		if a.ModuleID != "herdr" {
			continue
		}
		if a.Kind == domain.ActionPackageInstall || a.Kind == domain.ActionPostInstall {
			steps = append(steps, a)
		}
	}
	return steps
}

// Herdr ships in Omarchy's own pacman repo (`omarchy`), not in the standard
// Arch repos, so only an Omarchy desktop may try to pacman-install it.
func TestRealManifest_HerdrInstalledFromPacmanOnOmarchy(t *testing.T) {
	steps := herdrInstallSteps(t, domain.Platform{OS: domain.Linux, Desktop: domain.Omarchy, PkgManager: domain.Pacman, Env: linuxEnv()})
	if len(steps) != 1 || steps[0].Kind != domain.ActionPostInstall {
		t.Fatalf("herdr install steps on omarchy = %+v, want exactly one post-install", steps)
	}
	cmd := steps[0].Command
	if !strings.Contains(cmd, "command -v herdr") || !strings.Contains(cmd, "pacman -S --needed herdr") {
		t.Errorf("post-install = %q, want it to skip when herdr is on PATH and otherwise pacman-install it", cmd)
	}
}

func TestRealManifest_HerdrNotInstalledOnPlainLinux(t *testing.T) {
	steps := herdrInstallSteps(t, domain.Platform{OS: domain.Linux, Desktop: domain.NoDesktop, PkgManager: domain.Pacman, Env: linuxEnv()})
	if len(steps) != 0 {
		t.Errorf("herdr install steps without omarchy = %+v, want none (no standard-repo package exists)", steps)
	}
}

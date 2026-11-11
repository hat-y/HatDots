package tui

import (
	"reflect"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
	"github.com/hat-y/HatDots/installer/internal/pkg"
)

// probeExecutor answers every Probe with a fixed pacman -T result and
// fails the test if anything is actually Run.
type probeExecutor struct {
	t    *testing.T
	out  string
	code int
}

func (p probeExecutor) Run(cmd pkg.Command) error {
	p.t.Fatalf("TerminalCommands must not run anything, ran %+v", cmd)
	return nil
}

func (p probeExecutor) Probe(pkg.Command) (string, int, error) { return p.out, p.code, nil }

func pacmanAction(names ...string) domain.Action {
	return domain.Action{Kind: domain.ActionPackageInstall, ModuleID: "nvim", Manager: domain.Pacman, Packages: names}
}

func TestAppPort_TerminalCommands_SkipsPackagesAlreadyProvided(t *testing.T) {
	port := AppPort{Exec: probeExecutor{t: t, code: 0}}
	if got := port.TerminalCommands(pacmanAction("neovim")); got != nil {
		t.Errorf("got %+v, want nil (neovim already provided, e.g. by neovim-git)", got)
	}
}

func TestAppPort_TerminalCommands_InstallsOnlyMissingPackages(t *testing.T) {
	port := AppPort{Exec: probeExecutor{t: t, code: 127, out: "newsboat\n"}}
	got := port.TerminalCommands(pacmanAction("neovim", "newsboat"))
	want := []pkg.Command{{Name: "sudo", Args: []string{"pacman", "-S", "--needed", "newsboat"}}}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %+v, want %+v", got, want)
	}
}

package pkg

import (
	"errors"
	"reflect"
	"testing"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

var errExecFailed = errors.New("exec failed")

func TestBuildCommands(t *testing.T) {
	cases := []struct {
		name      string
		manager   domain.PkgManager
		names     []string
		cask      bool
		aurHelper string
		want      []Command
		wantErr   bool
	}{
		{
			name:    "pacman",
			manager: domain.Pacman,
			names:   []string{"neovim", "tmux"},
			want:    []Command{{Name: "sudo", Args: []string{"pacman", "-S", "--needed", "neovim", "tmux"}}},
		},
		{
			name:      "aur via yay",
			manager:   domain.AUR,
			names:     []string{"ghostty-git"},
			aurHelper: "yay",
			want:      []Command{{Name: "yay", Args: []string{"-S", "--needed", "ghostty-git"}}},
		},
		{
			name:    "aur without a helper is an error",
			manager: domain.AUR,
			names:   []string{"ghostty-git"},
			wantErr: true,
		},
		{
			name:    "apt",
			manager: domain.Apt,
			names:   []string{"neovim"},
			want:    []Command{{Name: "sudo", Args: []string{"apt", "install", "-y", "neovim"}}},
		},
		{
			name:    "dnf",
			manager: domain.Dnf,
			names:   []string{"neovim"},
			want:    []Command{{Name: "sudo", Args: []string{"dnf", "install", "-y", "neovim"}}},
		},
		{
			name:    "zypper",
			manager: domain.Zypper,
			names:   []string{"neovim"},
			want:    []Command{{Name: "sudo", Args: []string{"zypper", "install", "-y", "neovim"}}},
		},
		{
			name:    "brew formula",
			manager: domain.Brew,
			names:   []string{"neovim", "tmux"},
			want:    []Command{{Name: "brew", Args: []string{"install", "neovim", "tmux"}}},
		},
		{
			name:    "brew cask",
			manager: domain.Brew,
			names:   []string{"ghostty"},
			cask:    true,
			want:    []Command{{Name: "brew", Args: []string{"install", "--cask", "ghostty"}}},
		},
		{
			name:    "winget issues one command per package id",
			manager: domain.Winget,
			names:   []string{"Neovim.Neovim", "Starship.Starship"},
			want: []Command{
				{Name: "winget", Args: []string{"install", "--id", "Neovim.Neovim", "-e"}},
				{Name: "winget", Args: []string{"install", "--id", "Starship.Starship", "-e"}},
			},
		},
		{
			name:    "scoop",
			manager: domain.Scoop,
			names:   []string{"eza"},
			want:    []Command{{Name: "scoop", Args: []string{"install", "eza"}}},
		},
		{
			name:    "empty names is an error",
			manager: domain.Pacman,
			names:   nil,
			wantErr: true,
		},
		{
			name:    "unknown manager is an error",
			manager: domain.UnknownPkgManager,
			names:   []string{"neovim"},
			wantErr: true,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := BuildCommands(tc.manager, tc.names, tc.cask, tc.aurHelper)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("expected an error, got commands %+v", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("BuildCommands error: %v", err)
			}
			if !reflect.DeepEqual(got, tc.want) {
				t.Errorf("got %+v, want %+v", got, tc.want)
			}
		})
	}
}

type fakeExecutor struct {
	ran []Command
	err error

	probed     []Command
	probeOut   string
	probeCode  int
	probeError error
}

func (f *fakeExecutor) Run(cmd Command) error {
	f.ran = append(f.ran, cmd)
	return f.err
}

func (f *fakeExecutor) Probe(cmd Command) (string, int, error) {
	f.probed = append(f.probed, cmd)
	return f.probeOut, f.probeCode, f.probeError
}

func TestUnsatisfied_PacmanEverythingProvided(t *testing.T) {
	// pacman -T exits 0 when every dependency is satisfied, including
	// through `provides` (e.g. neovim-git satisfies neovim).
	exec := &fakeExecutor{probeCode: 0}
	got, err := Unsatisfied(exec, domain.Pacman, []string{"neovim", "fish"})
	if err != nil {
		t.Fatalf("Unsatisfied error: %v", err)
	}
	if len(got) != 0 {
		t.Errorf("got %v, want nothing missing", got)
	}
	want := []Command{{Name: "pacman", Args: []string{"-T", "neovim", "fish"}}}
	if !reflect.DeepEqual(exec.probed, want) {
		t.Errorf("probed %+v, want %+v", exec.probed, want)
	}
}

func TestUnsatisfied_PacmanSomeMissing(t *testing.T) {
	// pacman -T exits 127 and prints each unsatisfied dependency per line.
	exec := &fakeExecutor{probeCode: 127, probeOut: "newsboat\n"}
	got, err := Unsatisfied(exec, domain.Pacman, []string{"neovim", "newsboat"})
	if err != nil {
		t.Fatalf("Unsatisfied error: %v", err)
	}
	if want := []string{"newsboat"}; !reflect.DeepEqual(got, want) {
		t.Errorf("got %v, want %v", got, want)
	}
}

func TestUnsatisfied_PacmanUnexpectedExitIsAnError(t *testing.T) {
	exec := &fakeExecutor{probeCode: 1, probeOut: "error: something broke\n"}
	if _, err := Unsatisfied(exec, domain.Pacman, []string{"neovim"}); err == nil {
		t.Fatal("expected an error for an unexpected pacman -T exit code")
	}
}

func TestUnsatisfied_PacmanProbeStartFailureIsAnError(t *testing.T) {
	exec := &fakeExecutor{probeError: errExecFailed}
	if _, err := Unsatisfied(exec, domain.Pacman, []string{"neovim"}); err == nil {
		t.Fatal("expected an error when pacman -T cannot run")
	}
}

func TestUnsatisfied_OtherManagersReturnNamesUnchanged(t *testing.T) {
	exec := &fakeExecutor{}
	names := []string{"Git.Git", "Neovim.Neovim"}
	got, err := Unsatisfied(exec, domain.Winget, names)
	if err != nil {
		t.Fatalf("Unsatisfied error: %v", err)
	}
	if !reflect.DeepEqual(got, names) {
		t.Errorf("got %v, want %v", got, names)
	}
	if len(exec.probed) != 0 {
		t.Errorf("probed %+v, want no probe for winget", exec.probed)
	}
}

func TestInstall_PacmanSkipsWhenEverythingIsProvided(t *testing.T) {
	exec := &fakeExecutor{probeCode: 0}
	if err := Install(exec, domain.Pacman, []string{"neovim"}, false, ""); err != nil {
		t.Fatalf("Install error: %v", err)
	}
	if len(exec.ran) != 0 {
		t.Errorf("ran %+v, want nothing (neovim already provided)", exec.ran)
	}
}

func TestInstall_PacmanInstallsOnlyMissingPackages(t *testing.T) {
	exec := &fakeExecutor{probeCode: 127, probeOut: "newsboat\n"}
	if err := Install(exec, domain.Pacman, []string{"neovim", "newsboat"}, false, ""); err != nil {
		t.Fatalf("Install error: %v", err)
	}
	want := []Command{{Name: "sudo", Args: []string{"pacman", "-S", "--needed", "newsboat"}}}
	if !reflect.DeepEqual(exec.ran, want) {
		t.Errorf("ran %+v, want %+v", exec.ran, want)
	}
}

func TestInstall_RunsEveryBuiltCommand(t *testing.T) {
	exec := &fakeExecutor{}
	err := Install(exec, domain.Winget, []string{"Git.Git", "Neovim.Neovim"}, false, "")
	if err != nil {
		t.Fatalf("Install error: %v", err)
	}
	if len(exec.ran) != 2 {
		t.Fatalf("ran %d commands, want 2: %+v", len(exec.ran), exec.ran)
	}
}

func TestInstall_StopsOnFirstError(t *testing.T) {
	wantErr := errExecFailed
	exec := &fakeExecutor{err: wantErr}
	err := Install(exec, domain.Winget, []string{"A.A", "B.B"}, false, "")
	if err == nil {
		t.Fatal("expected an error")
	}
	if len(exec.ran) != 1 {
		t.Fatalf("ran %d commands after a failure, want exactly 1 (stop on first error)", len(exec.ran))
	}
}

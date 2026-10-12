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
}

func (f *fakeExecutor) Run(cmd Command) error {
	f.ran = append(f.ran, cmd)
	return f.err
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

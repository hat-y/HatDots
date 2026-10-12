// Package pkg is the adapter that turns a package-install action into the
// concrete command line(s) a package manager understands, and runs them
// through an injectable Executor port (so tests never spawn a real
// process, and dry-run just prints without an Executor at all).
package pkg

import (
	"fmt"

	"github.com/hat-y/HatDots/installer/internal/domain"
)

// Command is one argv to run: Name is the program, Args its arguments.
type Command struct {
	Name string
	Args []string
}

// Executor runs one Command. The real implementation execs it; tests use
// a fake that just records what it was asked to run.
type Executor interface {
	Run(cmd Command) error
}

// BuildCommands returns the command(s) that install names via manager.
// cask only affects Brew (adds --cask). aurHelper names the AUR helper
// binary ("yay" or "paru") and is required when manager is domain.AUR.
func BuildCommands(manager domain.PkgManager, names []string, cask bool, aurHelper string) ([]Command, error) {
	if len(names) == 0 {
		return nil, fmt.Errorf("pkg: no package names given for %s", manager)
	}

	switch manager {
	case domain.Pacman:
		return []Command{{Name: "sudo", Args: append([]string{"pacman", "-S", "--needed"}, names...)}}, nil
	case domain.AUR:
		if aurHelper == "" {
			return nil, fmt.Errorf("pkg: AUR packages requested but no AUR helper (yay/paru) is available")
		}
		return []Command{{Name: aurHelper, Args: append([]string{"-S", "--needed"}, names...)}}, nil
	case domain.Apt:
		return []Command{{Name: "sudo", Args: append([]string{"apt", "install", "-y"}, names...)}}, nil
	case domain.Dnf:
		return []Command{{Name: "sudo", Args: append([]string{"dnf", "install", "-y"}, names...)}}, nil
	case domain.Zypper:
		return []Command{{Name: "sudo", Args: append([]string{"zypper", "install", "-y"}, names...)}}, nil
	case domain.Brew:
		args := []string{"install"}
		if cask {
			args = append(args, "--cask")
		}
		args = append(args, names...)
		return []Command{{Name: "brew", Args: args}}, nil
	case domain.Winget:
		cmds := make([]Command, 0, len(names))
		for _, n := range names {
			cmds = append(cmds, Command{Name: "winget", Args: []string{"install", "--id", n, "-e"}})
		}
		return cmds, nil
	case domain.Scoop:
		return []Command{{Name: "scoop", Args: append([]string{"install"}, names...)}}, nil
	default:
		return nil, fmt.Errorf("pkg: unknown package manager: %q", manager)
	}
}

// Install builds and runs, in order, every command needed to install
// names via manager, stopping at the first failure.
func Install(exec Executor, manager domain.PkgManager, names []string, cask bool, aurHelper string) error {
	cmds, err := BuildCommands(manager, names, cask, aurHelper)
	if err != nil {
		return err
	}
	for _, cmd := range cmds {
		if err := exec.Run(cmd); err != nil {
			return fmt.Errorf("pkg: %s %v: %w", cmd.Name, cmd.Args, err)
		}
	}
	return nil
}

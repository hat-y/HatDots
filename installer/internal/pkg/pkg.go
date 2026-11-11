// Package pkg is the adapter that turns a package-install action into the
// concrete command line(s) a package manager understands, and runs them
// through an injectable Executor port (so tests never spawn a real
// process, and dry-run just prints without an Executor at all).
package pkg

import (
	"fmt"
	"strings"

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
	// Run executes cmd interactively (stdio wired to the installer's).
	Run(cmd Command) error
	// Probe executes cmd silently and reports its stdout and exit code.
	// err is non-nil only when cmd could not be started at all; a
	// non-zero exit is reported through exitCode, not err.
	Probe(cmd Command) (stdout string, exitCode int, err error)
}

// pacmanUnsatisfiedExit is the exit code `pacman -T` uses when at least
// one dependency is not satisfied (it then prints each one on stdout).
const pacmanUnsatisfiedExit = 127

// Unsatisfied returns the subset of names the system does not already
// provide, in their original order. For pacman-family managers it asks
// `pacman -T`, which resolves `provides` — so an installed neovim-git
// satisfies neovim and is never offered for replacement by the repo
// package. Every other manager returns names unchanged (their install
// commands are already idempotent).
func Unsatisfied(exec Executor, manager domain.PkgManager, names []string) ([]string, error) {
	if manager != domain.Pacman && manager != domain.AUR {
		return names, nil
	}
	cmd := Command{Name: "pacman", Args: append([]string{"-T"}, names...)}
	out, code, err := exec.Probe(cmd)
	if err != nil {
		return nil, fmt.Errorf("pkg: %s %v: %w", cmd.Name, cmd.Args, err)
	}
	switch code {
	case 0:
		return nil, nil
	case pacmanUnsatisfiedExit:
		missing := strings.Fields(out)
		if len(missing) == 0 {
			return nil, fmt.Errorf("pkg: pacman -T exited %d without naming any package", code)
		}
		return missing, nil
	default:
		return nil, fmt.Errorf("pkg: pacman -T exited %d: %s", code, strings.TrimSpace(out))
	}
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

// Install builds and runs, in order, every command needed to install the
// names manager does not already provide (see Unsatisfied), stopping at
// the first failure. It runs nothing when every name is already provided.
func Install(exec Executor, manager domain.PkgManager, names []string, cask bool, aurHelper string) error {
	missing, err := Unsatisfied(exec, manager, names)
	if err != nil {
		return err
	}
	if len(missing) == 0 {
		return nil
	}
	cmds, err := BuildCommands(manager, missing, cask, aurHelper)
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

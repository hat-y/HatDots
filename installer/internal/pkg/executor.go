package pkg

import (
	"os"
	"os/exec"
)

// RealExecutor runs a Command as a real child process, with stdio wired to
// the installer's own so package manager prompts (sudo password, [Y/n])
// work interactively.
type RealExecutor struct{}

func (RealExecutor) Run(cmd Command) error {
	c := exec.Command(cmd.Name, cmd.Args...)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return c.Run()
}

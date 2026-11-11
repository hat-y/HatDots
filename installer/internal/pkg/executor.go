package pkg

import (
	"bytes"
	"errors"
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

// Probe runs cmd without a terminal, capturing stdout. A non-zero exit is
// returned as exitCode with a nil error; err is only for start failures.
func (RealExecutor) Probe(cmd Command) (string, int, error) {
	var out bytes.Buffer
	c := exec.Command(cmd.Name, cmd.Args...)
	c.Stdout = &out
	err := c.Run()
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return out.String(), exitErr.ExitCode(), nil
	}
	if err != nil {
		return "", 0, err
	}
	return out.String(), 0, nil
}

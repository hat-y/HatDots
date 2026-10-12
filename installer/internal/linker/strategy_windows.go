//go:build windows

package linker

import (
	"fmt"
	"os"
	"os/exec"
)

// defaultDirStrategy on Windows tries a real symlink first (works when the
// process has SeCreateSymbolicLinkPrivilege or Developer Mode is on) and
// falls back to an NTFS junction via `cmd /c mklink /J`, which needs no
// elevated privilege for directories.
func defaultDirStrategy() dirLinkStrategy {
	return windowsDirStrategy{symlink: os.Symlink, mklinkJunction: runMklinkJunction}
}

func runMklinkJunction(src, dst string) error {
	cmd := exec.Command("cmd", "/c", "mklink", "/J", dst, src)
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("mklink /J %s %s: %w: %s", dst, src, err, out)
	}
	return nil
}

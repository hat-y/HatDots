//go:build !windows

package linker

import "os"

// defaultDirStrategy on Unix-like systems is always a plain symlink.
func defaultDirStrategy() dirLinkStrategy {
	return symlinkStrategy{symlink: os.Symlink}
}

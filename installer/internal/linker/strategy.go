package linker

// dirLinkStrategy creates a link to a directory. On Unix-like systems a
// plain symlink always suffices; Windows needs a fallback because
// symlinks there require either admin rights or Developer Mode.
type dirLinkStrategy interface {
	link(src, dst string) error
}

// symlinkStrategy is the default (Linux/macOS): always symlink.
type symlinkStrategy struct {
	symlink func(src, dst string) error
}

func (s symlinkStrategy) link(src, dst string) error {
	return s.symlink(src, dst)
}

// windowsDirStrategy tries a symlink first and falls back to an NTFS
// junction (`cmd /c mklink /J`) when that fails — the one fallback the
// phase-4a spec calls for. Both operations are injected functions so this
// decision logic is exercised by a plain Linux test, without needing a
// real Windows machine or a build tag.
type windowsDirStrategy struct {
	symlink        func(src, dst string) error
	mklinkJunction func(src, dst string) error
}

func (w windowsDirStrategy) link(src, dst string) error {
	if err := w.symlink(src, dst); err == nil {
		return nil
	}
	return w.mklinkJunction(src, dst)
}

package linker

import (
	"errors"
	"testing"
)

func TestWindowsDirStrategy_SymlinkSucceeds_JunctionNeverCalled(t *testing.T) {
	junctionCalled := false
	s := windowsDirStrategy{
		symlink:        func(src, dst string) error { return nil },
		mklinkJunction: func(src, dst string) error { junctionCalled = true; return nil },
	}
	if err := s.link("src", "dst"); err != nil {
		t.Fatalf("link error: %v", err)
	}
	if junctionCalled {
		t.Error("mklinkJunction was called even though symlink succeeded")
	}
}

func TestWindowsDirStrategy_SymlinkFails_FallsBackToJunction(t *testing.T) {
	junctionCalled := false
	s := windowsDirStrategy{
		symlink:        func(src, dst string) error { return errors.New("no privilege") },
		mklinkJunction: func(src, dst string) error { junctionCalled = true; return nil },
	}
	if err := s.link("src", "dst"); err != nil {
		t.Fatalf("link error: %v", err)
	}
	if !junctionCalled {
		t.Error("mklinkJunction was never called after symlink failed")
	}
}

func TestWindowsDirStrategy_BothFail_ReturnsJunctionError(t *testing.T) {
	wantErr := errors.New("junction also failed")
	s := windowsDirStrategy{
		symlink:        func(src, dst string) error { return errors.New("no privilege") },
		mklinkJunction: func(src, dst string) error { return wantErr },
	}
	if err := s.link("src", "dst"); err != wantErr {
		t.Fatalf("link error = %v, want %v", err, wantErr)
	}
}

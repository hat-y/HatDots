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

func TestWindowsDirStrategy_RejectsShellMetacharactersBeforeInvokingMklink(t *testing.T) {
	cases := []struct {
		name     string
		src, dst string
	}{
		{"ampersand in dst", "C:\\src", "C:\\dst & calc.exe"},
		{"pipe in src", "C:\\src | whoami", "C:\\dst"},
		{"percent in dst", "C:\\src", "C:\\dst\\%TEMP%"},
		{"caret in src", "C:\\src^", "C:\\dst"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			junctionCalled := false
			s := windowsDirStrategy{
				symlink:        func(src, dst string) error { return errors.New("no privilege") },
				mklinkJunction: func(src, dst string) error { junctionCalled = true; return nil },
			}
			err := s.link(tc.src, tc.dst)
			if err == nil {
				t.Fatal("expected an error for a path containing a cmd.exe shell metacharacter")
			}
			if junctionCalled {
				t.Error("mklinkJunction was invoked despite an unsafe path; the check must run first")
			}
		})
	}
}

func TestWindowsDirStrategy_PlainPathsStillReachMklink(t *testing.T) {
	junctionCalled := false
	s := windowsDirStrategy{
		symlink:        func(src, dst string) error { return errors.New("no privilege") },
		mklinkJunction: func(src, dst string) error { junctionCalled = true; return nil },
	}
	if err := s.link("C:\\Users\\u\\repo\\common\\nvim", "C:\\Users\\u\\AppData\\Local\\nvim"); err != nil {
		t.Fatalf("link error: %v", err)
	}
	if !junctionCalled {
		t.Error("an ordinary path must still reach mklinkJunction")
	}
}

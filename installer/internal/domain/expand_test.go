package domain

import "testing"

func TestExpandPath(t *testing.T) {
	env := map[string]string{
		"HOME":            "/home/hat",
		"LOCALAPPDATA":    "C:\\Users\\hat\\AppData\\Local",
		"XDG_CONFIG_HOME": "/home/hat/.config",
	}

	cases := []struct {
		name string
		path string
		want string
	}{
		{"tilde prefix", "~/.config/nvim", "/home/hat/.config/nvim"},
		{"bare tilde", "~", "/home/hat"},
		{"dollar var", "$HOME/.zshrc", "/home/hat/.zshrc"},
		{"braced dollar var", "${HOME}/.zshrc", "/home/hat/.zshrc"},
		{"percent var windows style", "%LOCALAPPDATA%\\nvim", "C:\\Users\\hat\\AppData\\Local\\nvim"},
		{"no placeholder", "common/nvim", "common/nvim"},
		{"xdg var", "$XDG_CONFIG_HOME/starship.toml", "/home/hat/.config/starship.toml"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ExpandPath(tc.path, env)
			if err != nil {
				t.Fatalf("ExpandPath(%q) unexpected error: %v", tc.path, err)
			}
			if got != tc.want {
				t.Errorf("ExpandPath(%q) = %q, want %q", tc.path, got, tc.want)
			}
		})
	}
}

func TestExpandPath_MissingVarErrors(t *testing.T) {
	_, err := ExpandPath("$NOPE/x", map[string]string{"HOME": "/home/hat"})
	if err == nil {
		t.Fatal("ExpandPath with an unset variable reference should error, not silently leave a placeholder or substitute nothing")
	}
}

func TestExpandPath_EmptyHOMEErrorsOnTilde(t *testing.T) {
	// The real-world bug this guards against: an empty-but-present HOME
	// used to turn "~/x" into "/x" (a root-relative path) instead of
	// failing loudly.
	_, err := ExpandPath("~/.config/nvim", map[string]string{"HOME": ""})
	if err == nil {
		t.Fatal("ExpandPath with an empty HOME should error, not silently produce a root path")
	}
}

func TestExpandPath_AbsentHOMEErrorsOnTilde(t *testing.T) {
	_, err := ExpandPath("~/.config/nvim", map[string]string{})
	if err == nil {
		t.Fatal("ExpandPath with no HOME at all should error on a ~ reference")
	}
}

func TestExpandPath_EmptyVarValueErrors(t *testing.T) {
	_, err := ExpandPath("$LOCALAPPDATA/nvim", map[string]string{"HOME": "/home/hat", "LOCALAPPDATA": ""})
	if err == nil {
		t.Fatal("ExpandPath with an empty-but-present variable should error, not substitute an empty string")
	}
}

func TestExpandPath_NoPlaceholderNeverErrors(t *testing.T) {
	got, err := ExpandPath("common/nvim", map[string]string{})
	if err != nil {
		t.Fatalf("a path with no placeholder at all must never error: %v", err)
	}
	if got != "common/nvim" {
		t.Errorf("got %q, want unchanged", got)
	}
}

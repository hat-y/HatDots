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
			got := ExpandPath(tc.path, env)
			if got != tc.want {
				t.Errorf("ExpandPath(%q) = %q, want %q", tc.path, got, tc.want)
			}
		})
	}
}

func TestExpandPathMissingVarLeavesPlaceholder(t *testing.T) {
	got := ExpandPath("$NOPE/x", map[string]string{"HOME": "/home/hat"})
	if got != "$NOPE/x" {
		t.Errorf("ExpandPath with missing var = %q, want placeholder left untouched", got)
	}
}

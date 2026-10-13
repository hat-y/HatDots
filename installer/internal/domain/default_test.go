package domain

import (
	"reflect"
	"testing"
)

func TestModule_IsDefaultFor(t *testing.T) {
	cases := []struct {
		name    string
		mod     Module
		desktop Desktop
		want    bool
	}{
		{
			name:    "default module with no exceptions is default on no desktop",
			mod:     Module{ID: "tmux", OS: []OS{Linux}, Default: true},
			desktop: NoDesktop,
			want:    true,
		},
		{
			name:    "non-default module is never default",
			mod:     Module{ID: "starship", Default: false},
			desktop: NoDesktop,
			want:    false,
		},
		{
			name:    "kde is default with no desktop",
			mod:     Module{ID: "kde", OS: []OS{Linux}, Default: true, NotDefaultDesktop: []Desktop{Omarchy}},
			desktop: NoDesktop,
			want:    true,
		},
		{
			name:    "kde is NOT default on omarchy",
			mod:     Module{ID: "kde", OS: []OS{Linux}, Default: true, NotDefaultDesktop: []Desktop{Omarchy}},
			desktop: Omarchy,
			want:    false,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			platform := Platform{OS: Linux, Desktop: tc.desktop, Env: testEnv()}
			if got := tc.mod.IsDefaultFor(platform); got != tc.want {
				t.Errorf("IsDefaultFor(desktop=%q) = %v, want %v", tc.desktop, got, tc.want)
			}
		})
	}
}

func TestModule_IsDefaultFor_PlatformIncompatibleIsNeverDefault(t *testing.T) {
	mod := Module{ID: "wezterm", OS: []OS{Windows}, Default: true}
	platform := Platform{OS: Linux, Desktop: NoDesktop, Env: testEnv()}
	if mod.IsDefaultFor(platform) {
		t.Error("a module incompatible with the platform must never be default on it")
	}
}

func TestDefaultSelection_PerDesktop(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "tmux", OS: []OS{Linux}, Default: true},
		{ID: "kde", OS: []OS{Linux}, Default: true, NotDefaultDesktop: []Desktop{Omarchy}},
		{ID: "hypr", OS: []OS{Linux}, Desktop: []Desktop{Omarchy}, Default: true},
		{ID: "starship", Default: false},
	}}

	noDesktop := DefaultSelection(manifest, Platform{OS: Linux, Desktop: NoDesktop, Env: testEnv()})
	if !reflect.DeepEqual(noDesktop, []string{"tmux", "kde"}) {
		t.Errorf("no-desktop default selection = %v, want [tmux kde]", noDesktop)
	}

	omarchy := DefaultSelection(manifest, Platform{OS: Linux, Desktop: Omarchy, Env: testEnv()})
	if !reflect.DeepEqual(omarchy, []string{"tmux", "hypr"}) {
		t.Errorf("omarchy default selection = %v, want [tmux hypr] (kde excluded, hypr included)", omarchy)
	}
}

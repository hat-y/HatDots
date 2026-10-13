package domain

import (
	"reflect"
	"testing"
)

// fakeFS is an in-memory FSState fake for pure, disk-free domain tests.
type fakeFS struct {
	// states maps a destination path to the state BuildPlan should see.
	states map[string]DstState
}

func (f fakeFS) Inspect(dst, expandedSrc string) (DstState, error) {
	if s, ok := f.states[dst]; ok {
		return s, nil
	}
	return DstMissing, nil
}

func testEnv() map[string]string {
	return map[string]string{"HOME": "/home/hat"}
}

func TestBuildPlan_RequiredModuleAlwaysIncluded(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "nvim", Required: true, Links: []Link{{Src: "common/nvim", Dst: "~/.config/nvim"}}},
	}}
	platform := Platform{OS: Linux, Env: testEnv()}

	plan, err := BuildPlan(manifest, platform, nil, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 1 {
		t.Fatalf("got %d actions, want 1: %+v", len(plan.Actions), plan.Actions)
	}
	want := Action{Kind: ActionLinkCreate, ModuleID: "nvim", Src: "common/nvim", Dst: "/home/hat/.config/nvim"}
	if !reflect.DeepEqual(plan.Actions[0], want) {
		t.Errorf("action = %+v, want %+v", plan.Actions[0], want)
	}
}

func TestBuildPlan_UnknownModuleSelectionIsError(t *testing.T) {
	manifest := Manifest{Modules: []Module{{ID: "nvim", Required: true}}}
	platform := Platform{OS: Linux, Env: testEnv()}

	_, err := BuildPlan(manifest, platform, []string{"does-not-exist"}, fakeFS{})
	if err == nil {
		t.Fatal("expected an error for an unknown module id, got nil")
	}
}

func TestBuildPlan_IncompatibleModuleSelectionIsError(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "wezterm", OS: []OS{Windows}},
	}}
	platform := Platform{OS: Linux, Env: testEnv()}

	_, err := BuildPlan(manifest, platform, []string{"wezterm"}, fakeFS{})
	if err == nil {
		t.Fatal("expected an error selecting a module incompatible with the platform, got nil")
	}
}

func TestBuildPlan_OptionalModuleOnlyWhenSelected(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "tmux", Links: []Link{{Src: "common/tmux/tmux.conf", Dst: "~/.config/tmux/tmux.conf"}}},
	}}
	platform := Platform{OS: Linux, Env: testEnv()}

	plan, err := BuildPlan(manifest, platform, nil, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 0 {
		t.Fatalf("unselected optional module produced actions: %+v", plan.Actions)
	}

	plan, err = BuildPlan(manifest, platform, []string{"tmux"}, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 1 {
		t.Fatalf("selected optional module produced %d actions, want 1", len(plan.Actions))
	}
}

func TestBuildPlan_LinkActionKindFollowsFSState(t *testing.T) {
	cases := []struct {
		name  string
		state DstState
		want  ActionKind
	}{
		{"missing destination creates a link", DstMissing, ActionLinkCreate},
		{"symlink already pointing at src is a no-op", DstSymlinkToExpectedSrc, ActionLinkSkipIdentical},
		{"symlink pointing elsewhere gets replaced", DstSymlinkElsewhere, ActionLinkReplace},
		{"a real file or dir gets backed up then linked", DstOther, ActionBackupThenLink},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			manifest := Manifest{Modules: []Module{
				{ID: "nvim", Required: true, Links: []Link{{Src: "common/nvim", Dst: "~/.config/nvim"}}},
			}}
			platform := Platform{OS: Linux, Env: testEnv()}
			fs := fakeFS{states: map[string]DstState{"/home/hat/.config/nvim": tc.state}}

			plan, err := BuildPlan(manifest, platform, nil, fs)
			if err != nil {
				t.Fatalf("BuildPlan error: %v", err)
			}
			if len(plan.Actions) != 1 || plan.Actions[0].Kind != tc.want {
				t.Fatalf("got %+v, want kind %v", plan.Actions, tc.want)
			}
		})
	}
}

func TestBuildPlan_LinkOSFilterAppliesWithinAModule(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{
			ID: "ghostty",
			OS: []OS{Linux, Mac},
			Links: []Link{
				{Src: "common/ghostty", Dst: "~/.config/ghostty"},
				{Src: "os/linux/ghostty/os.ghostty", Dst: "~/.config/hatdots/os.ghostty", OS: []OS{Linux}},
				{Src: "os/mac/ghostty/os.ghostty", Dst: "~/.config/hatdots/os.ghostty", OS: []OS{Mac}},
			},
		},
	}}
	platform := Platform{OS: Mac, Env: testEnv()}

	plan, err := BuildPlan(manifest, platform, []string{"ghostty"}, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	var srcs []string
	for _, a := range plan.Actions {
		srcs = append(srcs, a.Src)
	}
	want := []string{"common/ghostty", "os/mac/ghostty/os.ghostty"}
	if !reflect.DeepEqual(srcs, want) {
		t.Errorf("srcs = %v, want %v", srcs, want)
	}
}

func TestBuildPlan_DesktopFilterGatesOmarchyOverlay(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{
			ID: "tmux",
			OS: []OS{Linux},
			Links: []Link{
				{Src: "common/tmux/tmux.conf", Dst: "~/.config/tmux/tmux.conf"},
				{Src: "os/omarchy/tmux/omarchy.tmux.conf", Dst: "~/.config/hatdots/omarchy.tmux.conf", OS: []OS{Linux}, Desktop: []Desktop{Omarchy}},
			},
		},
	}}

	plain := Platform{OS: Linux, Desktop: NoDesktop, Env: testEnv()}
	plan, err := BuildPlan(manifest, plain, []string{"tmux"}, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 1 {
		t.Fatalf("non-omarchy linux got %d actions, want 1 (overlay must be skipped): %+v", len(plan.Actions), plan.Actions)
	}

	omarchy := Platform{OS: Linux, Desktop: Omarchy, Env: testEnv()}
	plan, err = BuildPlan(manifest, omarchy, []string{"tmux"}, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 2 {
		t.Fatalf("omarchy got %d actions, want 2 (overlay must be included): %+v", len(plan.Actions), plan.Actions)
	}
}

func TestBuildPlan_PackageInstallOnlyForPlatformManager(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{
			ID:       "nvim",
			Required: true,
			Packages: []PackageSpec{
				{Manager: Pacman, Names: []string{"neovim"}},
				{Manager: Brew, Names: []string{"neovim"}},
			},
		},
	}}
	platform := Platform{OS: Linux, PkgManager: Pacman, Env: testEnv()}

	plan, err := BuildPlan(manifest, platform, nil, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 1 || plan.Actions[0].Kind != ActionPackageInstall || plan.Actions[0].Manager != Pacman {
		t.Fatalf("got %+v, want exactly one pacman package-install action", plan.Actions)
	}
}

func TestBuildPlan_PostInstallRespectsFilters(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{
			ID: "herdr",
			OS: []OS{Mac},
			PostInstall: []PostInstall{
				{Command: "os/mac/herdr/install.sh", OS: []OS{Mac}},
			},
		},
	}}
	platform := Platform{OS: Mac, Env: testEnv()}

	plan, err := BuildPlan(manifest, platform, []string{"herdr"}, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 1 || plan.Actions[0].Kind != ActionPostInstall || plan.Actions[0].Command != "os/mac/herdr/install.sh" {
		t.Fatalf("got %+v, want exactly one post-install action", plan.Actions)
	}
}

func TestBuildPlan_RequiredModuleSkippedWhenPlatformUnsupported(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "fish", Required: true, OS: []OS{Linux}, Links: []Link{{Src: "common/fish/config.fish", Dst: "~/.config/fish/config.fish"}}},
	}}
	platform := Platform{OS: Mac, Env: testEnv()}

	plan, err := BuildPlan(manifest, platform, nil, fakeFS{})
	if err != nil {
		t.Fatalf("BuildPlan error: %v", err)
	}
	if len(plan.Actions) != 0 {
		t.Fatalf("required-but-platform-incompatible module produced actions: %+v", plan.Actions)
	}
}

func TestBuildPlan_RejectsEmptyHOME(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "nvim", Required: true, Links: []Link{{Src: "common/nvim", Dst: "~/.config/nvim"}}},
	}}
	platform := Platform{OS: Linux, Env: map[string]string{"HOME": ""}}

	if _, err := BuildPlan(manifest, platform, nil, fakeFS{}); err == nil {
		t.Fatal("expected an error with an empty HOME, got nil (this is the exact bug that used to turn ~/x into /x)")
	}
}

func TestBuildPlan_RejectsDstOutsideHome(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "evil", Required: true, Links: []Link{{Src: "common/evil", Dst: "/etc/evil"}}},
	}}
	platform := Platform{OS: Linux, Env: testEnv()}

	if _, err := BuildPlan(manifest, platform, nil, fakeFS{}); err == nil {
		t.Fatal("expected an error for a destination outside the user's home directory, got nil")
	}
}

func TestBuildPlan_RejectsRelativeDst(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "evil", Required: true, Links: []Link{{Src: "common/evil", Dst: "relative/path"}}},
	}}
	platform := Platform{OS: Linux, Env: testEnv()}

	if _, err := BuildPlan(manifest, platform, nil, fakeFS{}); err == nil {
		t.Fatal("expected an error for a relative destination, got nil")
	}
}

func TestBuildPlan_RejectsRootDst(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "evil", Required: true, Links: []Link{{Src: "common/evil", Dst: "/"}}},
	}}
	platform := Platform{OS: Linux, Env: testEnv()}

	if _, err := BuildPlan(manifest, platform, nil, fakeFS{}); err == nil {
		t.Fatal("expected an error for a root destination, got nil")
	}
}

func TestBuildPlan_AllowsDstUnderLocalAppData(t *testing.T) {
	manifest := Manifest{Modules: []Module{
		{ID: "nvim", Required: true, Links: []Link{{Src: "common/nvim", Dst: "%LOCALAPPDATA%/nvim"}}},
	}}
	platform := Platform{OS: Windows, Env: map[string]string{
		"HOME":         "/home/u",
		"LOCALAPPDATA": `C:\Users\u\AppData\Local`,
	}}

	plan, err := BuildPlan(manifest, platform, nil, fakeFS{})
	if err != nil {
		t.Fatalf("a destination under the documented LOCALAPPDATA exception must be allowed: %v", err)
	}
	if len(plan.Actions) != 1 {
		t.Fatalf("got %+v, want 1 action", plan.Actions)
	}
}

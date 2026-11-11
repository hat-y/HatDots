// Command hatdots is the HatDots cross-platform dotfiles installer.
package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/hat-y/HatDots/installer/internal/app"
	"github.com/hat-y/HatDots/installer/internal/domain"
	"github.com/hat-y/HatDots/installer/internal/manifest"
	"github.com/hat-y/HatDots/installer/internal/platform"
	"github.com/hat-y/HatDots/installer/internal/tui"
)

// executableFunc resolves the running binary's own path; a package-level
// var (rather than a run()/resolveRepoRoot parameter) so tests can fake
// it without widening run()'s already-stable public signature.
var executableFunc = os.Executable

// runTUIFunc launches the interactive TUI; a package-level var so tests
// can substitute a fake that never actually starts a Bubbletea program
// (which would block waiting for real terminal input) while still
// observing what port/options run() built for it.
var runTUIFunc = tui.Run

func main() {
	isTTY := false
	if info, err := os.Stdin.Stat(); err == nil {
		isTTY = info.Mode()&os.ModeCharDevice != 0
	}
	isStdoutTTY := false
	if info, err := os.Stdout.Stat(); err == nil {
		isStdoutTTY = info.Mode()&os.ModeCharDevice != 0
	}
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr, isTTY, isStdoutTTY))
}

// run is the whole CLI, factored out of main so tests can drive it without
// a real process, a real TTY, or the real filesystem outside t.TempDir().
func run(args []string, stdin io.Reader, stdout, stderr io.Writer, isTTY, isStdoutTTY bool) int {
	if len(args) > 0 && args[0] == "list" {
		return runList(args[1:], stdout, stderr)
	}
	if shouldLaunchTUI(args, isTTY, isStdoutTTY) {
		return runTUIMode(args, stdout, stderr)
	}
	return runInstall(args, stdin, stdout, stderr, isTTY)
}

// shouldLaunchTUI decides between the interactive TUI and the plain,
// scriptable CLI path. Both stdin and stdout must be real terminals (the
// TUI reads key events from one and paints to the other); --yes is an
// explicit request to run non-interactively and always wins. --dry-run
// is deliberately NOT a bypass: it is one of the TUI's own preview-screen
// features (toggled with "d"), carried into the TUI's initial state
// instead (see runTUIMode), so asking for a dry run on a real terminal
// still gets the interactive experience.
func shouldLaunchTUI(args []string, isTTY, isStdoutTTY bool) bool {
	if !isTTY || !isStdoutTTY {
		return false
	}
	return !hasBoolFlag(args, "yes")
}

// hasBoolFlag reports whether args contains a Go flag.Bool-style flag
// named name, spelled "--name"/"-name" or with an explicit "=true" (the
// only forms any caller here ever uses).
func hasBoolFlag(args []string, name string) bool {
	for _, a := range args {
		switch a {
		case "-" + name, "--" + name, "-" + name + "=true", "--" + name + "=true":
			return true
		}
	}
	return false
}

// runTUIMode resolves the repo and platform exactly like runInstall, then
// hands off to the interactive TUI instead of printing a plan and
// applying it directly. --all/--only mean exactly what they mean on the
// non-interactive path (selectionFromFlags): they seed the select screen,
// where the user can still adjust it. An unknown or incompatible --only id
// fails here, before the TUI opens, with the same error as the CLI path.
// --yes is still accepted (and ignored) so muscle-memory flags don't trip
// flag.ContinueOnError.
func runTUIMode(args []string, stdout, stderr io.Writer) int {
	fs := flag.NewFlagSet("hatdots", flag.ContinueOnError)
	fs.SetOutput(stderr)
	repoFlag := fs.String("repo", "", "path to the HatDots repo root (default: auto-detect)")
	dryRunFlag := fs.Bool("dry-run", false, "start the TUI with dry-run on and locked: the preview screen's \"d\" key cannot turn it back off")
	osFlag := fs.String("os", "", "override the detected OS: linux, mac, or windows")
	desktopFlag := fs.String("desktop", "", "override the detected desktop: omarchy or none")
	allFlag := fs.Bool("all", false, "start the TUI with every compatible module selected")
	onlyFlag := fs.String("only", "", "start the TUI with only these comma-separated module ids selected (plus required modules)")
	_ = fs.Bool("yes", false, "ignored: shouldLaunchTUI already keeps --yes on the non-interactive path")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	repoRoot, err := resolveRepoRootForInteractiveUse(*repoFlag, stdout, stderr)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	a, err := app.Load(repoRoot)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	plat, err := detectPlatform(*osFlag, *desktopFlag)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	opts := []tui.Option{tui.WithInitialDryRun(*dryRunFlag)}
	if only := parseOnly(*onlyFlag); *allFlag || len(only) > 0 {
		selection := selectionFromFlags(a.Manifest, plat, *allFlag, only)
		// Validate up front so a typo in --only fails loudly instead of
		// opening a select screen that silently dropped it.
		if _, err := a.Plan(plat, selection); err != nil {
			fmt.Fprintln(stderr, "hatdots:", err)
			return 1
		}
		opts = append(opts, tui.WithInitialSelection(selection))
	}

	port := tui.NewAppPort(a, plat)
	if err := runTUIFunc(port, opts...); err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}
	return 0
}

// resolveRepoRootForInteractiveUse resolves --repo exactly like
// runInstall's own repo resolution, confirming on stdin/stdout when the
// repo was only found via the executable-fallback path (see
// findRepoRoot). It is only ever reached when a real TTY is already
// confirmed (shouldLaunchTUI's own check), so os.Stdin is always a real
// terminal to confirm on here.
func resolveRepoRootForInteractiveUse(explicit string, stdout, stderr io.Writer) (string, error) {
	repoRoot, repoSrc, err := resolveRepoRoot(explicit)
	if err != nil {
		return "", err
	}
	if repoSrc == repoSourceExecutableFallback {
		fmt.Fprintf(stderr, "hatdots: no --repo given and no modules.toml found above the current directory; using %s (found next to the installer binary).\n", repoRoot)
		if !confirmPrompt(os.Stdin, stdout, "Use this repo? [y/N] ") {
			return "", fmt.Errorf("aborted: repo not confirmed")
		}
	}
	return repoRoot, nil
}

func runList(args []string, stdout, stderr io.Writer) int {
	fs := flag.NewFlagSet("list", flag.ContinueOnError)
	fs.SetOutput(stderr)
	repoFlag := fs.String("repo", "", "path to the HatDots repo root (default: auto-detect)")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	// `list` is read-only, so an auto-detected repo (even via the
	// executable-fallback path) is used without the confirmation
	// runInstall requires — nothing destructive can come of printing
	// the wrong repo's module list.
	repoRoot, _, err := resolveRepoRoot(*repoFlag)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}
	a, err := app.Load(repoRoot)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	for _, mod := range a.Manifest.Modules {
		req := "optional"
		if mod.Required {
			req = "required"
		}
		osList := "all"
		if len(mod.OS) > 0 {
			var oses []string
			for _, o := range mod.OS {
				oses = append(oses, string(o))
			}
			osList = strings.Join(oses, ",")
		}
		def := ""
		if mod.Default {
			def = ", default-selected"
		}
		fmt.Fprintf(stdout, "%-14s %-9s os=%-16s %s%s\n", mod.ID, req, osList, mod.Description, def)
	}
	return 0
}

func runInstall(args []string, stdin io.Reader, stdout, stderr io.Writer, isTTY bool) int {
	fs := flag.NewFlagSet("hatdots", flag.ContinueOnError)
	fs.SetOutput(stderr)
	repoFlag := fs.String("repo", "", "path to the HatDots repo root (default: auto-detect)")
	allFlag := fs.Bool("all", false, "select every module compatible with this platform")
	onlyFlag := fs.String("only", "", "comma-separated module ids to select, in addition to required modules")
	dryRunFlag := fs.Bool("dry-run", false, "print the plan without changing anything")
	yesFlag := fs.Bool("yes", false, "don't prompt for confirmation before applying")
	osFlag := fs.String("os", "", "override the detected OS: linux, mac, or windows")
	desktopFlag := fs.String("desktop", "", "override the detected desktop: omarchy or none")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	repoRoot, repoSrc, err := resolveRepoRoot(*repoFlag)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}
	if repoSrc == repoSourceExecutableFallback {
		// Nothing told us which repo to use: not --repo, not a
		// modules.toml anywhere above the current directory. We're
		// about to act on a directory the user never actually pointed
		// us at (it just happened to sit next to the binary) — require
		// an explicit human confirmation rather than silently trusting
		// a guess, and refuse outright under --yes, since there is no
		// one to confirm with.
		fmt.Fprintf(stderr, "hatdots: no --repo given and no modules.toml found above the current directory; using %s (found next to the installer binary).\n", repoRoot)
		if *yesFlag {
			fmt.Fprintln(stderr, "hatdots: refusing to proceed with an auto-detected repo under --yes; pass --repo explicitly.")
			return 1
		}
		if !isTTY {
			fmt.Fprintln(stderr, "hatdots: no terminal available to confirm the auto-detected repo; pass --repo explicitly.")
			return 1
		}
		if !confirmPrompt(stdin, stdout, "Use this repo? [y/N] ") {
			fmt.Fprintln(stdout, "Aborted.")
			return 0
		}
	}
	a, err := app.Load(repoRoot)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	plat, err := detectPlatform(*osFlag, *desktopFlag)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	selection := selectionFromFlags(a.Manifest, plat, *allFlag, parseOnly(*onlyFlag))

	plan, err := a.Plan(plat, selection)
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}

	printPlan(stdout, plan)

	if !*dryRunFlag && !*yesFlag && isTTY {
		if !confirm(stdin, stdout) {
			fmt.Fprintln(stdout, "Aborted.")
			return 0
		}
	}

	err = a.Apply(plan, *dryRunFlag, func(e app.Event) {
		if e.Err != nil {
			fmt.Fprintf(stderr, "  ! %s %s: %v\n", e.Action.Kind, e.Action.ModuleID, e.Err)
		}
	})
	if err != nil {
		fmt.Fprintln(stderr, "hatdots:", err)
		return 1
	}
	return 0
}

func printPlan(stdout io.Writer, plan domain.Plan) {
	fmt.Fprintf(stdout, "Plan: %d action(s)\n", len(plan.Actions))
	var toBackUp []string
	for _, a := range plan.Actions {
		switch a.Kind {
		case domain.ActionPackageInstall:
			fmt.Fprintf(stdout, "  %-22s %-10s %s %v\n", a.Kind, a.ModuleID, a.Manager, a.Packages)
		case domain.ActionPostInstall:
			fmt.Fprintf(stdout, "  %-22s %-10s %s\n", a.Kind, a.ModuleID, a.Command)
		default:
			fmt.Fprintf(stdout, "  %-22s %-10s %s -> %s\n", a.Kind, a.ModuleID, a.Dst, a.Src)
		}
		if a.Kind == domain.ActionBackupThenLink {
			toBackUp = append(toBackUp, a.Dst)
		}
	}

	if len(toBackUp) > 0 {
		fmt.Fprintln(stdout)
		fmt.Fprintln(stdout, "These files will be replaced (backup kept):")
		for _, dst := range toBackUp {
			fmt.Fprintf(stdout, "  %s\n", dst)
		}
	}
}

func confirm(stdin io.Reader, stdout io.Writer) bool {
	return confirmPrompt(stdin, stdout, "Apply this plan? [y/N] ")
}

func confirmPrompt(stdin io.Reader, stdout io.Writer, prompt string) bool {
	fmt.Fprint(stdout, prompt)
	scanner := bufio.NewScanner(stdin)
	if !scanner.Scan() {
		return false
	}
	answer := strings.ToLower(strings.TrimSpace(scanner.Text()))
	return answer == "y" || answer == "yes"
}

// repoSource records how resolveRepoRoot picked a repo root, so callers
// that care (runInstall) can require extra confirmation for the riskiest
// case: a guess based on where the binary happens to live.
type repoSource int

const (
	repoSourceExplicit repoSource = iota
	repoSourceWalkUp
	repoSourceExecutableFallback
)

// resolveRepoRoot honors an explicit --repo, else auto-detects.
func resolveRepoRoot(explicit string) (string, repoSource, error) {
	if explicit != "" {
		abs, err := filepath.Abs(explicit)
		if err != nil {
			return "", 0, err
		}
		return abs, repoSourceExplicit, nil
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "", 0, err
	}
	return findRepoRoot(cwd, executableFunc)
}

// findRepoRoot walks up from start looking for a modules.toml that
// declares the HatDots schema marker (manifest.HasSchemaMarker) — a file
// that merely exists at that name isn't enough, since it might belong to
// something else entirely. If none is found, it falls back to the
// directory holding the running executable (the layout a release/
// bootstrap install produces: the binary sits next to the repo it was
// built to install), still gated on the same marker check.
func findRepoRoot(start string, executable func() (string, error)) (string, repoSource, error) {
	dir := start
	for {
		if manifest.HasSchemaMarker(filepath.Join(dir, app.ManifestFileName)) {
			return dir, repoSourceWalkUp, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}

	exe, err := executable()
	if err == nil && exe != "" {
		exeDir := filepath.Dir(exe)
		if manifest.HasSchemaMarker(filepath.Join(exeDir, app.ManifestFileName)) {
			return exeDir, repoSourceExecutableFallback, nil
		}
	}

	return "", 0, fmt.Errorf("could not find a HatDots repo (a %s declaring schema = %q) above %s or next to the executable", app.ManifestFileName, manifest.Schema, start)
}

// selectionFromFlags turns --all/--only into the optional-module
// selection both the non-interactive path and the TUI start from:
//   - --all: every module compatible with plat;
//   - --only: exactly those ids, nothing else auto-selected;
//   - neither: domain.DefaultSelection, the modules the three old scripts
//     installed by default on this platform (not every optional module).
//
// Required modules are always added later by domain.BuildPlan.
func selectionFromFlags(m domain.Manifest, plat domain.Platform, all bool, only []string) []string {
	var selection []string
	switch {
	case all:
		for _, mod := range m.Modules {
			if mod.SupportsPlatform(plat) {
				selection = append(selection, mod.ID)
			}
		}
	case len(only) > 0:
		// explicit --only: nothing auto-selected beyond required modules.
	default:
		selection = domain.DefaultSelection(m, plat)
	}
	return append(selection, only...)
}

func parseOnly(s string) []string {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	var out []string
	for _, part := range strings.Split(s, ",") {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func resolveOSFlag(s string) (domain.OS, error) {
	if s == "" {
		return platform.DetectOS(), nil
	}
	switch domain.OS(s) {
	case domain.Linux, domain.Mac, domain.Windows:
		return domain.OS(s), nil
	default:
		return "", fmt.Errorf("invalid --os value: %q (want linux, mac, or windows)", s)
	}
}

// resolveDesktopFlag parses an explicit --desktop value. "" is the
// sentinel for "not given" (the caller auto-detects); "none" explicitly
// forces no-desktop, distinct from an absent flag.
func resolveDesktopFlag(s string) (domain.Desktop, error) {
	switch s {
	case "", "none":
		return domain.NoDesktop, nil
	case "omarchy":
		return domain.Omarchy, nil
	default:
		return "", fmt.Errorf("invalid --desktop value: %q (want omarchy or none)", s)
	}
}

func lookPath(name string) (string, error) {
	return exec.LookPath(name)
}

func detectPlatform(osFlag, desktopFlag string) (domain.Platform, error) {
	targetOS, err := resolveOSFlag(osFlag)
	if err != nil {
		return domain.Platform{}, err
	}

	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("HOME")
	}

	var desktop domain.Desktop
	if desktopFlag == "" {
		desktop = domain.NoDesktop
		if targetOS == domain.Linux {
			desktop = platform.DetectOmarchy(home)
		}
	} else {
		desktop, err = resolveDesktopFlag(desktopFlag)
		if err != nil {
			return domain.Platform{}, err
		}
	}

	var distroID, distroIDLike string
	if targetOS == domain.Linux {
		distroID, distroIDLike, _ = platform.DetectDistro()
	}
	mgr, aurHelper := platform.DetectPkgManagerFor(targetOS, distroID, distroIDLike, lookPath)

	env := map[string]string{}
	// Never set an empty HOME: a present-but-empty value used to let
	// domain.ExpandPath turn "~/x" into "/x" (a real root-relative path,
	// just the wrong one). Leaving the key out entirely makes
	// ExpandPath/BuildPlan treat it exactly like HOME being unset, which
	// they now reject outright instead of guessing.
	if home != "" {
		env["HOME"] = home
	}
	for _, k := range []string{"LOCALAPPDATA", "XDG_CONFIG_HOME"} {
		if v := os.Getenv(k); v != "" {
			env[k] = v
		}
	}

	return domain.Platform{
		OS:         targetOS,
		Desktop:    desktop,
		PkgManager: mgr,
		AURHelper:  aurHelper,
		Env:        env,
	}, nil
}

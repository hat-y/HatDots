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
	"github.com/hat-y/HatDots/installer/internal/platform"
)

func main() {
	isTTY := false
	if info, err := os.Stdin.Stat(); err == nil {
		isTTY = info.Mode()&os.ModeCharDevice != 0
	}
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr, isTTY))
}

// run is the whole CLI, factored out of main so tests can drive it without
// a real process, a real TTY, or the real filesystem outside t.TempDir().
func run(args []string, stdin io.Reader, stdout, stderr io.Writer, isTTY bool) int {
	if len(args) > 0 && args[0] == "list" {
		return runList(args[1:], stdout, stderr)
	}
	return runInstall(args, stdin, stdout, stderr, isTTY)
}

func runList(args []string, stdout, stderr io.Writer) int {
	fs := flag.NewFlagSet("list", flag.ContinueOnError)
	fs.SetOutput(stderr)
	repoFlag := fs.String("repo", "", "path to the HatDots repo root (default: auto-detect)")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	repoRoot, err := resolveRepoRoot(*repoFlag)
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

	repoRoot, err := resolveRepoRoot(*repoFlag)
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

	only := parseOnly(*onlyFlag)
	var selection []string
	switch {
	case *allFlag:
		for _, mod := range a.Manifest.Modules {
			if mod.SupportsPlatform(plat) {
				selection = append(selection, mod.ID)
			}
		}
	case len(only) > 0:
		// explicit --only: nothing auto-selected beyond required modules.
	default:
		// No --all, no --only: pre-select exactly the modules the three
		// old scripts installed by default on this platform (see
		// domain.Module.IsDefaultFor/DefaultSelection), not every
		// optional module.
		selection = domain.DefaultSelection(a.Manifest, plat)
	}
	selection = append(selection, only...)

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
	fmt.Fprint(stdout, "Apply this plan? [y/N] ")
	scanner := bufio.NewScanner(stdin)
	if !scanner.Scan() {
		return false
	}
	answer := strings.ToLower(strings.TrimSpace(scanner.Text()))
	return answer == "y" || answer == "yes"
}

// resolveRepoRoot honors an explicit --repo, else auto-detects.
func resolveRepoRoot(explicit string) (string, error) {
	if explicit != "" {
		abs, err := filepath.Abs(explicit)
		if err != nil {
			return "", err
		}
		return abs, nil
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	return findRepoRoot(cwd, os.Executable)
}

// findRepoRoot walks up from start looking for modules.toml; if none is
// found, it falls back to the directory holding the running executable
// (the layout a release/bootstrap install produces: the binary sits next
// to the repo it was built to install).
func findRepoRoot(start string, executable func() (string, error)) (string, error) {
	dir := start
	for {
		if _, err := os.Stat(filepath.Join(dir, app.ManifestFileName)); err == nil {
			return dir, nil
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
		if _, err := os.Stat(filepath.Join(exeDir, app.ManifestFileName)); err == nil {
			return exeDir, nil
		}
	}

	return "", fmt.Errorf("could not find %s above %s or next to the executable", app.ManifestFileName, start)
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

	env := map[string]string{"HOME": home}
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

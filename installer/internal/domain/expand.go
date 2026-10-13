package domain

import (
	"fmt"
	"strings"
)

// ExpandPath expands "~", "$VAR", "${VAR}" and "%VAR%" references in path
// using env. It errors instead of guessing whenever a reference cannot be
// resolved to a genuinely non-empty value: a "~" with no HOME set (or HOME
// set to ""), and any $VAR/${VAR}/%VAR% whose variable is absent or empty.
// Guessing here is exactly how an empty-but-present HOME used to silently
// turn "~/x" into "/x" — a real path, just the wrong one — instead of
// failing loudly. A path with no placeholder at all never errors.
//
// This is a pure function: it never reads the real environment or touches
// the filesystem. The caller (the app/platform layer) is responsible for
// building env from the real OS when that's what's wanted, and tests build
// a fake one.
func ExpandPath(path string, env map[string]string) (string, error) {
	if strings.HasPrefix(path, "~") {
		home, ok := env["HOME"]
		if !ok || home == "" {
			return "", fmt.Errorf("expand %q: HOME is not set (or is empty); refusing to guess a path", path)
		}
		path = home + path[1:]
	}

	var b strings.Builder
	for i := 0; i < len(path); i++ {
		c := path[i]
		switch c {
		case '$':
			name, length := readDollarVar(path[i+1:])
			if length == 0 {
				b.WriteByte(c)
				continue
			}
			val, ok := env[name]
			if !ok || val == "" {
				return "", fmt.Errorf("expand %q: $%s is not set (or is empty); refusing to guess a path", path, name)
			}
			b.WriteString(val)
			i += length
		case '%':
			end := strings.IndexByte(path[i+1:], '%')
			if end <= 0 {
				b.WriteByte(c)
				continue
			}
			name := path[i+1 : i+1+end]
			val, ok := env[name]
			if !ok || val == "" {
				return "", fmt.Errorf("expand %q: %%%s%% is not set (or is empty); refusing to guess a path", path, name)
			}
			b.WriteString(val)
			i += end + 1
		default:
			b.WriteByte(c)
		}
	}
	return b.String(), nil
}

// readDollarVar parses a "$VAR" or "${VAR}" reference starting right after
// the '$'. It returns the variable name and how many bytes (after the '$')
// the reference occupies, or ("", 0) if s does not start with a valid
// reference.
func readDollarVar(s string) (name string, length int) {
	if s == "" {
		return "", 0
	}
	if s[0] == '{' {
		end := strings.IndexByte(s, '}')
		if end <= 1 {
			return "", 0
		}
		return s[1:end], end + 1
	}
	end := 0
	for end < len(s) && isVarNameByte(s[end]) {
		end++
	}
	if end == 0 {
		return "", 0
	}
	return s[:end], end
}

func isVarNameByte(c byte) bool {
	return c == '_' ||
		(c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		(c >= '0' && c <= '9')
}

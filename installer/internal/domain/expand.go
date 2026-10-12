package domain

import "strings"

// ExpandPath expands "~", "$VAR", "${VAR}" and "%VAR%" references in path
// using env. A reference to a variable absent from env is left untouched
// (including "~" when env has no "HOME") so callers can detect and report
// the problem instead of silently producing a wrong path.
//
// This is a pure function: it never reads the real environment or touches
// the filesystem. The caller (the app/platform layer) is responsible for
// building env from the real OS when that's what's wanted, and tests build
// a fake one.
func ExpandPath(path string, env map[string]string) string {
	if strings.HasPrefix(path, "~") {
		if home, ok := env["HOME"]; ok {
			path = home + path[1:]
		}
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
			if val, ok := env[name]; ok {
				b.WriteString(val)
				i += length
				continue
			}
			b.WriteByte(c)
		case '%':
			if end := strings.IndexByte(path[i+1:], '%'); end > 0 {
				name := path[i+1 : i+1+end]
				if val, ok := env[name]; ok {
					b.WriteString(val)
					i += end + 1
					continue
				}
			}
			b.WriteByte(c)
		default:
			b.WriteByte(c)
		}
	}
	return b.String()
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

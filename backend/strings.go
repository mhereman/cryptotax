package backend

func TruncateString(s string, maxLength int, addElipses bool) string {
	if len(s) <= maxLength {
		return s
	}

	if !addElipses {
		return s[:maxLength]
	}

	return s[:(maxLength-1)] + "…"
}

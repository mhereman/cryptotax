package validators

import (
	"errors"
	"regexp"
)

var emailRegex *regexp.Regexp

func init() {
	emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
}

func ValidateEmail(email string) error {
	if email == "" {
		return errors.New("Email is required")
	}
	if !emailRegex.MatchString(email) {
		return errors.New("Inavlid email format")
	}
	return nil
}

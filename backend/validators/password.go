package validators

import (
	"errors"

	pwval "github.com/wagslane/go-password-validator"
)

const minEntopyBits = 70

func ValidatePasswordsMatch(password1 string, password2 string) error {
	if password1 != password2 {
		return errors.New("passwords do not match")
	}
	return nil
}

func ValidatePasswordStrength(password string) error {
	err := pwval.Validate(password, minEntopyBits)
	return err
}

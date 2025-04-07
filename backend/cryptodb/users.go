package cryptodb

import (
	"errors"
	"log"
)

func IsAdminConfigured() (bool, error) {
	var count int

	const query = `SELECT COUNT(Email) FROM crypto.Users WHERE IsAdmin = 'true'`
	err := db.QueryRow(query).Scan(&count)
	if err != nil {
		return false, err
	}

	return (count > 0), nil
}

func CreateUser(
	email string,
	hash string,
	isAdmin bool,
) error {
	const query = `INSERT INTO crypto.Users (Email, PasswordHash, IsAdmin) VALUES ($1, $2, $3)`
	res, err := db.Exec(query, email, hash, isAdmin)
	if err != nil {
		log.Println(err.Error())
		return err
	}

	rows, err := res.RowsAffected()
	if err != nil {
		log.Println(err.Error())
		return err
	}

	if rows == 0 {
		log.Println(res.RowsAffected())
		return errors.New("user not created")
	}
	return nil
}

type User struct {
	Email        string
	PasswordHash string
	IsAdmin      bool
}

func GetUser(
	email string,
) (*User, error) {
	var hash string
	var isAdmin bool

	const query = `SELECT PasswordHash, IsAdmin FROM crypto.Users WHERE Email = $1`
	err := db.QueryRow(query, email).Scan(&hash, &isAdmin)
	if err != nil {
		return nil, err
	}

	return &User{
		Email:        email,
		PasswordHash: hash,
		IsAdmin:      isAdmin,
	}, nil
}

type UserDetails struct {
	Email     string
	IsAdmin   bool
	FirstName string
	LastName  string
}

func GetUserDetails(
	email string,
) (*UserDetails, error) {
	var isAdmin bool
	var firstName, lastName NullString

	const query = `SELECT u.IsAdmin, d.FirstName, d.LastName
		FROM crypto.Users u
		LEFT JOIN crypto.UserDetails d ON (d.UserId = u.Id)
		WHERE u.Email = $1`
	err := db.QueryRow(query, email).Scan(&isAdmin, &firstName, &lastName)
	if err != nil {
		return nil, err
	}

	return &UserDetails{
		Email:     email,
		IsAdmin:   isAdmin,
		FirstName: firstName.String(),
		LastName:  lastName.String(),
	}, nil
}

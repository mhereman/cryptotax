package cryptodb

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
	"github.com/mhereman/cryptotax/config"
)

var db *sql.DB

func Connect() {
	var err error

	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		config.DatabaseHost(),
		config.DatabasePort(),
		config.DatabaseUser(),
		config.DatabasePassword(),
		config.DatabaesName())
	db, err = sql.Open("postgres", dsn)
	if err != nil {
		log.Fatal("Failed to connect to database: ", err)
	}
}

package cryptodb

import (
	"io/fs"
	"sort"

	"github.com/mhereman/cryptotax/backend/cryptodb/sql"
)

var migrateArr []func() error

func init() {
	migrateArr = []func() error{
		migrateFromV0,
	}
}

func Migrate() error {
	currentVersion := currentDbVersion()
	for i := currentVersion; i < len(migrateArr); i++ {
		if err := migrateArr[i](); err != nil {
			return err
		}
	}
	return nil
}

func migrateFromV0() error {
	files := []string{}

	err := fs.WalkDir(sql.V1, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return err
	}

	sort.Strings(files)

	for _, file := range files {
		data, err := sql.V1.ReadFile(file)
		if err != nil {
			return err
		}
		_, err = db.Exec(string(data))
		if err != nil {
			return err
		}
	}

	return nil
}

func currentDbVersion() int {
	if !hasCryptoSchema() {
		return 0
	}

	const query = `SELECT Version FROM crypto.Version;`
	var version int
	err := db.QueryRow(query).Scan(&version)
	if err != nil {
		return 0
	}
	return version
}

func hasCryptoSchema() bool {
	const query = `select exists (select * from pg_catalog.pg_stat_all_tables where schemaname = 'crypto');`
	var exists bool
	err := db.QueryRow(query).Scan(&exists)
	if err != nil {
		return false
	}
	return exists
}

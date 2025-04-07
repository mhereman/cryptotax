package config

import (
	"flag"
	"os"
	"strconv"
)

type configVars struct {
	Debug bool

	Port int

	DatabaseHost     string
	DatabasePort     int
	DatabaseName     string
	DatabaseUser     string
	DatabasePassword string

	LibDir string
}

var cfgVars configVars

func getStringEnvVar(key string, defaultValue string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultValue
}

func getIntEnvVar(key string, defaultValue int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return defaultValue
}

func getBoolEnvVar(key string, defaultValue bool) bool {
	if v := os.Getenv(key); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return defaultValue
}

func ParseConfig() {
	flag.BoolVar(&cfgVars.Debug, "debug", getBoolEnvVar("DEBUG", false), "Debug")
	flag.IntVar(&cfgVars.Port, "port", getIntEnvVar("PORT", 8080), "Port")

	flag.StringVar(&cfgVars.DatabaseHost, "dbhost", getStringEnvVar("DB_HOST", "localhost"), "Database host")
	flag.IntVar(&cfgVars.DatabasePort, "dbport", getIntEnvVar("DB_PORT", 5432), "Database port")
	flag.StringVar(&cfgVars.DatabaseName, "dbname", getStringEnvVar("DB_NAME", "postgres"), "Database name")
	flag.StringVar(&cfgVars.DatabaseUser, "dbuser", getStringEnvVar("DB_USER", "postgres"), "Database user")
	flag.StringVar(&cfgVars.DatabasePassword, "dbpass", getStringEnvVar("DB_PASS", "postgres"), "Database password")

	flag.StringVar(&cfgVars.LibDir, "libdir", getStringEnvVar("LIB_DIR", "/var/lib/cryptotax"), "Library directory")

	flag.Parse()
}

func Debug() bool {
	return cfgVars.Debug
}

func Port() int {
	return cfgVars.Port
}

func DatabaseHost() string {
	return cfgVars.DatabaseHost
}

func DatabasePort() int {
	return cfgVars.DatabasePort
}

func DatabaesName() string {
	return cfgVars.DatabaseName
}

func DatabaseUser() string {
	return cfgVars.DatabaseUser
}

func DatabasePassword() string {
	return cfgVars.DatabasePassword
}

func LibDir() string {
	return cfgVars.LibDir
}

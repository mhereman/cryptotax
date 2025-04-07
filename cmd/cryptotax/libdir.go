package main

import (
	"log"
	"os"

	"github.com/mhereman/cryptotax/config"
)

func createLibDir() {
	if err := os.MkdirAll(config.LibDir(), 0700); err != nil {
		log.Fatalf("Could not create directory path for '%s': %v", config.LibDir(), err)
	}
}

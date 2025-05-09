package main

import (
	"context"
	"fmt"
	"net/http"
	"os"

	"github.com/joho/godotenv"

	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/config"
	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/middlewares"

	"github.com/mhereman/cryptotax/websrv/assets"

	_ "github.com/mhereman/cryptotax/websrv/handlers"
)

var (
	mainContext  context.Context
	mainCancel   context.CancelFunc
	osSignalChan chan os.Signal
	shutdownChan chan struct{}
)

const (
	ExitCodeOK    = 0
	ExitCodeError = 1
)

func init() {
	if err := godotenv.Load(); err != nil {
		fmt.Println("No environment file loaded")
	}

	mainContext, mainCancel = context.WithCancel(context.Background())
	osSignalChan = make(chan os.Signal, 1)
	shutdownChan = make(chan struct{}, 1)

	config.ParseConfig()

	createLibDir()

	cryptodb.Connect()
	if err := cryptodb.Migrate(); err != nil {
		panic(err)
	}

	http.Handle("/", http.RedirectHandler("/home", http.StatusSeeOther))
	http.Handle("/static/", middlewares.NeuterFS(
		http.FileServerFS(assets.StaticFS),
	))
}

func main() {
	interruptHandlerRoutine()
	websrv.Run(
		mainContext, shutdownChan,
		config.Port(), config.Debug())

	<-shutdownChan
	os.Exit(ExitCodeOK)
}

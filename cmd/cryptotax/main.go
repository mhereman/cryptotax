package main

import (
	"context"
	"net/http"
	"os"

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

/*func init() {
	config.ParseConfig()
	cryptodb.Connect()
	ui.LoadFiles()
}

func main() {
	http.Handle("/static/", http.FileServer(http.FS(ui.StaticFS)))

	ui.SetupPages()

	log.Printf("Server listening on port: %d\n", config.Port())
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", config.Port()), nil))
}
*/

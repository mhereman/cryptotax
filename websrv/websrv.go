package websrv

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"time"
)

var (
	debug bool
	port  int

	listener net.Listener
	server   *http.Server
)

func SetDebug(dbg bool) {
	debug = dbg
}

func Run(
	ctx context.Context,
	shutdownChan chan struct{},
	listenPort int,
	debugMode bool,
) {
	if err := generateJWTKeyPair(); err != nil {
		log.Fatalf("Failed to generate JWT key pair: %v", err)
	}

	stopHttpServerRoutine(ctx, shutdownChan)
	run(listenPort, debugMode)
}

func stopHttpServerRoutine(
	ctx context.Context,
	shutdownChan chan struct{},
) {
	go func() {
		<-ctx.Done()

		c, cncl := context.WithTimeout(context.Background(), 10*time.Second)
		serverStoppedListenerRoutine(c, shutdownChan)
		log.Println("Requesting HTTP Server shutdown")
		server.Shutdown(c)
		cncl()
	}()
}

func serverStoppedListenerRoutine(
	ctx context.Context,
	shutdownChan chan struct{},
) {
	go func() {
		<-ctx.Done()

		log.Println("HTTP Server stopped")
		shutdownChan <- struct{}{}
	}()
}

func run(listenPort int, debugMode bool) {
	port = listenPort
	debug = debugMode

	var err error
	listener, err = net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		panic(err)
	}

	go func() {
		defer listener.Close()
		server = &http.Server{}
		log.Printf("Server listening on port %d\n", port)
		if err := server.Serve(listener); !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("HTTPServer error: %v", err)
			os.Exit(1)
		}
	}()
}

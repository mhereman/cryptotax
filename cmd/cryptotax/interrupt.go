package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
)

// interruptHandlerRoutine starts a go routine which waits for an interrupt
func interruptHandlerRoutine() {
	go func() {
		signal.Notify(osSignalChan, syscall.SIGINT, syscall.SIGTERM, os.Interrupt)
		defer func() {
			signal.Stop(osSignalChan)
			mainCancel()
		}()

		select {
		case <-osSignalChan:
			log.Println("Received shutdown signal")
			mainCancel()
		case <-mainContext.Done():
		}
		<-osSignalChan
	}()
}

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	_ "time/tzdata"
)

var (
	sleep int
	ready bool = true
)

func generateMessage(p string) string {
	greeting := "Hello"

	if len(os.Getenv("GREETING")) > 0 {
		greeting = os.Getenv("GREETING")
	}

	name := "World"
	lastSlash := strings.LastIndex(p, "/")
	if lastSlash != -1 {
		lastComponent := p[lastSlash+1:]
		if len(lastComponent) > 0 {
			name = lastComponent
		}
	}

	return fmt.Sprintf("%s %s", greeting, name)
}

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")

	// do not log requests from probes
	//
	if strings.HasPrefix(r.Header.Get("User-Agent"), "kube-probe") {
		fmt.Fprint(w, "OK")
		return
	}

	path := r.URL.Path
	dump, _ := httputil.DumpRequest(r, true)
	log.Printf("%s", dump)

	if sleep > 0 {
		log.Printf("sleeping for %d seconds...", sleep)
		time.Sleep(time.Duration(sleep) * time.Second)
	}

	fmt.Fprintf(w, "%s: %s\n", os.Getenv("HOSTNAME"), generateMessage(path))
	log.Print("end of request")
}

func liveness(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprint(w, "OK")
}

func readiness(w http.ResponseWriter, r *http.Request) {
	if !ready {
		http.Error(w, "Shutting down", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprint(w, "OK")
}

func exit(w http.ResponseWriter, r *http.Request) {
	log.Print("exiting immediately")
	os.Exit(1)
}

func main() {
	var port, shutdownWait int

	flag.IntVar(&port, "port", 8080, "HTTP listener port")
	flag.IntVar(&sleep, "sleep", 0, "number of seconds to sleep")
	flag.IntVar(&shutdownWait, "shutdownwait", 10, "shutdown grace period in seconds")
	flag.Parse()

	env := getEnvInt("PORT")
	if env > -1 {
		port = env
	}

	sl := getEnvInt("SLEEP")
	if sl > -1 {
		sleep = sl
	}

	log.Printf("sleep set to %d seconds", sleep)

	shutdownWait = getEnvInt("SHUTDOWN_WAIT")
	if shutdownWait == -1 {
		shutdownWait = 15
	}

	log.Printf("shutdown grace period set to %d seconds", shutdownWait)

	// Setup signal handling
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)

	var wg sync.WaitGroup
	server := &http.Server{
		Addr: fmt.Sprintf(":%d", port),
	}
	go func() {
		log.Printf("listening on port %v", port)
		http.HandleFunc("/livez", liveness)
		http.HandleFunc("/readyz", readiness)
		http.HandleFunc("/exit", exit)
		http.HandleFunc("/", handler)
		wg.Add(1)
		defer wg.Done()
		if err := server.ListenAndServe(); err != nil {
			if err == http.ErrServerClosed {
				log.Print("web server graceful shutdown")
				return
			}
			log.Fatal(err)
		}
	}()

	// Wait for SIGINT
	<-ctx.Done()
	stop()
	log.Print("interrupt signal received, turning off readiness flag...")
	ready = false
	time.Sleep(time.Duration(shutdownWait) * time.Second)
	log.Print("initiating web server shutdown...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	server.Shutdown(ctx)

	wg.Wait()
	log.Print("shutdown successful")
}

func getEnvInt(key string) int {
	s := os.Getenv(key)
	if len(s) == 0 {
		return -1
	}
	i, err := strconv.Atoi(s)
	if err != nil {
		return -1
	}
	return i
}

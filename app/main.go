package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
)

func echo(w http.ResponseWriter, r *http.Request) {
	body, _ := io.ReadAll(r.Body)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"headers": r.Header,
		"params":  r.URL.Query(),
		"body":    string(body),
		"path":    r.URL.Path,
	})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", echo)
	log.Printf("echo service listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
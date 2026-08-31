package main

import (
	"fmt"

	"net/http"

	"os"
)

func main() {
	// Soporte para el subcomando de Docker
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		os.Exit(0) // Simula un healthcheck exitoso por ahora
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)

		w.Write([]byte("OK"))
	})

	fmt.Println("API lista en puerto 8080...")

	http.ListenAndServe(":8080", nil)
}

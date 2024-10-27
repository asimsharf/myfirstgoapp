package main

import (
	"database/sql"
	"log"
	"net/http"

	"example.com/myproject/api/handlers"
	"example.com/myproject/config"
	"example.com/myproject/internal/app"
	"example.com/myproject/internal/repository"
	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

func main() {
	cfg := config.LoadConfig()
	db, err := sql.Open("mysql", cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Could not connect to database: %v", err)
	}
	defer db.Close()

	repo := repository.NewMySQLBookRepository(db)
	service := app.NewBookService(repo)
	handler := handlers.BookHandler{Service: service}

	router := mux.NewRouter()
	router.HandleFunc("/books", handler.GetAllBooks).Methods("GET")
	router.HandleFunc("/books", handler.CreateBook).Methods("POST")
	router.HandleFunc("/books/{id}", handler.GetBook).Methods("GET")

	log.Println("Server started at :4000")
	log.Fatal(http.ListenAndServe(":4000", router))
}

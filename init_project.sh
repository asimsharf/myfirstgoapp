#!/bin/bash

# Project Name
PROJECT_NAME="myproject"

# Set up project folder and navigate into it
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Initialize Go module
go mod init "example.com/$PROJECT_NAME"

# Add dependencies
go get -u github.com/go-sql-driver/mysql
go get -u github.com/spf13/viper
go get -u github.com/gorilla/mux

# Create directory structure
mkdir -p cmd/$PROJECT_NAME api/handlers config internal/{app,domain,repository,utils} scripts

# Create .env file for environment variables
cat <<EOL > .env
DATABASE_URL="user:password@tcp(localhost:3306)/mydatabase?charset=utf8mb4&parseTime=True&loc=Local"
EOL

# Create README.md
cat <<EOL > README.md
# $PROJECT_NAME
This is a sample Golang project following a repository pattern with MySQL.

## Getting Started
1. Set up your environment variables in the .env file.
2. Run \`go run cmd/$PROJECT_NAME/main.go\` to start the server.
EOL

# config/config.go
cat <<'EOL' > config/config.go
package config

import (
    "log"
    "github.com/spf13/viper"
)

type Config struct {
    DatabaseURL string
}

func LoadConfig() Config {
    viper.SetConfigFile(".env")
    viper.AutomaticEnv()

    if err := viper.ReadInConfig(); err != nil {
        log.Fatalf("Error reading config file, %s", err)
    }

    return Config{
        DatabaseURL: viper.GetString("DATABASE_URL"),
    }
}
EOL

# internal/domain/book.go
cat <<'EOL' > internal/domain/book.go
package domain

type Book struct {
    ID     string
    Title  string
    Author string
    Year   string
}
EOL

# internal/repository/book_repository.go
cat <<'EOL' > internal/repository/book_repository.go
package repository

import "example.com/$PROJECT_NAME/internal/domain"

type BookRepository interface {
    Create(book *domain.Book) error
    GetByID(id string) (*domain.Book, error)
    GetAll() ([]domain.Book, error)
    Update(book *domain.Book) error
    Delete(id string) error
}
EOL

# internal/repository/book_repo_mysql.go
cat <<'EOL' > internal/repository/book_repo_mysql.go
package repository

import (
    "context"
    "database/sql"
    "example.com/$PROJECT_NAME/internal/domain"
)

type MySQLBookRepository struct {
    DB *sql.DB
}

func NewMySQLBookRepository(db *sql.DB) *MySQLBookRepository {
    return &MySQLBookRepository{DB: db}
}

func (r *MySQLBookRepository) Create(book *domain.Book) error {
    query := "INSERT INTO books (id, title, author, year) VALUES (?, ?, ?, ?)"
    _, err := r.DB.ExecContext(context.Background(), query, book.ID, book.Title, book.Author, book.Year)
    return err
}

func (r *MySQLBookRepository) GetByID(id string) (*domain.Book, error) {
    query := "SELECT id, title, author, year FROM books WHERE id = ?"
    row := r.DB.QueryRowContext(context.Background(), query, id)

    var book domain.Book
    if err := row.Scan(&book.ID, &book.Title, &book.Author, &book.Year); err != nil {
        return nil, err
    }

    return &book, nil
}

func (r *MySQLBookRepository) GetAll() ([]domain.Book, error) {
    query := "SELECT id, title, author, year FROM books"
    rows, err := r.DB.QueryContext(context.Background(), query)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var books []domain.Book
    for rows.Next() {
        var book domain.Book
        if err := rows.Scan(&book.ID, &book.Title, &book.Author, &book.Year); err != nil {
            return nil, err
        }
        books = append(books, book)
    }

    return books, nil
}

func (r *MySQLBookRepository) Update(book *domain.Book) error {
    query := "UPDATE books SET title=?, author=?, year=? WHERE id=?"
    _, err := r.DB.ExecContext(context.Background(), query, book.Title, book.Author, book.Year, book.ID)
    return err
}

func (r *MySQLBookRepository) Delete(id string) error {
    query := "DELETE FROM books WHERE id = ?"
    _, err := r.DB.ExecContext(context.Background(), query, id)
    return err
}
EOL

# internal/app/book_service.go
cat <<'EOL' > internal/app/book_service.go
package app

import (
    "example.com/$PROJECT_NAME/internal/domain"
    "example.com/$PROJECT_NAME/internal/repository"
)

type BookService struct {
    Repo repository.BookRepository
}

func NewBookService(repo repository.BookRepository) *BookService {
    return &BookService{Repo: repo}
}

func (s *BookService) CreateBook(book *domain.Book) error {
    return s.Repo.Create(book)
}

func (s *BookService) GetBookByID(id string) (*domain.Book, error) {
    return s.Repo.GetByID(id)
}

func (s *BookService) GetAllBooks() ([]domain.Book, error) {
    return s.Repo.GetAll()
}

func (s *BookService) UpdateBook(book *domain.Book) error {
    return s.Repo.Update(book)
}

func (s *BookService) DeleteBook(id string) error {
    return s.Repo.Delete(id)
}
EOL

# api/handlers/book_handler.go
cat <<'EOL' > api/handlers/book_handler.go
package handlers

import (
    "encoding/json"
    "net/http"
    "example.com/$PROJECT_NAME/internal/app"
    "example.com/$PROJECT_NAME/internal/domain"
    "github.com/gorilla/mux"
)

type BookHandler struct {
    Service *app.BookService
}

func (h *BookHandler) CreateBook(w http.ResponseWriter, r *http.Request) {
    var book domain.Book
    json.NewDecoder(r.Body).Decode(&book)
    if err := h.Service.CreateBook(&book); err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    json.NewEncoder(w).Encode(book)
}

func (h *BookHandler) GetBook(w http.ResponseWriter, r *http.Request) {
    id := mux.Vars(r)["id"]
    book, err := h.Service.GetBookByID(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    json.NewEncoder(w).Encode(book)
}
EOL

# cmd/myproject/main.go
cat <<'EOL' > cmd/$PROJECT_NAME/main.go
package main

import (
    "database/sql"
    "log"
    "net/http"
    "example.com/$PROJECT_NAME/api/handlers"
    "example.com/$PROJECT_NAME/config"
    "example.com/$PROJECT_NAME/internal/app"
    "example.com/$PROJECT_NAME/internal/repository"
    "github.com/gorilla/mux"
    _ "github.com/go-sql-driver/mysql"
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
    router.HandleFunc("/books", handler.CreateBook).Methods("POST")
    router.HandleFunc("/books/{id}", handler.GetBook).Methods("GET")

    log.Println("Server started at :8080")
    log.Fatal(http.ListenAndServe(":8080", router))
}
EOL

echo "Project $PROJECT_NAME initialized successfully with MySQL support!"

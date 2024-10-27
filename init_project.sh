#!/bin/bash

# Project Name
PROJECT_NAME="myproject"

# Set up project folder and navigate into it
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Initialize Go module
go mod init "example.com/$PROJECT_NAME"

# Add dependencies
go get -u gorm.io/gorm
go get -u gorm.io/driver/mysql
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
This is a sample Golang project following a repository pattern with MySQL, utilizing GORM as the ORM.

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

import (
    "gorm.io/gorm"
)

type Book struct {
    ID     string `gorm:"primaryKey"`
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

# internal/repository/book_repo_gorm.go
cat <<'EOL' > internal/repository/book_repo_gorm.go
package repository

import (
    "example.com/$PROJECT_NAME/internal/domain"
    "gorm.io/gorm"
)

type GORMBookRepository struct {
    DB *gorm.DB
}

func NewGORMBookRepository(db *gorm.DB) *GORMBookRepository {
    return &GORMBookRepository{DB: db}
}

func (r *GORMBookRepository) Create(book *domain.Book) error {
    return r.DB.Create(book).Error
}

func (r *GORMBookRepository) GetByID(id string) (*domain.Book, error) {
    var book domain.Book
    if err := r.DB.First(&book, "id = ?", id).Error; err != nil {
        return nil, err
    }
    return &book, nil
}

func (r *GORMBookRepository) GetAll() ([]domain.Book, error) {
    var books []domain.Book
    if err := r.DB.Find(&books).Error; err != nil {
        return nil, err
    }
    return books, nil
}

func (r *GORMBookRepository) Update(book *domain.Book) error {
    return r.DB.Save(book).Error
}

func (r *GORMBookRepository) Delete(id string) error {
    return r.DB.Delete(&domain.Book{}, "id = ?", id).Error
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
    "log"
    "net/http"
    "example.com/$PROJECT_NAME/api/handlers"
    "example.com/$PROJECT_NAME/config"
    "example.com/$PROJECT_NAME/internal/app"
    "example.com/$PROJECT_NAME/internal/domain"
    "example.com/$PROJECT_NAME/internal/repository"
    "github.com/gorilla/mux"
    "gorm.io/driver/mysql"
    "gorm.io/gorm"
)

func main() {
    cfg := config.LoadConfig()

    db, err := gorm.Open(mysql.Open(cfg.DatabaseURL), &gorm.Config{})
    if err != nil {
        log.Fatalf("Could not connect to database: %v", err)
    }

    // Auto migrate to create or update tables based on the domain model
    db.AutoMigrate(&domain.Book{})

    repo := repository.NewGORMBookRepository(db)
    service := app.NewBookService(repo)
    handler := handlers.BookHandler{Service: service}

    router := mux.NewRouter()
    router.HandleFunc("/books", handler.CreateBook).Methods("POST")
    router.HandleFunc("/books/{id}", handler.GetBook).Methods("GET")

    log.Println("Server started at :8080")
    log.Fatal(http.ListenAndServe(":8080", router))
}
EOL

echo "Project $PROJECT_NAME initialized successfully with GORM support and best practices!"

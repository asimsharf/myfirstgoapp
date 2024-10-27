package handlers

import (
	"encoding/json"
	"net/http"

	"example.com/myproject/internal/app"
	"example.com/myproject/internal/domain"
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

// get alll books
func (h *BookHandler) GetAllBooks(w http.ResponseWriter, r *http.Request) {
	books, err := h.Service.GetAllBooks()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(books)
}

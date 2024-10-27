package repository

import "example.com/myproject/internal/domain"

type BookRepository interface {
	Create(book *domain.Book) error
	GetByID(id string) (*domain.Book, error)
	GetAll() ([]domain.Book, error)
	Update(book *domain.Book) error
	Delete(id string) error
}

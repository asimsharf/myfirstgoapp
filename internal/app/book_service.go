package app

import (
	"example.com/myproject/internal/domain"
	"example.com/myproject/internal/repository"
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

package repository

import (
	"context"
	"database/sql"

	"example.com/myproject/internal/domain"
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

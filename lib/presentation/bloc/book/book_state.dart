import 'package:equatable/equatable.dart';
import '../../../domain/entities/book.dart';

class BookState extends Equatable {
  final List<Book> books;
  final Book? selectedBook;
  final String? category;
  final String? bookContent;
  final bool isLoading;
  final String? error;

  const BookState({
    this.books = const [],
    this.selectedBook,
    this.category,
    this.bookContent,
    this.isLoading = false,
    this.error,
  });

  BookState copyWith({
    List<Book>? books,
    Book? selectedBook,
    String? category,
    String? bookContent,
    bool? isLoading,
    String? error,
  }) {
    return BookState(
      books: books ?? this.books,
      selectedBook: selectedBook ?? this.selectedBook,
      category: category ?? this.category,
      bookContent: bookContent ?? this.bookContent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [books, selectedBook, category, bookContent, isLoading, error];
}

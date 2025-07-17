import 'package:equatable/equatable.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/reading_progress.dart';

class BookState extends Equatable {
  final List<Book> books;
  final Book? selectedBook;
  final String? category;
  final String? bookContent;
  final bool isLoading;
  final String? error;
  final List<String> bookContentChunks;
  final int currentChunkIndex;
  final bool hasMoreContent;
  final List<Book> currentlyReadingBooks;
  final ReadingProgress? readingProgress;
  final List<Book> editions;
  final Book? bestReadableEdition;

  const BookState({
    this.books = const [],
    this.selectedBook,
    this.category,
    this.bookContent,
    this.isLoading = false,
    this.error,
    this.bookContentChunks = const [],
    this.currentChunkIndex = 0,
    this.hasMoreContent = false,
    this.currentlyReadingBooks = const [],
    this.readingProgress,
    this.editions = const [],
    this.bestReadableEdition,
  });

  BookState copyWith({
    List<Book>? books,
    Book? selectedBook,
    String? category,
    String? bookContent,
    bool? isLoading,
    String? error,
    List<String>? bookContentChunks,
    int? currentChunkIndex,
    bool? hasMoreContent,
    List<Book>? currentlyReadingBooks,
    ReadingProgress? readingProgress,
    List<Book>? editions,
    Book? bestReadableEdition,
  }) {
    return BookState(
      books: books ?? this.books,
      selectedBook: selectedBook ?? this.selectedBook,
      category: category ?? this.category,
      bookContent: bookContent ?? this.bookContent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookContentChunks: bookContentChunks ?? this.bookContentChunks,
      currentChunkIndex: currentChunkIndex ?? this.currentChunkIndex,
      hasMoreContent: hasMoreContent ?? this.hasMoreContent,
      currentlyReadingBooks:
          currentlyReadingBooks ?? this.currentlyReadingBooks,
      readingProgress: readingProgress ?? this.readingProgress,
      editions: editions ?? this.editions,
      bestReadableEdition: bestReadableEdition ?? this.bestReadableEdition,
    );
  }

  @override
  List<Object?> get props => [
        books,
        selectedBook,
        category,
        bookContent,
        isLoading,
        error,
        bookContentChunks,
        currentChunkIndex,
        hasMoreContent,
        currentlyReadingBooks,
        readingProgress,
        editions,
        bestReadableEdition,
      ];
}

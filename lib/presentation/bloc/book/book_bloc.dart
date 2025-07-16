import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_books_by_topic.dart';
import '../../../domain/usecases/search_books.dart';
import '../../../domain/usecases/get_book_content.dart';
import '../../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../../domain/repositories/book_repository.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final GetBooksByTopic getBooksByTopic;
  final SearchBooks searchBooks;
  final GetBookContent getBookContent;
  final GetBookContentByGutenbergId getBookContentByGutenbergId;
  final BookRepository bookRepository;

  BookBloc({
    required this.getBooksByTopic,
    required this.searchBooks,
    required this.getBookContent,
    required this.getBookContentByGutenbergId,
    required this.bookRepository,
  }) : super(BookInitial()) {
    on<LoadBooksByTopic>(_onLoadBooksByTopic);
    on<SearchBooksEvent>(_onSearchBooks);
    on<LoadBookById>(_onLoadBookById);
    on<LoadBooksByPage>(_onLoadBooksByPage);
    on<LoadBookContent>(_onLoadBookContent);
    on<LoadBookContentByGutenbergId>(_onLoadBookContentByGutenbergId);
  }

  Future<void> _onLoadBooksByTopic(
    LoadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());
    try {
      final books = await getBooksByTopic(event.topic);
      emit(BooksLoaded(books, category: event.topic));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _onSearchBooks(
    SearchBooksEvent event,
    Emitter<BookState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const BooksLoaded([]));
      return;
    }

    emit(BookLoading());
    try {
      final books = await searchBooks(event.query);
      emit(BooksLoaded(books));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _onLoadBookById(
    LoadBookById event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());
    try {
      final book = await bookRepository.getBookById(event.bookId);
      if (book != null) {
        emit(BookLoaded(book));
      } else {
        emit(const BookError('Book not found'));
      }
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _onLoadBooksByPage(
    LoadBooksByPage event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());
    try {
      final books = await bookRepository.getBooksByPage(event.page);
      emit(BooksLoaded(books));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _onLoadBookContent(
    LoadBookContent event,
    Emitter<BookState> emit,
  ) async {
    emit(BookContentLoading());
    try {
      final content = await getBookContent(event.textUrl);
      emit(BookContentLoaded(content));
    } catch (e) {
      emit(BookContentError(e.toString()));
    }
  }

  Future<void> _onLoadBookContentByGutenbergId(
    LoadBookContentByGutenbergId event,
    Emitter<BookState> emit,
  ) async {
    emit(BookContentLoading());
    try {
      final content = await getBookContentByGutenbergId(event.gutenbergId);
      emit(BookContentLoaded(content));
    } catch (e) {
      emit(BookContentError(e.toString()));
    }
  }
}

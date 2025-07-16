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
  }) : super(const BookState()) {
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
    emit(state.copyWith(isLoading: true, error: null, category: event.topic));
    try {
      final books = await getBooksByTopic(event.topic);
      emit(state.copyWith(
        books: books,
        isLoading: false,
        error: null,
        category: event.topic,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSearchBooks(
    SearchBooksEvent event,
    Emitter<BookState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(state.copyWith(books: [], isLoading: false, error: null));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final books = await searchBooks(event.query);
      emit(state.copyWith(books: books, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBookById(
    LoadBookById event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final book = await bookRepository.getBookById(event.bookId);
      if (book != null) {
        emit(state.copyWith(selectedBook: book, isLoading: false, error: null));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Book not found'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBooksByPage(
    LoadBooksByPage event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final books = await bookRepository.getBooksByPage(event.page);
      emit(state.copyWith(books: books, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBookContent(
    LoadBookContent event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final content = await getBookContent(event.textUrl);
      emit(state.copyWith(bookContent: content, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBookContentByGutenbergId(
    LoadBookContentByGutenbergId event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final content = await getBookContentByGutenbergId(event.gutenbergId);
      emit(state.copyWith(bookContent: content, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}

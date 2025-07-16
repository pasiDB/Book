import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_books_by_topic.dart';
import '../../../domain/usecases/search_books.dart';
import '../../../domain/usecases/get_book_content.dart';
import '../../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../data/repositories/book_repository_impl.dart';
import '../../../data/models/book_model.dart';
import 'book_event.dart';
import 'book_state.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../domain/repositories/reading_repository.dart';
import '../../../domain/entities/book.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:async';

class BookBloc extends Bloc<BookEvent, BookState> {
  final GetBooksByTopic getBooksByTopic;
  final SearchBooks searchBooks;
  final GetBookContent getBookContent;
  final GetBookContentByGutenbergId getBookContentByGutenbergId;
  final BookRepository bookRepository;

  // In-memory cache for books by category
  final Map<String, List<Book>> _booksByCategoryCache = {};

  BookBloc({
    required this.getBooksByTopic,
    required this.searchBooks,
    required this.getBookContent,
    required this.getBookContentByGutenbergId,
    required this.bookRepository,
  }) : super(const BookState()) {
    on<LoadBooksByTopic>(_onLoadBooksByTopic);
    on<PreloadBooksByTopic>(_onPreloadBooksByTopic);
    on<SearchBooksEvent>(_onSearchBooks);
    on<LoadBookById>(_onLoadBookById);
    on<LoadBooksByPage>(_onLoadBooksByPage);
    on<LoadBookContent>(_onLoadBookContent);
    on<LoadBookContentByGutenbergId>(_onLoadBookContentByGutenbergId);
    on<LoadBookContentChunk>(_onLoadBookContentChunk);
    on<AddBookToLibrary>(_onAddBookToLibrary);
    on<LoadCurrentlyReadingBooks>(_onLoadCurrentlyReadingBooks);
    on<LoadReadingProgress>(_onLoadReadingProgress);
    on<SaveReadingProgress>(_onSaveReadingProgress);
  }

  Future<void> _onPreloadBooksByTopic(
    PreloadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    if (_booksByCategoryCache.containsKey(event.topic)) return;
    try {
      final books = await getBooksByTopic(event.topic);
      _booksByCategoryCache[event.topic] = books;
    } catch (_) {}
  }

  static const int _chunkSize = 3000;

  List<String> _splitContentIntoChunks(String content) {
    List<String> chunks = [];
    int start = 0;
    while (start < content.length) {
      int end = (start + _chunkSize < content.length)
          ? start + _chunkSize
          : content.length;
      chunks.add(content.substring(start, end));
      start = end;
    }
    return chunks;
  }

  Future<void> _onLoadBooksByTopic(
    LoadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, category: event.topic));
    // Check cache first
    if (_booksByCategoryCache.containsKey(event.topic)) {
      emit(state.copyWith(
        books: _booksByCategoryCache[event.topic]!,
        isLoading: false,
        error: null,
        category: event.topic,
      ));
      return;
    }
    try {
      final books = await getBooksByTopic(event.topic);
      // Cache the result
      _booksByCategoryCache[event.topic] = books;
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
    print('[BLoC] Loading book content for URL: ${event.textUrl}');
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final content = await getBookContent(event.textUrl);
      print('[BLoC] Book content loaded, length: ${content.length}');
      final chunks = _splitContentIntoChunks(content);
      emit(state.copyWith(
        bookContent: chunks.isNotEmpty ? chunks[0] : '',
        bookContentChunks: chunks,
        currentChunkIndex: 0,
        hasMoreContent: chunks.length > 1,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      print('[BLoC] Error loading book content: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBookContentByGutenbergId(
    LoadBookContentByGutenbergId event,
    Emitter<BookState> emit,
  ) async {
    print('[BLoC] Loading book content by Gutenberg ID: ${event.gutenbergId}');
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final content = await getBookContentByGutenbergId(event.gutenbergId);
      print(
          '[BLoC] Book content loaded by Gutenberg ID, length: ${content.length}');
      final chunks = _splitContentIntoChunks(content);
      emit(state.copyWith(
        bookContent: chunks.isNotEmpty ? chunks[0] : '',
        bookContentChunks: chunks,
        currentChunkIndex: 0,
        hasMoreContent: chunks.length > 1,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      print('[BLoC] Error loading book content by Gutenberg ID: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadBookContentChunk(
    LoadBookContentChunk event,
    Emitter<BookState> emit,
  ) async {
    print('[BLoC] Loading book content chunk: ${event.chunkIndex}');
    final chunks = state.bookContentChunks;
    final nextIndex = event.chunkIndex;
    if (nextIndex < chunks.length) {
      final newContent = chunks.sublist(0, nextIndex + 1).join('');
      emit(state.copyWith(
        bookContent: newContent,
        currentChunkIndex: nextIndex,
        hasMoreContent: nextIndex < chunks.length - 1,
      ));
      print('[BLoC] Book content chunk loaded, up to chunk: $nextIndex');
    } else {
      print('[BLoC] No more chunks to load.');
    }
  }

  Future<void> _onAddBookToLibrary(
    AddBookToLibrary event,
    Emitter<BookState> emit,
  ) async {
    // Load current list
    final localDataSource = bookRepository is BookRepositoryImpl
        ? (bookRepository as BookRepositoryImpl).localDataSource
        : null;
    if (localDataSource == null) return;
    final currentBooks = await localDataSource.getCurrentlyReadingBooks();
    // Avoid duplicates
    if (!currentBooks.any((b) => b.id == event.book.id)) {
      final updatedBooks = List<BookModel>.from(currentBooks)
        ..add(BookModel.fromJson((event.book as BookModel).toJson()));
      await localDataSource.saveCurrentlyReadingBooks(updatedBooks);
      emit(state.copyWith(currentlyReadingBooks: updatedBooks));
    }
  }

  Future<void> _onLoadCurrentlyReadingBooks(
    LoadCurrentlyReadingBooks event,
    Emitter<BookState> emit,
  ) async {
    final localDataSource = bookRepository is BookRepositoryImpl
        ? (bookRepository as BookRepositoryImpl).localDataSource
        : null;
    if (localDataSource == null) return;
    final books = await localDataSource.getCurrentlyReadingBooks();
    emit(state.copyWith(currentlyReadingBooks: books));
  }

  Future<void> _onLoadReadingProgress(
    LoadReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    // Use repository to load progress
    ReadingProgress? progress;
    if (bookRepository is ReadingRepository) {
      progress = await (bookRepository as ReadingRepository)
          .getReadingProgress(event.bookId);
    }
    emit(state.copyWith(readingProgress: progress));
  }

  Future<void> _onSaveReadingProgress(
    SaveReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    if (bookRepository is ReadingRepository) {
      await (bookRepository as ReadingRepository).updateCurrentPosition(
        event.bookId,
        event.chunkIndex,
        0.0,
        event.scrollOffset,
      );
      final progress = await (bookRepository as ReadingRepository)
          .getReadingProgress(event.bookId);
      emit(state.copyWith(readingProgress: progress));
    }
  }

  // Public method to get cached books for a category
  List<Book>? getCachedBooksForCategory(String category) {
    return _booksByCategoryCache[category];
  }

  // Optimized method to preload all categories and set state for default
  Future<void> preloadAllCategoriesAndSetDefault() async {
    final categories = AppConstants.bookCategories;
    final futures = <Future<void>>[];
    for (final category in categories) {
      if (!_booksByCategoryCache.containsKey(category)) {
        futures.add(getBooksByTopic(category).then((books) {
          _booksByCategoryCache[category] = books;
        }).catchError((_) {}));
      }
    }
    await Future.wait(futures);
    // Set state for default category
    final defaultCategory = categories.first;
    final cachedBooks = _booksByCategoryCache[defaultCategory];
    if (cachedBooks != null && cachedBooks.isNotEmpty) {
      emit(state.copyWith(
        books: cachedBooks,
        isLoading: false,
        category: defaultCategory,
      ));
    }
  }
}

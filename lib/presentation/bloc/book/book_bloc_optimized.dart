import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../domain/usecases/get_books_by_topic.dart';
import '../../../domain/usecases/search_books.dart';
import '../../../domain/usecases/get_book_content.dart';
import '../../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../domain/entities/book.dart';

import '../../../core/constants/app_constants.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBlocOptimized extends Bloc<BookEvent, BookState> {
  final GetBooksByTopic _getBooksByTopic;
  final GetBooksByTopicWithPagination _getBooksByTopicWithPagination;
  final SearchBooks _searchBooks;
  final GetBookContent _getBookContent;
  final GetBookContentByGutenbergId _getBookContentByGutenbergId;
  final BookRepository _bookRepository;

  // In-memory cache for books by category
  final Map<String, List<Book>> _booksByCategoryCache = {};
  final Map<String, List<Book>> _allBooksByCategoryCache = {};

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  BookBlocOptimized({
    required GetBooksByTopic getBooksByTopic,
    required GetBooksByTopicWithPagination getBooksByTopicWithPagination,
    required SearchBooks searchBooks,
    required GetBookContent getBookContent,
    required GetBookContentByGutenbergId getBookContentByGutenbergId,
    required BookRepository bookRepository,
  })  : _getBooksByTopic = getBooksByTopic,
        _getBooksByTopicWithPagination = getBooksByTopicWithPagination,
        _searchBooks = searchBooks,
        _getBookContent = getBookContent,
        _getBookContentByGutenbergId = getBookContentByGutenbergId,
        _bookRepository = bookRepository,
        super(const BookState()) {
    on<LoadBooksByTopic>(_onLoadBooksByTopic);
    on<PreloadBooksByTopic>(_onPreloadBooksByTopic);
    on<LoadMoreBooks>(_onLoadMoreBooks);
    on<SearchBooksEvent>(_onSearchBooks);
    on<LoadBookById>(_onLoadBookById);
    on<LoadBookContent>(_onLoadBookContent);
    on<LoadBookContentByGutenbergId>(_onLoadBookContentByGutenbergId);
    on<LoadBookContentChunk>(_onLoadBookContentChunk);
    on<AddBookToLibrary>(_onAddBookToLibrary);
    on<LoadCurrentlyReadingBooks>(_onLoadCurrentlyReadingBooks);
    on<LoadReadingProgress>(_onLoadReadingProgress);
    on<SaveReadingProgress>(_onSaveReadingProgress);
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }

  // Public methods for external access
  List<Book>? getCachedBooksForCategory(String category) {
    return _booksByCategoryCache[category];
  }

  Future<void> loadDefaultCategoryAndSetState() async {
    if (AppConstants.bookCategories.isEmpty) return;

    final defaultCategory = AppConstants.bookCategories.first;
    await _loadBooksByTopic(defaultCategory);
  }

  Future<void> preloadOtherCategoriesInBackground() async {
    if (AppConstants.bookCategories.length <= 1) return;

    final categoriesToPreload = AppConstants.bookCategories.skip(1);

    // Preload categories in parallel
    final futures =
        categoriesToPreload.map((category) => _preloadBooksByTopic(category));

    try {
      await Future.wait(futures);
      print('✅ All categories preloaded successfully');
    } catch (e) {
      print('❌ Error preloading categories: $e');
    }
  }

  // Event handlers
  Future<void> _onLoadBooksByTopic(
    LoadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    await _loadBooksByTopic(event.topic);
  }

  Future<void> _onPreloadBooksByTopic(
    PreloadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    await _preloadBooksByTopic(event.topic);
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BookState> emit,
  ) async {
    final currentState = state;
    final category = currentState.category;
    if (category == null) return;

    try {
      final allBooks = _allBooksByCategoryCache[category];
      if (allBooks == null) return;

      final currentCount = currentState.books.length;
      final nextBatch = allBooks.skip(currentCount).take(10).toList();

      if (nextBatch.isNotEmpty) {
        emit(currentState.copyWith(
          books: [...currentState.books, ...nextBatch],
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        error: 'Failed to load more books: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onSearchBooks(
    SearchBooksEvent event,
    Emitter<BookState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(state.copyWith(
        books: [],
        error: null,
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final books = await _searchBooks(event.query);
      emit(state.copyWith(
        books: books,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Search failed: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadBookById(
    LoadBookById event,
    Emitter<BookState> emit,
  ) async {
    try {
      final book = await _bookRepository.getBookById(event.bookId);
      if (book != null) {
        emit(state.copyWith(
          selectedBook: book,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          error: 'Book not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load book: $e',
      ));
    }
  }

  Future<void> _onLoadBookContent(
    LoadBookContent event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final content = await _getBookContent(event.textUrl);
      final chunks = _splitContentIntoChunks(content);

      emit(state.copyWith(
        bookContent: content,
        bookContentChunks: chunks,
        currentChunkIndex: 0,
        hasMoreContent: chunks.length > 1,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load book content: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadBookContentByGutenbergId(
    LoadBookContentByGutenbergId event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final content = await _getBookContentByGutenbergId(event.gutenbergId);
      final chunks = _splitContentIntoChunks(content);

      emit(state.copyWith(
        bookContent: content,
        bookContentChunks: chunks,
        currentChunkIndex: 0,
        hasMoreContent: chunks.length > 1,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load book content: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadBookContentChunk(
    LoadBookContentChunk event,
    Emitter<BookState> emit,
  ) async {
    final currentState = state;
    final chunks = currentState.bookContentChunks;

    if (event.chunkIndex >= 0 && event.chunkIndex < chunks.length) {
      emit(currentState.copyWith(
        currentChunkIndex: event.chunkIndex,
        hasMoreContent: event.chunkIndex < chunks.length - 1,
      ));
    }
  }

  Future<void> _onAddBookToLibrary(
    AddBookToLibrary event,
    Emitter<BookState> emit,
  ) async {
    // Implementation for adding book to library
    // This would typically involve saving to local storage
  }

  Future<void> _onLoadCurrentlyReadingBooks(
    LoadCurrentlyReadingBooks event,
    Emitter<BookState> emit,
  ) async {
    // Implementation for loading currently reading books
  }

  Future<void> _onLoadReadingProgress(
    LoadReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    // Implementation for loading reading progress
  }

  Future<void> _onSaveReadingProgress(
    SaveReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    // Implementation for saving reading progress
  }

  // Private helper methods
  Future<void> _loadBooksByTopic(String topic) async {
    // Check cache first
    final cachedBooks = _booksByCategoryCache[topic];
    if (cachedBooks != null && cachedBooks.isNotEmpty) {
      emit(state.copyWith(
        books: cachedBooks.take(10).toList(),
        category: topic,
        isLoading: false,
        error: null,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final books = await _getBooksByTopic(topic);

      // Cache the books
      _booksByCategoryCache[topic] = books;
      _allBooksByCategoryCache[topic] = books;

      emit(state.copyWith(
        books: books.take(10).toList(),
        category: topic,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load books: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _preloadBooksByTopic(String topic) async {
    if (_booksByCategoryCache.containsKey(topic)) return;

    try {
      final books = await _getBooksByTopic(topic);
      _booksByCategoryCache[topic] = books;
      _allBooksByCategoryCache[topic] = books;
      print('✅ Preloaded $topic: ${books.length} books');
    } catch (e) {
      print('❌ Failed to preload $topic: $e');
    }
  }

  List<String> _splitContentIntoChunks(String content) {
    const int chunkSize = 3000;
    List<String> chunks = [];
    int start = 0;

    while (start < content.length) {
      int end = (start + chunkSize < content.length)
          ? start + chunkSize
          : content.length;
      chunks.add(content.substring(start, end));
      start = end;
    }

    return chunks;
  }
}

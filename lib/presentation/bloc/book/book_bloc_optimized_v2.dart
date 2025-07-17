import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:isolate';
import '../../../domain/usecases/get_books_by_topic.dart';
import '../../../domain/usecases/search_books.dart';
import '../../../domain/usecases/get_book_content.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../domain/entities/book.dart';

import '../../../core/constants/app_constants.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBlocOptimizedV2 extends Bloc<BookEvent, BookState> {
  final GetBooksByTopic _getBooksByTopic;
  final GetBooksByTopicWithPagination _getBooksByTopicWithPagination;
  final SearchBooks _searchBooks;
  final GetBookContent _getBookContent;
  final BookRepository _bookRepository;

  // Enhanced in-memory cache with TTL
  final Map<String, _CacheEntry> _booksByCategoryCache = {};
  final Map<String, List<Book>> _allBooksByCategoryCache = {};

  // Background processing
  final List<StreamSubscription> _subscriptions = [];
  final List<Future<void>> _backgroundTasks = [];

  // Performance tracking
  final Map<String, DateTime> _lastFetchTimes = {};
  static const Duration _minFetchInterval = Duration(minutes: 5);

  BookBlocOptimizedV2({
    required GetBooksByTopic getBooksByTopic,
    required GetBooksByTopicWithPagination getBooksByTopicWithPagination,
    required SearchBooks searchBooks,
    required GetBookContent getBookContent,
    required BookRepository bookRepository,
  })  : _getBooksByTopic = getBooksByTopic,
        _getBooksByTopicWithPagination = getBooksByTopicWithPagination,
        _searchBooks = searchBooks,
        _getBookContent = getBookContent,
        _bookRepository = bookRepository,
        super(const BookState()) {
    on<LoadBooksByTopic>(_onLoadBooksByTopic);
    on<PreloadBooksByTopic>(_onPreloadBooksByTopic);
    on<LoadMoreBooks>(_onLoadMoreBooks);
    on<SearchBooksEvent>(_onSearchBooks);
    on<LoadBookById>(_onLoadBookById);
    on<LoadBookContent>(_onLoadBookContent);
    on<LoadBookContentChunk>(_onLoadBookContentChunk);
    on<AddBookToLibrary>(_onAddBookToLibrary);
    on<LoadCurrentlyReadingBooks>(_onLoadCurrentlyReadingBooks);
    on<LoadReadingProgress>(_onLoadReadingProgress);
    on<SaveReadingProgress>(_onSaveReadingProgress);
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions and background tasks
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Wait for background tasks to complete
    Future.wait(_backgroundTasks);

    return super.close();
  }

  // Public methods for external access
  List<Book>? getCachedBooksForCategory(String category) {
    final entry = _booksByCategoryCache[category];
    if (entry != null && !_isExpired(entry.timestamp)) {
      return entry.books;
    }
    return null;
  }

  Future<void> loadDefaultCategoryAndSetState() async {
    if (AppConstants.bookCategories.isEmpty) return;

    final defaultCategory = AppConstants.bookCategories.first;
    await _loadBooksByTopic(defaultCategory);
  }

  Future<void> preloadOtherCategoriesInBackground() async {
    if (AppConstants.bookCategories.length <= 1) return;

    final categoriesToPreload = AppConstants.bookCategories.skip(1);

    // Preload categories in parallel with rate limiting
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
      final book = await _bookRepository.getBookById(event.workKey);
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

    Future<void> _onLoadBookContentChunk(
    LoadBookContentChunk event,
    Emitter<BookState> emit,
  ) async {
    final currentState = state;
    final chunks = currentState.bookContentChunks;

    if (chunks.isEmpty || event.chunkIndex >= chunks.length) {
      return;
    }

    emit(currentState.copyWith(
      currentChunkIndex: event.chunkIndex,
      hasMoreContent: event.chunkIndex < chunks.length - 1,
    ));
  }

  Future<void> _onAddBookToLibrary(
    AddBookToLibrary event,
    Emitter<BookState> emit,
  ) async {
    try {
      // TODO: Implement addBookToLibrary in repository
      emit(state.copyWith(
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to add book to library: $e',
      ));
    }
  }

  Future<void> _onLoadCurrentlyReadingBooks(
    LoadCurrentlyReadingBooks event,
    Emitter<BookState> emit,
  ) async {
    try {
      // TODO: Implement getCurrentlyReadingBooks in repository
      emit(state.copyWith(
        currentlyReadingBooks: [],
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load currently reading books: $e',
      ));
    }
  }

  Future<void> _onLoadReadingProgress(
    LoadReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    try {
      // TODO: Implement getReadingProgress in repository
      emit(state.copyWith(
        readingProgress: null,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load reading progress: $e',
      ));
    }
  }

  Future<void> _onSaveReadingProgress(
    SaveReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    try {
      // TODO: Implement saveReadingProgress in repository
      emit(state.copyWith(
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to save reading progress: $e',
      ));
    }
  }

  // Private methods
  Future<void> _loadBooksByTopic(String topic) async {
    // Check if we should fetch from API (rate limiting)
    final lastFetch = _lastFetchTimes[topic];
    if (lastFetch != null &&
        DateTime.now().difference(lastFetch) < _minFetchInterval) {
      print('⏱️ Rate limited for topic: $topic');
      return;
    }

    // Check cache first
    final cachedBooks = getCachedBooksForCategory(topic);
    if (cachedBooks != null) {
      emit(state.copyWith(
        books: cachedBooks,
        category: topic,
        isLoading: false,
        error: null,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final books = await _getBooksByTopic(topic);

      // Cache the results
      _booksByCategoryCache[topic] = _CacheEntry(books, DateTime.now());
      _allBooksByCategoryCache[topic] = books;
      _lastFetchTimes[topic] = DateTime.now();

      emit(state.copyWith(
        books: books,
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
    try {
      final books = await _getBooksByTopic(topic);
      _booksByCategoryCache[topic] = _CacheEntry(books, DateTime.now());
      _allBooksByCategoryCache[topic] = books;
      print('✅ Preloaded category: $topic (${books.length} books)');
    } catch (e) {
      print('❌ Failed to preload category: $topic - $e');
    }
  }

  Future<void> _preloadPopularBooksInBackground() async {
    try {
      // Preload books from popular categories
      final popularCategories = ['fiction', 'science', 'history'];

      for (final category in popularCategories) {
        await _preloadBooksByTopic(category);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ Error preloading popular books: $e');
    }
  }

  List<String> _splitContentIntoChunks(String content) {
    const chunkSize = 5000; // characters per chunk
    final chunks = <String>[];

    for (int i = 0; i < content.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, content.length);
      chunks.add(content.substring(i, end));
    }

    return chunks;
  }

  bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > const Duration(hours: 1);
  }
}

class _CacheEntry {
  final List<Book> books;
  final DateTime timestamp;

  _CacheEntry(this.books, this.timestamp);
}

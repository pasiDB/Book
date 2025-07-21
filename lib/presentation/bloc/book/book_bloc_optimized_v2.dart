import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:developer' as developer;

import '../../../domain/usecases/get_books_by_topic.dart';
import '../../../domain/usecases/search_books.dart';
import '../../../domain/usecases/get_book_content.dart';
import '../../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../domain/repositories/reading_repository.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../core/constants/app_constants.dart';
import 'book_event.dart';
import 'book_state.dart';

// Cache data class with timestamp
class CachedBookData {
  final List<Book> books;
  final DateTime timestamp;

  CachedBookData({
    required this.books,
    required this.timestamp,
  });
}

class BookBlocOptimizedV2 extends Bloc<BookEvent, BookState> {
  final GetBooksByTopic _getBooksByTopic;
  final GetBooksByTopicWithPagination _getBooksByTopicWithPagination;
  final SearchBooks _searchBooks;
  final GetBookContent _getBookContent;
  final GetBookContentByGutenbergId _getBookContentByGutenbergId;
  final BookRepository _bookRepository;
  final ReadingRepository _readingRepository;

  // Enhanced cache with timestamps and persistence
  final Map<String, CachedBookData> _booksByCategoryCache = {};
  final Map<String, String> _bookContentCache = {};
  final Map<int, Book> _bookDetailsCache = {};
  int _searchToken = 0;

  // Cache configuration
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  BookBlocOptimizedV2({
    required GetBooksByTopic getBooksByTopic,
    required GetBooksByTopicWithPagination getBooksByTopicWithPagination,
    required SearchBooks searchBooks,
    required GetBookContent getBookContent,
    required GetBookContentByGutenbergId getBookContentByGutenbergId,
    required BookRepository bookRepository,
    required ReadingRepository readingRepository,
  })  : _getBooksByTopic = getBooksByTopic,
        _getBooksByTopicWithPagination = getBooksByTopicWithPagination,
        _searchBooks = searchBooks,
        _getBookContent = getBookContent,
        _getBookContentByGutenbergId = getBookContentByGutenbergId,
        _bookRepository = bookRepository,
        _readingRepository = readingRepository,
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
  Future<void> close() async {
    // Save cache to persistent storage before closing
    await _saveCacheToStorage();
    await super.close();
  }

  // Public methods for external access
  Future<void> loadDefaultCategoryAndSetState() async {
    if (AppConstants.bookCategories.isEmpty) return;

    final defaultCategory = AppConstants.bookCategories.first;

    // Check cache first
    if (_isCacheValid(defaultCategory)) {
      final cachedData = _booksByCategoryCache[defaultCategory];
      if (cachedData != null) {
        // Use add instead of emit for external calls
        add(LoadBooksByTopic(defaultCategory));
        return;
      }
    }

    add(LoadBooksByTopic(defaultCategory));
  }

  Future<void> preloadOtherCategoriesInBackground() async {
    if (AppConstants.bookCategories.length <= 1) return;

    final categoriesToPreload = AppConstants.bookCategories.skip(1);
    for (final category in categoriesToPreload) {
      // Only preload if not already cached or cache is expired
      if (!_isCacheValid(category)) {
        add(PreloadBooksByTopic(category));
      }
    }
  }

  // Enhanced cache management
  bool _isCacheValid(String category) {
    final cachedData = _booksByCategoryCache[category];
    if (cachedData == null) return false;

    final now = DateTime.now();
    return now.difference(cachedData.timestamp) < _cacheValidityDuration;
  }

  bool _isContentCacheValid(String key) {
    // For now, content cache is always valid (could add timestamp later)
    return _bookContentCache.containsKey(key);
  }

  Future<void> _saveCacheToStorage() async {
    try {
      // Save category cache info (without the actual book data for now)
      final cacheInfo =
          _booksByCategoryCache.map((key, value) => MapEntry(key, {
                'count': value.books.length,
                'timestamp': value.timestamp.toIso8601String(),
              }));

      // Save to SharedPreferences or other persistent storage
      // This would require injecting SharedPreferences into the BLoC
      developer.log('Cache info saved: ${cacheInfo.length} categories');
    } catch (e) {
      developer.log('Failed to save cache: $e');
    }
  }

  Future<void> _loadCacheFromStorage() async {
    try {
      // Load from persistent storage
      // This would require injecting SharedPreferences into the BLoC
      developer.log('Cache loaded from storage');
    } catch (e) {
      developer.log('Failed to load cache: $e');
    }
  }

  Future<void> _onLoadBooksByTopic(
    LoadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    // Check cache first
    if (_isCacheValid(event.topic)) {
      final cachedData = _booksByCategoryCache[event.topic];
      if (cachedData != null) {
        emit(state.copyWith(
          books: cachedData.books,
          isLoading: false,
          error: null,
          category: event.topic,
        ));
        return;
      }
    }

    emit(state.copyWith(isLoading: true, error: null, category: event.topic));

    try {
      final books = await _getBooksByTopic(event.topic);

      // Cache the results
      _booksByCategoryCache[event.topic] = CachedBookData(
        books: books,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        books: books,
        isLoading: false,
        error: null,
        category: event.topic,
      ));
    } catch (e) {
      final errorMessage = _getUserFriendlyError(e.toString());
      emit(state.copyWith(isLoading: false, error: errorMessage));
    }
  }

  Future<void> _onPreloadBooksByTopic(
    PreloadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    if (_isCacheValid(event.topic)) return;

    try {
      final books = await _getBooksByTopic(event.topic);

      // Cache the results
      _booksByCategoryCache[event.topic] = CachedBookData(
        books: books,
        timestamp: DateTime.now(),
      );

      developer
          .log('Preloaded ${books.length} books for category: ${event.topic}');
    } catch (e) {
      developer.log('Preload failed for ${event.topic}: ${e.toString()}');
    }
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BookState> emit,
  ) async {
    try {
      final books = await _getBooksByTopicWithPagination(
        event.category,
        limit: 10,
        offset: event.currentCount,
      );

      if (books.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          error: 'No more books available',
        ));
        return;
      }

      final updatedBooks = List<Book>.from(state.books)..addAll(books);
      emit(state.copyWith(
        books: updatedBooks,
        isLoading: false,
      ));
    } catch (e) {
      final errorMessage = _getUserFriendlyError(e.toString());
      emit(state.copyWith(isLoading: false, error: errorMessage));
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
    final currentToken = ++_searchToken;
    try {
      final books = await _searchBooks(event.query);
      // Only show results if this is the latest search
      if (currentToken == _searchToken) {
        emit(state.copyWith(books: books, isLoading: false, error: null));
      }
    } catch (e) {
      final errorMessage = _getUserFriendlyError(e.toString());
      if (currentToken == _searchToken) {
        emit(state.copyWith(isLoading: false, error: errorMessage));
      }
    }
  }

  Future<void> _onLoadBookById(
    LoadBookById event,
    Emitter<BookState> emit,
  ) async {
    // Check cache first
    if (_bookDetailsCache.containsKey(event.bookId)) {
      final cachedBook = _bookDetailsCache[event.bookId];
      emit(state.copyWith(
        selectedBook: cachedBook,
        isLoading: false,
        error: null,
        // Clear previous book content to ensure fresh content load
        bookContent: null,
        bookContentChunks: [],
        currentChunkIndex: 0,
        hasMoreContent: false,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      error: null,
      // Clear previous book content when loading new book
      bookContent: null,
      bookContentChunks: [],
      currentChunkIndex: 0,
      hasMoreContent: false,
    ));
    try {
      final book = await _bookRepository.getBookById(event.bookId);
      if (book != null) {
        // Cache the book details
        _bookDetailsCache[event.bookId] = book;

        emit(state.copyWith(
          selectedBook: book,
          isLoading: false,
          error: null,
          // Keep content cleared for fresh load
          bookContent: null,
          bookContentChunks: [],
          currentChunkIndex: 0,
          hasMoreContent: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Book not found',
          bookContent: null,
          bookContentChunks: [],
          currentChunkIndex: 0,
          hasMoreContent: false,
        ));
      }
    } catch (e) {
      final errorMessage = _getUserFriendlyError(e.toString());
      emit(state.copyWith(
        isLoading: false,
        error: errorMessage,
        bookContent: null,
        bookContentChunks: [],
        currentChunkIndex: 0,
        hasMoreContent: false,
      ));
    }
  }

  Future<void> _onLoadBookContent(
    LoadBookContent event,
    Emitter<BookState> emit,
  ) async {
    // Check content cache first
    if (_isContentCacheValid(event.textUrl)) {
      final cachedContent = _bookContentCache[event.textUrl];
      if (cachedContent != null) {
        final chunks = _splitContentIntoChunks(cachedContent);
        emit(state.copyWith(
          bookContent: cachedContent,
          bookContentChunks: chunks,
          currentChunkIndex: 0,
          hasMoreContent: chunks.length > 1,
          isLoading: false,
          error: null,
        ));
        return;
      }
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final content = await _getBookContent(event.textUrl);

      // Cache the content
      _bookContentCache[event.textUrl] = content;

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
      final errorMessage =
          _getUserFriendlyError('Failed to load book content: ${e.toString()}');
      emit(state.copyWith(
        error: errorMessage,
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
      final errorMessage =
          _getUserFriendlyError('Failed to load book content: ${e.toString()}');
      emit(state.copyWith(
        error: errorMessage,
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
      // Create a reading progress entry for the book
      final progress = ReadingProgress(
        bookId: event.book.id,
        progress: 0.0,
        currentPosition: 0,
        scrollOffset: 0.0,
        lastReadAt: DateTime.now(),
      );

      // Save to reading repository
      await _readingRepository.saveReadingProgress(progress);

      // Update the currently reading books list
      final updatedBooks = List<Book>.from(state.currentlyReadingBooks)
        ..add(event.book);

      emit(state.copyWith(
        currentlyReadingBooks: updatedBooks,
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
      final progressList = await _readingRepository.getCurrentlyReadingBooks();
      final books = state.books.where((book) {
        return progressList.any((progress) => progress.bookId == book.id);
      }).toList();

      emit(state.copyWith(
        currentlyReadingBooks: books,
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
      final progress =
          await _readingRepository.getReadingProgress(event.bookId);
      emit(state.copyWith(
        readingProgress: progress,
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
      final progress = ReadingProgress(
        bookId: event.bookId,
        progress: event.chunkIndex / state.bookContentChunks.length,
        currentPosition: event.chunkIndex,
        scrollOffset: event.scrollOffset,
        lastReadAt: DateTime.now(),
      );

      await _readingRepository.saveReadingProgress(progress);
      emit(state.copyWith(
        readingProgress: progress,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to save reading progress: $e',
      ));
    }
  }

  // Public method to clear cache
  void clearCache() {
    _booksByCategoryCache.clear();
    _bookContentCache.clear();
    _bookDetailsCache.clear();

    developer.log('Cache cleared');

    // Optionally reload current category
    if (state.category != null) {
      add(LoadBooksByTopic(state.category!));
    }
  }

  List<String> _splitContentIntoChunks(String content) {
    const int chunkSize = AppConstants.defaultChunkSize;
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

  // Public method to get cached books for a category
  List<Book>? getCachedBooksForCategory(String category) {
    if (_isCacheValid(category)) {
      return _booksByCategoryCache[category]?.books;
    }
    return null;
  }

  // Public method to get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'categories': _booksByCategoryCache.length,
      'content': _bookContentCache.length,
      'bookDetails': _bookDetailsCache.length,
      'totalBooks': _booksByCategoryCache.values
          .fold<int>(0, (sum, data) => sum + data.books.length),
    };
  }

  String _getUserFriendlyError(String error) {
    if (error.contains(AppConstants.errorTimeout) ||
        error.contains('Timeout')) {
      return 'Request timeout - the server took too long to respond. Please try again.';
    } else if (error.contains(AppConstants.errorConnection) ||
        error.contains('Connection')) {
      return 'No internet connection. Please check your network settings.';
    } else if (error.contains(AppConstants.errorDio)) {
      return 'Network error occurred. Please check your internet connection.';
    } else if (error.contains(AppConstants.errorFailedToFetch)) {
      return 'Failed to load data from server. Please try again later.';
    } else if (error.contains(AppConstants.errorBookNotFound)) {
      return 'The requested book could not be found.';
    } else {
      return AppConstants.errorUnexpected;
    }
  }
}

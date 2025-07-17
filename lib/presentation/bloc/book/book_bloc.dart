import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_books_by_topic.dart';
import '../../../domain/usecases/search_books.dart';
import '../../../domain/usecases/get_book_content.dart';
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
  final GetBooksByTopicWithPagination getBooksByTopicWithPagination;
  final SearchBooks searchBooks;
  final GetBookContent getBookContent;
  final BookRepository bookRepository;

  // In-memory cache for books by category
  final Map<String, List<Book>> _booksByCategoryCache = {};
  // Cache for all books fetched from API (for pagination)
  final Map<String, List<Book>> _allBooksByCategoryCache = {};

  BookBloc({
    required this.getBooksByTopic,
    required this.getBooksByTopicWithPagination,
    required this.searchBooks,
    required this.getBookContent,
    required this.bookRepository,
  }) : super(const BookState()) {
    on<LoadBooksByTopic>(_onLoadBooksByTopic);
    on<PreloadBooksByTopic>(_onPreloadBooksByTopic);
    on<LoadMoreBooks>(_onLoadMoreBooks);
    on<SearchBooksEvent>(_onSearchBooks);
    on<LoadBookById>(_onLoadBookById);
    on<LoadBooksByPage>(_onLoadBooksByPage);
    on<LoadBookContent>(_onLoadBookContent);
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

    // Check if we have all books cached for this category
    if (_allBooksByCategoryCache.containsKey(event.topic)) {
      final allBooks = _allBooksByCategoryCache[event.topic]!;
      final initialBooks = allBooks.take(10).toList();
      _booksByCategoryCache[event.topic] = initialBooks;

      emit(state.copyWith(
        books: initialBooks,
        isLoading: false,
        error: null,
        category: event.topic,
      ));
      return;
    }

    // Try to load from local storage first
    final localDataSource = bookRepository is BookRepositoryImpl
        ? (bookRepository as BookRepositoryImpl).localDataSource
        : null;

    if (localDataSource != null) {
      try {
        final cachedBooks =
            await localDataSource.getCachedBooksByCategory(event.topic);
        if (cachedBooks.isNotEmpty) {
          _booksByCategoryCache[event.topic] = cachedBooks;
          _allBooksByCategoryCache[event.topic] = cachedBooks;
          emit(state.copyWith(
            books: cachedBooks,
            isLoading: false,
            error: null,
            category: event.topic,
          ));
          return;
        }
      } catch (e) {
        print('[BLoC] Error loading from local storage: $e');
      }
    }

    try {
      print('[BLoC] Fetching books for topic: ${event.topic}');
      final allBooks = await getBooksByTopic(event.topic);
      print(
          '[BLoC] Successfully fetched ${allBooks.length} books for topic: ${event.topic}');

      // Cache all books for pagination
      _allBooksByCategoryCache[event.topic] = allBooks;

      // Show only first 10 books initially
      final initialBooks = allBooks.take(10).toList();
      _booksByCategoryCache[event.topic] = initialBooks;

      // Save to local storage (only first 10 for storage efficiency)
      if (localDataSource != null) {
        try {
          final bookModels = initialBooks
              .map((book) => BookModel.fromJson((book as BookModel).toJson()))
              .toList();
          await localDataSource.cacheBooksByCategory(event.topic, bookModels);
        } catch (e) {
          print('[BLoC] Error saving to local storage: $e');
        }
      }

      emit(state.copyWith(
        books: initialBooks,
        isLoading: false,
        error: null,
        category: event.topic,
      ));
    } catch (e) {
      print('[BLoC] Error fetching books for topic ${event.topic}: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to load books: $e'));
    }
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BookState> emit,
  ) async {
    try {
      // Check if we have all books cached
      if (!_allBooksByCategoryCache.containsKey(event.category)) {
        emit(
            state.copyWith(isLoading: false, error: 'No more books available'));
        return;
      }

      final allBooks = _allBooksByCategoryCache[event.category]!;
      final currentCount = event.currentCount;

      // Check if we have more books to show
      if (currentCount >= allBooks.length) {
        emit(
            state.copyWith(isLoading: false, error: 'No more books available'));
        return;
      }

      // Get next 10 books
      final nextBooks = allBooks.skip(currentCount).take(10).toList();
      final updatedBooks = List<Book>.from(state.books)..addAll(nextBooks);

      emit(state.copyWith(
        books: updatedBooks,
        isLoading: false,
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
      final book = await bookRepository.getBookById(event.workKey);
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
    try {
      final progress = await bookRepository.getReadingProgress(event.workKey);
      emit(state.copyWith(readingProgress: progress));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSaveReadingProgress(
    SaveReadingProgress event,
    Emitter<BookState> emit,
  ) async {
    try {
      final progress = ReadingProgress(
        bookId: event.workKey,
        currentPosition: event.chunkIndex,
        scrollOffset: event.scrollOffset,
        progress: 0.0,
        lastReadAt: DateTime.now(),
        bookmarks: [],
      );
      await bookRepository.saveReadingProgress(progress);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // Public method to get cached books for a category
  List<Book>? getCachedBooksForCategory(String category) {
    return _booksByCategoryCache[category];
  }

  // Optimized method to preload all categories and set state for default
  Future<void> preloadAllCategoriesAndSetDefault() async {
    final categories = AppConstants.bookCategories;
    final localDataSource = bookRepository is BookRepositoryImpl
        ? (bookRepository as BookRepositoryImpl).localDataSource
        : null;

    final futures = <Future<void>>[];
    for (final category in categories) {
      if (!_booksByCategoryCache.containsKey(category)) {
        futures.add(() async {
          // First try local storage
          if (localDataSource != null) {
            final cachedBooks =
                await localDataSource.getCachedBooksByCategory(category);
            if (cachedBooks.isNotEmpty) {
              _booksByCategoryCache[category] = cachedBooks;
              return;
            }
          }

          // If not in local storage, fetch from API
          try {
            final books = await getBooksByTopic(category);
            _booksByCategoryCache[category] = books;
            // Save to local storage
            if (localDataSource != null) {
              final bookModels = books
                  .map((book) =>
                      BookModel.fromJson((book as BookModel).toJson()))
                  .toList();
              await localDataSource.cacheBooksByCategory(category, bookModels);
            }
          } catch (_) {}
        }());
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

  // Load only the default category and set state
  Future<void> loadDefaultCategoryAndSetState() async {
    final defaultCategory = AppConstants.bookCategories.first;

    // First try to load from local storage
    final localDataSource = bookRepository is BookRepositoryImpl
        ? (bookRepository as BookRepositoryImpl).localDataSource
        : null;

    if (localDataSource != null) {
      final cachedBooks =
          await localDataSource.getCachedBooksByCategory(defaultCategory);
      if (cachedBooks.isNotEmpty) {
        _booksByCategoryCache[defaultCategory] = cachedBooks;
        emit(state.copyWith(
          books: cachedBooks,
          isLoading: false,
          category: defaultCategory,
        ));
        return;
      }
    }

    // If not in local storage, fetch from API
    try {
      final books = await getBooksByTopic(defaultCategory);
      _booksByCategoryCache[defaultCategory] = books;

      // Save to local storage for future use
      if (localDataSource != null) {
        final bookModels = books
            .map((book) => BookModel.fromJson((book as BookModel).toJson()))
            .toList();
        await localDataSource.cacheBooksByCategory(defaultCategory, bookModels);
      }

      emit(state.copyWith(
        books: books,
        isLoading: false,
        category: defaultCategory,
      ));
    } catch (_) {}
  }

  // Preload the rest of the categories in the background
  Future<void> preloadOtherCategoriesInBackground() async {
    final categories = AppConstants.bookCategories;
    final defaultCategory = categories.first;
    final localDataSource = bookRepository is BookRepositoryImpl
        ? (bookRepository as BookRepositoryImpl).localDataSource
        : null;

    for (final category in categories) {
      if (category == defaultCategory) continue;
      if (!_booksByCategoryCache.containsKey(category)) {
        // First try local storage
        if (localDataSource != null) {
          final cachedBooks =
              await localDataSource.getCachedBooksByCategory(category);
          if (cachedBooks.isNotEmpty) {
            _booksByCategoryCache[category] = cachedBooks;
            continue;
          }
        }

        // If not in local storage, fetch from API
        getBooksByTopic(category).then((books) {
          _booksByCategoryCache[category] = books;
          // Save to local storage
          if (localDataSource != null) {
            final bookModels = books
                .map((book) => BookModel.fromJson((book as BookModel).toJson()))
                .toList();
            localDataSource.cacheBooksByCategory(category, bookModels);
          }
        }).catchError((_) {});
      }
    }
  }
}

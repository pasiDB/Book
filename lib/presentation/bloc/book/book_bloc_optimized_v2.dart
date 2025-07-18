import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

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

class BookBlocOptimizedV2 extends Bloc<BookEvent, BookState> {
  final GetBooksByTopic _getBooksByTopic;
  final GetBooksByTopicWithPagination _getBooksByTopicWithPagination;
  final SearchBooks _searchBooks;
  final GetBookContent _getBookContent;
  final GetBookContentByGutenbergId _getBookContentByGutenbergId;
  final BookRepository _bookRepository;
  final ReadingRepository _readingRepository;

  // Cache for books by category
  final Map<String, List<Book>> _booksByCategoryCache = {};

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
    await super.close();
  }

  // Public methods for external access
  Future<void> loadDefaultCategoryAndSetState() async {
    if (AppConstants.bookCategories.isEmpty) return;

    final defaultCategory = AppConstants.bookCategories.first;
    add(LoadBooksByTopic(defaultCategory));
  }

  Future<void> preloadOtherCategoriesInBackground() async {
    if (AppConstants.bookCategories.length <= 1) return;

    final categoriesToPreload = AppConstants.bookCategories.skip(1);
    for (final category in categoriesToPreload) {
      add(PreloadBooksByTopic(category));
    }
  }

  Future<void> _onLoadBooksByTopic(
    LoadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, category: event.topic));

    try {
      final books = await _getBooksByTopic(event.topic);
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

  Future<void> _onPreloadBooksByTopic(
    PreloadBooksByTopic event,
    Emitter<BookState> emit,
  ) async {
    if (_booksByCategoryCache.containsKey(event.topic)) return;
    try {
      final books = await _getBooksByTopic(event.topic);
      _booksByCategoryCache[event.topic] = books;
    } catch (_) {}
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
      final books = await _searchBooks(event.query);
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
      final book = await _bookRepository.getBookById(event.bookId);
      if (book != null) {
        emit(state.copyWith(selectedBook: book, isLoading: false, error: null));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Book not found'));
      }
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

  // Public method to get cached books for a category
  List<Book>? getCachedBooksForCategory(String category) {
    return _booksByCategoryCache[category];
  }
}

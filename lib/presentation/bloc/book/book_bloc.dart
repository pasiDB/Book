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
    on<LoadBookContentChunk>(_onLoadBookContentChunk);
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
}

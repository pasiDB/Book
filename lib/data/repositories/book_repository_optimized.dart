import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source_optimized_v2.dart';
import '../datasources/book_local_data_source.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_repository.dart';

class BookRepositoryOptimized implements BookRepository, ReadingRepository {
  final BookRemoteDataSourceOptimized remoteDataSource;
  final BookLocalDataSource localDataSource;

  BookRepositoryOptimized({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Book>> getBooksByTopic(String topic) async {
    try {
      // Use pagination to load only 10 books initially
      final books = await remoteDataSource.getBooksByTopicWithPagination(topic,
          limit: 10, offset: 0);
      await localDataSource.cacheBooksByCategory(topic, books);
      return books;
    } catch (e) {
      // Fallback to cached data if available
      final cachedBooks = await localDataSource.getCachedBooksByCategory(topic);
      if (cachedBooks.isNotEmpty) {
        return cachedBooks;
      }
      rethrow;
    }
  }

  @override
  Future<List<Book>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0}) async {
    try {
      final books = await remoteDataSource.getBooksByTopicWithPagination(topic,
          limit: limit, offset: offset);
      return books;
    } catch (e) {
      throw Exception('Failed to get books by topic with pagination: $e');
    }
  }

  // Add a method to get cached books by topic
  Future<List<Book>> getCachedBooksByTopic(String topic) async {
    return await localDataSource.getCachedBooks('cached_books_$topic');
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    try {
      final books = await remoteDataSource.searchBooks(query);
      return books;
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  @override
  Future<Book?> getBookById(String workKey) async {
    try {
      final book = await remoteDataSource.getBookByWorkKey(workKey);
      return book;
    } catch (e) {
      throw Exception('Failed to get book by work key: $e');
    }
  }

  @override
  Future<List<Book>> getBooksByPage(int page) async {
    try {
      final books = await remoteDataSource.getBooksByPage(page);
      return books;
    } catch (e) {
      throw Exception('Failed to get books by page: $e');
    }
  }

  @override
  Future<String> getBookContent(String textUrl) async {
    try {
      final content = await remoteDataSource.getBookContent(textUrl);
      return content;
    } catch (e) {
      throw Exception('Failed to get book content: $e');
    }
  }

  // Optimized batch operations
  Future<List<Book>> getBooksBatch(List<int> ids) async {
    try {
      return await remoteDataSource.getBooksBatch(ids);
    } catch (e) {
      throw Exception('Failed to get books batch: $e');
    }
  }

  Future<Map<int, String>> getBookContentsBatch(List<String> textUrls) async {
    try {
      return await remoteDataSource.getBookContentsBatch(textUrls);
    } catch (e) {
      throw Exception('Failed to get book contents batch: $e');
    }
  }

  @override
  Future<List<Book>> getEditionsByWorkKey(String workKey) async {
    final editionModels = await remoteDataSource.getEditionsByWorkKey(workKey);
    // Convert BookModel to Book if needed
    return editionModels.map((e) => e as Book).toList();
  }

  // ReadingRepository implementation
  @override
  Future<ReadingProgress?> getReadingProgress(String workKey) async {
    return await localDataSource.getReadingProgress(workKey);
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    await localDataSource.saveReadingProgress(progress);
  }

  @override
  Future<void> updateCurrentPosition(String workKey, int position,
      double progress, double scrollOffset) async {
    final existing = await getReadingProgress(workKey);
    final updated = ReadingProgress(
      bookId: workKey,
      progress: progress,
      currentPosition: position,
      scrollOffset: scrollOffset,
      lastReadAt: DateTime.now(),
      bookmarks: existing?.bookmarks ?? [],
    );
    await saveReadingProgress(updated);
  }

  @override
  Future<void> addBookmark(String workKey, int position) async {
    final existing = await getReadingProgress(workKey);
    final updated = (existing ??
            ReadingProgress(
              bookId: workKey,
              progress: 0.0,
              currentPosition: 0,
              scrollOffset: 0.0,
              lastReadAt: DateTime.now(),
              bookmarks: [],
            ))
        .copyWith(bookmarks: [...(existing?.bookmarks ?? []), position]);
    await saveReadingProgress(updated);
  }

  @override
  Future<void> removeBookmark(String workKey, int position) async {
    final existing = await getReadingProgress(workKey);
    if (existing == null) return;
    final updated = existing.copyWith(
        bookmarks: existing.bookmarks.where((b) => b != position).toList());
    await saveReadingProgress(updated);
  }

  @override
  Future<List<ReadingProgress>> getCurrentlyReadingBooks() async {
    // Not implemented for now
    return [];
  }
}

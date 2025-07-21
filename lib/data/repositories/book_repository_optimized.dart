import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source_optimized_v2.dart';
import '../datasources/book_local_data_source.dart';
import '../datasources/book_local_data_source_hive.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../core/constants/app_constants.dart';

class BookRepositoryOptimized implements BookRepository, ReadingRepository {
  final BookRemoteDataSourceOptimized remoteDataSource;
  final BookLocalDataSource localDataSource;

  BookRepositoryOptimized({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // Helper getter for Hive data source if available
  BookLocalDataSourceHive? get _hiveDataSource =>
      localDataSource is BookLocalDataSourceHive
          ? localDataSource as BookLocalDataSourceHive
          : null;

  @override
  Future<List<Book>> getBooksByTopic(String topic) async {
    print('📚 Getting books for topic: $topic');

    try {
      // Check if we have cached data for this topic
      final cachedBooks = await localDataSource.getCachedBooksByCategory(topic);
      if (cachedBooks.isNotEmpty) {
        print('📦 Found ${cachedBooks.length} cached books for topic: $topic');
        return cachedBooks;
      } else {
        print('📭 No cached books found for topic: $topic');
      }

      // Check if this is the first launch (if using Hive)
      final hiveDataSource = _hiveDataSource;
      if (hiveDataSource != null) {
        final isFirstLaunch = await hiveDataSource.isFirstLaunch();
        print('🔍 First launch detection result: $isFirstLaunch');

        if (isFirstLaunch) {
          // First launch: Load all categories from API
          print('🚀 First launch detected - loading all categories from API');
          await _loadAllCategoriesFromAPI();
          await hiveDataSource.markFirstLaunchCompleted();

          // Return books for the requested topic
          final updatedCachedBooks =
              await localDataSource.getCachedBooksByCategory(topic);
          print(
              '📦 After first launch loading, found ${updatedCachedBooks.length} books for topic: $topic');
          return updatedCachedBooks;
        } else {
          print(
              '🔄 Subsequent launch - but no cached data, falling back to API for topic: $topic');
        }
      } else {
        print('⚠️ Not using Hive data source, using regular API call');
      }

      // Regular API call
      print('📥 Loading books from API for topic: $topic');
      final books = await remoteDataSource.getBooksByTopicWithPagination(topic,
          limit: 50, offset: 0);
      print('📥 Received ${books.length} books from API for topic: $topic');
      await localDataSource.cacheBooksByCategory(topic, books);
      print('💾 Cached ${books.length} books for topic: $topic');
      return books;
    } catch (e) {
      print('❌ Error in getBooksByTopic for $topic: $e');

      // Fallback to cached data if available
      final cachedBooks = await localDataSource.getCachedBooksByCategory(topic);
      if (cachedBooks.isNotEmpty) {
        print('📦 Returning cached books as fallback');
        return cachedBooks;
      }

      rethrow;
    }
  }

  /// Load all book categories from API on first launch
  Future<void> _loadAllCategoriesFromAPI() async {
    print('🔄 Loading all categories from API...');

    final futures = AppConstants.bookCategories.map((category) async {
      try {
        print('📥 Fetching books for category: $category');
        final books = await remoteDataSource.getBooksByTopicWithPagination(
            category,
            limit:
                50, // Load more books per category for better offline experience
            offset: 0);
        await localDataSource.cacheBooksByCategory(category, books);
        print('✅ Cached ${books.length} books for category: $category');
      } catch (e) {
        print('❌ Error loading category $category: $e');
        // Continue with other categories even if one fails
      }
    });

    await Future.wait(futures);
    print('✅ Completed loading all categories');
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
  Future<Book?> getBookById(int id) async {
    try {
      final book = await remoteDataSource.getBookById(id);
      return book;
    } catch (e) {
      throw Exception('Failed to get book by id: $e');
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

  @override
  Future<String> getBookContentByGutenbergId(int gutenbergId) async {
    try {
      final content =
          await remoteDataSource.getBookContentByGutenbergId(gutenbergId);
      return content;
    } catch (e) {
      throw Exception('Failed to get book content by Gutenberg ID: $e');
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

  // ReadingRepository implementation
  @override
  Future<ReadingProgress?> getReadingProgress(int bookId) async {
    return await localDataSource.getReadingProgress(bookId);
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    await localDataSource.saveReadingProgress(progress);
  }

  @override
  Future<void> updateCurrentPosition(
      int bookId, int position, double progress, double scrollOffset) async {
    final existing = await getReadingProgress(bookId);
    final updated = ReadingProgress(
      bookId: bookId,
      progress: progress,
      currentPosition: position,
      scrollOffset: scrollOffset,
      lastReadAt: DateTime.now(),
      bookmarks: existing?.bookmarks ?? [],
    );
    await saveReadingProgress(updated);
  }

  @override
  Future<void> addBookmark(int bookId, int position) async {
    final existing = await getReadingProgress(bookId);
    final updated = (existing ??
            ReadingProgress(
              bookId: bookId,
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
  Future<void> removeBookmark(int bookId, int position) async {
    final existing = await getReadingProgress(bookId);
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

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/book.dart';
import '../../core/services/hive_storage_service.dart';
import 'book_local_data_source.dart';

class BookLocalDataSourceHive implements BookLocalDataSource {
  final SharedPreferences sharedPreferences;
  final HiveStorageService _hiveService;

  BookLocalDataSourceHive(this.sharedPreferences)
      : _hiveService = HiveStorageService.instance;

  @override
  Future<void> cacheBooks(String key, List<BookModel> books) async {
    // Convert BookModel to Book entities for Hive storage
    final bookEntities = books.map((bookModel) => bookModel.toBook()).toList();

    // Extract category from key if it follows the pattern 'cached_books_category'
    String category = key;
    if (key.startsWith('cached_books_')) {
      category = key.substring('cached_books_'.length);
    }

    await _hiveService.cacheBooksForCategory(category, bookEntities);
  }

  Book toBook() {
    throw UnimplementedError(
        'toBook() method should be called on BookModel instances');
  }

    @override
  Future<List<BookModel>> getCachedBooks(String key) async {
    // Extract category from key if it follows the pattern 'cached_books_category'
    String category = key;
    if (key.startsWith('cached_books_')) {
      category = key.substring('cached_books_'.length);
    }
    
    final books = await _hiveService.getCachedBooksForCategory(category);
    if (books == null || books.isEmpty) {
      return [];
    }
    
    // Convert Book entities back to BookModel
    return books.map((book) => BookToModelConversion.fromBook(book)).toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveService.clearAllCache();
  }

  @override
  Future<void> cacheBooksByCategory(
      String category, List<BookModel> books) async {
    // Convert BookModel to Book entities for Hive storage
    final bookEntities = books.map((bookModel) => bookModel.toBook()).toList();
    await _hiveService.cacheBooksForCategory(category, bookEntities);
  }

  @override
  Future<List<BookModel>> getCachedBooksByCategory(String category) async {
    final books = await _hiveService.getCachedBooksForCategory(category);
    if (books == null || books.isEmpty) {
      return [];
    }

    // Convert Book entities back to BookModel
    return books.map((book) => BookToModelConversion.fromBook(book)).toList();
  }

  @override
  Future<bool> hasCachedBooksForCategory(String category) async {
    return await _hiveService.hasCachedBooksForCategory(category);
  }

  @override
  Future<void> clearAllBookCache() async {
    await _hiveService.clearAllCache();
  }

  // First launch detection methods
  Future<bool> isFirstLaunch() async {
    return await _hiveService.isFirstLaunch();
  }

  Future<void> markFirstLaunchCompleted() async {
    await _hiveService.markFirstLaunchCompleted();
  }

  Future<void> resetFirstLaunchFlag() async {
    await _hiveService.resetFirstLaunchFlag();
  }

  // Check if all required categories have been cached
  Future<bool> areAllCategoriesCached() async {
    final cachedCategories = await _hiveService.getCachedCategories();
    final requiredCategories = AppConstants.bookCategories.toSet();
    final cachedCategoriesSet = cachedCategories.toSet();

    return requiredCategories
        .every((category) => cachedCategoriesSet.contains(category));
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    return await _hiveService.getCacheStats();
  }

  // Optimize cache storage
  Future<void> optimizeCache() async {
    await _hiveService.optimizeCache();
  }

  // Clear expired cache entries
  Future<void> clearExpiredCache() async {
    await _hiveService.clearExpiredCache();
  }

  @override
  Future<void> saveCurrentlyReadingBooks(List<BookModel> books) async {
    final booksJson = books.map((book) => book.toJson()).toList();
    await sharedPreferences.setString(
        AppConstants.currentlyReadingKey, jsonEncode(booksJson));
  }

  @override
  Future<List<BookModel>> getCurrentlyReadingBooks() async {
    final booksString =
        sharedPreferences.getString(AppConstants.currentlyReadingKey);
    if (booksString != null) {
      final booksJson = jsonDecode(booksString) as List<dynamic>;
      return booksJson
          .map((bookJson) =>
              BookModel.fromJson(bookJson as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    final key = 'reading_progress_${progress.bookId}';
    final data = {
      'bookId': progress.bookId,
      'progress': progress.progress,
      'currentPosition': progress.currentPosition,
      'scrollOffset': progress.scrollOffset,
      'lastReadAt': progress.lastReadAt.toIso8601String(),
      'bookmarks': progress.bookmarks,
    };
    await sharedPreferences.setString(key, jsonEncode(data));
  }

  @override
  Future<ReadingProgress?> getReadingProgress(int bookId) async {
    try {
      final key = 'reading_progress_$bookId';
      final progressJson = sharedPreferences.getString(key);
      if (progressJson != null) {
        final progressMap = jsonDecode(progressJson) as Map<String, dynamic>;
        return ReadingProgress(
          bookId: progressMap['bookId'] as int,
          progress: progressMap['progress'] as double,
          currentPosition: progressMap['currentPosition'] as int,
          scrollOffset: progressMap['scrollOffset'] as double,
          lastReadAt: DateTime.parse(progressMap['lastReadAt'] as String),
          bookmarks: List<int>.from(progressMap['bookmarks'] ?? []),
        );
      }
      return null;
    } catch (e) {
      print('Error getting reading progress: $e');
      return null;
    }
  }
}

// Extension to add Book conversion to BookModel
extension BookModelConversion on BookModel {
  Book toBook() {
    return Book(
      id: id,
      title: title,
      author: author,
      authors: [], // BookModel doesn't have authors list, so use empty list
      coverUrl: coverUrl,
      coverImageUrl: coverUrl, // Use coverUrl for both fields
      description: description,
      languages: languages,
      subjects: subjects,
      bookshelves: [], // BookModel doesn't have bookshelves, so use empty list
      readingProgress: readingProgress,
      isDownloaded: isDownloaded,
      downloadPath: downloadPath,
      lastReadAt: lastReadAt,
      formats: formats,
    );
  }
}

extension BookToModelConversion on Book {
  static BookModel fromBook(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      description: book.description,
      languages: book.languages,
      subjects: book.subjects,
      readingProgress: book.readingProgress,
      isDownloaded: book.isDownloaded,
      downloadPath: book.downloadPath,
      lastReadAt: book.lastReadAt,
      formats: book.formats,
    );
  }
}

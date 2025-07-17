import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/reading_progress.dart';

abstract class BookLocalDataSource {
  Future<void> cacheBooks(String key, List<BookModel> books);
  Future<List<BookModel>> getCachedBooks(String key);
  Future<void> clearCache();
  Future<void> saveCurrentlyReadingBooks(List<BookModel> books);
  Future<List<BookModel>> getCurrentlyReadingBooks();
  Future<void> saveReadingProgress(ReadingProgress progress);
  Future<ReadingProgress?> getReadingProgress(String workKey);
  // New methods for persistent book caching
  Future<void> cacheBooksByCategory(String category, List<BookModel> books);
  Future<List<BookModel>> getCachedBooksByCategory(String category);
  Future<bool> hasCachedBooksForCategory(String category);
  Future<void> clearAllBookCache();
}

class BookLocalDataSourceImpl implements BookLocalDataSource {
  final SharedPreferences sharedPreferences;

  BookLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheBooks(String key, List<BookModel> books) async {
    final booksJson = books.map((book) => book.toJson()).toList();
    await sharedPreferences.setString(key, jsonEncode(booksJson));
  }

  @override
  Future<List<BookModel>> getCachedBooks(String key) async {
    final booksString = sharedPreferences.getString(key);
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
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith('cached_books_')) {
        await sharedPreferences.remove(key);
      }
    }
  }

  @override
  Future<void> cacheBooksByCategory(
      String category, List<BookModel> books) async {
    final key = 'category_books_$category';
    final booksJson = books.map((book) => book.toJson()).toList();
    await sharedPreferences.setString(key, jsonEncode(booksJson));
    // Also store timestamp for cache invalidation
    await sharedPreferences.setInt(
        '${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<List<BookModel>> getCachedBooksByCategory(String category) async {
    final key = 'category_books_$category';
    final booksString = sharedPreferences.getString(key);
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
  Future<bool> hasCachedBooksForCategory(String category) async {
    final key = 'category_books_$category';
    return sharedPreferences.containsKey(key);
  }

  @override
  Future<void> clearAllBookCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith('category_books_') ||
          key.startsWith('cached_books_')) {
        await sharedPreferences.remove(key);
      }
    }
  }

  Future<void> saveCurrentlyReadingBooks(List<BookModel> books) async {
    final booksJson = books.map((book) => book.toJson()).toList();
    await sharedPreferences.setString(
        AppConstants.currentlyReadingKey, jsonEncode(booksJson));
  }

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
  Future<ReadingProgress?> getReadingProgress(String workKey) async {
    final key = 'reading_progress_$workKey';
    final jsonString = sharedPreferences.getString(key);
    if (jsonString == null) return null;
    final data = jsonDecode(jsonString);
    return ReadingProgress(
      bookId: data['bookId'] as String,
      progress: (data['progress'] as num).toDouble(),
      currentPosition: data['currentPosition'] as int,
      scrollOffset: (data['scrollOffset'] as num).toDouble(),
      lastReadAt: DateTime.parse(data['lastReadAt'] as String),
      bookmarks:
          (data['bookmarks'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }
}

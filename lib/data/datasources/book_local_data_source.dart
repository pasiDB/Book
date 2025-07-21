import '../models/book_model.dart';
import '../../domain/entities/reading_progress.dart';

abstract class BookLocalDataSource {
  Future<void> cacheBooks(String key, List<BookModel> books);
  Future<List<BookModel>> getCachedBooks(String key);
  Future<void> clearCache();
  Future<void> saveReadingProgress(ReadingProgress progress);
  Future<ReadingProgress?> getReadingProgress(int bookId);
  // New methods for persistent book caching
  Future<void> cacheBooksByCategory(String category, List<BookModel> books);
  Future<List<BookModel>> getCachedBooksByCategory(String category);
  Future<bool> hasCachedBooksForCategory(String category);
  Future<void> clearAllBookCache();
}

import '../entities/book.dart';
import '../entities/reading_progress.dart';

abstract class BookRepository {
  Future<List<Book>> getBooksByTopic(String topic);
  Future<List<Book>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0});
  Future<List<Book>> searchBooks(String query);
  Future<Book?> getBookById(String workKey);
  Future<ReadingProgress?> getReadingProgress(String workKey);
  Future<void> saveReadingProgress(ReadingProgress progress);
  Future<List<Book>> getBooksByPage(int page);
  Future<String> getBookContent(String textUrl);
  // Add method for cached books
  Future<List<Book>> getCachedBooksByTopic(String topic);
}

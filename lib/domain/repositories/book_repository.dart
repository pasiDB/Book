import '../entities/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooksByTopic(String topic);
  Future<List<Book>> searchBooks(String query);
  Future<Book?> getBookById(int id);
  Future<List<Book>> getBooksByPage(int page);
  Future<String> getBookContent(String textUrl);
  Future<String> getBookContentByGutenbergId(int gutenbergId);
  // Add method for cached books
  Future<List<Book>> getCachedBooksByTopic(String topic);
}

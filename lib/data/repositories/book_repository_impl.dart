import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source.dart';
import '../datasources/book_local_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  final BookRemoteDataSource remoteDataSource;
  final BookLocalDataSource localDataSource;

  BookRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Book>> getBooksByTopic(String topic) async {
    try {
      final books = await remoteDataSource.getBooksByTopic(topic);
      await localDataSource.cacheBooks('cached_books_$topic', books);
      return books;
    } catch (e) {
      // Fallback to cached data if available
      final cachedBooks =
          await localDataSource.getCachedBooks('cached_books_$topic');
      if (cachedBooks.isNotEmpty) {
        return cachedBooks;
      }
      rethrow;
    }
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
      final content = await remoteDataSource.getBookContentByGutenbergId(gutenbergId);
      return content;
    } catch (e) {
      throw Exception('Failed to get book content by Gutenberg ID: $e');
    }
  }
}

import '../../core/services/api_service.dart';
import '../../core/services/cache_service.dart';
import '../models/api_response_model.dart';
import '../models/book_model.dart';

abstract class BookRemoteDataSource {
  Future<List<BookModel>> getBooksByTopic(String topic);
  Future<List<BookModel>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0});
  Future<List<BookModel>> searchBooks(String query);
  Future<BookModel?> getBookById(int id);
  Future<List<BookModel>> getBooksByPage(int page);
  Future<String> getBookContent(String textUrl);
}

class BookRemoteDataSourceImpl implements BookRemoteDataSource {
  final ApiService _apiService;
  final CacheService _cacheService;

  BookRemoteDataSourceImpl(this._apiService, this._cacheService);

  @override
  Future<List<BookModel>> getBooksByTopic(String topic) async {
    try {
      // Check cache first
      final cachedBooks = await _cacheService.getBooksByCategory(topic);
      if (cachedBooks != null) {
        return cachedBooks.map((json) => BookModel.fromJson(json)).toList();
      }

      // Fetch from API with retry
      final response = await _apiService.getWithRetry<Map<String, dynamic>>(
        '/books/',
        queryParameters: {'topic': topic},
        useCache: true,
      );

      final apiResponse = ApiResponseModel.fromJson(response);
      final books = apiResponse.results;

      // Cache the results
      final booksJson = books.map((book) => book.toJson()).toList();
      await _cacheService.setBooksByCategory(topic, booksJson);

      return books;
    } catch (e) {
      print('Error fetching books by topic: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0}) async {
    try {
      // For now, we'll fetch all books and handle pagination client-side
      // since the API doesn't support proper pagination
      final allBooks = await getBooksByTopic(topic);

      // Apply client-side pagination
      final startIndex = offset;
      final endIndex = (offset + limit).clamp(0, allBooks.length);

      return allBooks.sublist(startIndex, endIndex);
    } catch (e) {
      print('Error fetching books with pagination: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await _apiService.getWithRetry<Map<String, dynamic>>(
        '/books/',
        queryParameters: {'search': query},
        useCache: true,
      );

      final apiResponse = ApiResponseModel.fromJson(response);
      return apiResponse.results;
    } catch (e) {
      print('Error searching books: $e');
      rethrow;
    }
  }

  @override
  Future<BookModel?> getBookById(int id) async {
    try {
      // Check cache first
      final cachedBook = await _cacheService.getBookDetails(id);
      if (cachedBook != null) {
        return BookModel.fromJson(cachedBook);
      }

      final response = await _apiService.getWithRetry<Map<String, dynamic>>(
        '/books/$id/',
        useCache: true,
      );

      final book = BookModel.fromJson(response);

      // Cache the book details
      await _cacheService.setBookDetails(id, book.toJson());

      return book;
    } catch (e) {
      print('Error fetching book by ID: $e');
      return null;
    }
  }

  @override
  Future<String> getBookContent(String textUrl) async {
    try {
      // Extract book ID from URL for caching
      final bookId = _extractBookIdFromUrl(textUrl);
      if (bookId != null) {
        // Check cache first
        final cachedContent = await _cacheService.getBookContent(bookId);
        if (cachedContent != null) {
          return cachedContent;
        }
      }

      final content = await _apiService.getWithRetry<String>(
        textUrl,
        useCache: false, // Don't cache raw text content in API service
      );

      // Cache the content
      if (bookId != null) {
        await _cacheService.setBookContent(bookId, content);
      }

      return content;
    } catch (e) {
      print('Error fetching book content: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> getBooksByPage(int page) async {
    try {
      final response = await _apiService.getWithRetry<Map<String, dynamic>>(
        '/books/',
        queryParameters: {'page': page},
        useCache: true,
      );

      final apiResponse = ApiResponseModel.fromJson(response);
      return apiResponse.results;
    } catch (e) {
      print('Error fetching books by page: $e');
      rethrow;
    }
  }

  int? _extractBookIdFromUrl(String url) {
    try {
      // Try to extract book ID from various URL patterns
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Look for numeric segments that might be book IDs
      for (final segment in pathSegments) {
        final id = int.tryParse(segment);
        if (id != null) {
          return id;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

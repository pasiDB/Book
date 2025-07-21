import '../../core/services/api_service_optimized.dart';
import '../../core/services/cache_service_optimized.dart';
import '../models/api_response_model.dart';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';
import 'dart:developer' as developer;

abstract class BookRemoteDataSourceOptimized {
  Future<List<BookModel>> getBooksByTopic(String topic);
  Future<List<BookModel>> getBooksByTopicWithPagination(String topic,
      {int limit = 10, int offset = 0});
  Future<List<BookModel>> searchBooks(String query);
  Future<BookModel?> getBookById(int id);
  Future<List<BookModel>> getBooksByPage(int page);
  Future<String> getBookContent(String textUrl);
  Future<String> getBookContentByGutenbergId(int gutenbergId);
  Future<List<BookModel>> getBooksBatch(List<int> ids);
  Future<Map<int, String>> getBookContentsBatch(List<String> textUrls);
}

class BookRemoteDataSourceOptimizedImpl
    implements BookRemoteDataSourceOptimized {
  final ApiServiceOptimized _apiService;
  final CacheServiceOptimized _cacheService;

  BookRemoteDataSourceOptimizedImpl(this._apiService, this._cacheService);

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
        AppConstants.booksEndpoint,
        queryParameters: {'topic': topic, 'copyright': false},
        useCache: true,
      );

      final apiResponse = ApiResponseModel.fromJson(response);
      final books = apiResponse.results;

      // Cache the results
      final booksJson = books.map((book) => book.toJson()).toList();
      await _cacheService.setBooksByCategory(topic, booksJson);

      return books;
    } catch (e) {
      developer.log('Error fetching books by topic: $e');
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
      developer.log('Error fetching books with pagination: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await _apiService.getWithRetry<Map<String, dynamic>>(
        AppConstants.booksEndpoint,
        queryParameters: {'search': query, 'copyright': false},
        useCache: true,
      );

      final apiResponse = ApiResponseModel.fromJson(response);
      final lowerQuery = query.toLowerCase();
      final exactTitle = <BookModel>[];
      final partialTitle = <BookModel>[];
      final authorMatch = <BookModel>[];
      final others = <BookModel>[];
      final seen = <int>{};

      for (final book in apiResponse.results) {
        final title = book.title.toLowerCase();
        final author = (book.author ?? '').toLowerCase();
        if (title == lowerQuery) {
          if (seen.add(book.id)) exactTitle.add(book);
        } else if (title.contains(lowerQuery)) {
          if (seen.add(book.id)) partialTitle.add(book);
        } else if (author.contains(lowerQuery)) {
          if (seen.add(book.id)) authorMatch.add(book);
        } else {
          if (seen.add(book.id)) others.add(book);
        }
      }
      return [...exactTitle, ...partialTitle, ...authorMatch, ...others];
    } catch (e) {
      developer.log('Error searching books: $e');
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
        '${AppConstants.booksEndpoint}$id/',
        queryParameters: {'copyright': false},
        useCache: true,
      );

      final book = BookModel.fromJson(response);

      // Cache the book details
      await _cacheService.setBookDetails(id, book.toJson());

      return book;
    } catch (e) {
      developer.log('Error fetching book by ID: $e');
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
      developer.log('Error fetching book content: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> getBooksByPage(int page) async {
    try {
      final response = await _apiService.getWithRetry<Map<String, dynamic>>(
        AppConstants.booksEndpoint,
        queryParameters: {'page': page, 'copyright': false},
        useCache: true,
      );

      final apiResponse = ApiResponseModel.fromJson(response);
      return apiResponse.results;
    } catch (e) {
      developer.log('Error fetching books by page: $e');
      rethrow;
    }
  }

  @override
  Future<String> getBookContentByGutenbergId(int gutenbergId) async {
    try {
      // Check cache first
      final cachedContent = await _cacheService.getBookContent(gutenbergId);
      if (cachedContent != null) {
        return cachedContent;
      }

      // First get the book details to find the text URL
      final book = await getBookById(gutenbergId);
      if (book == null) {
        throw Exception('Book not found');
      }

      final textUrl = book.textDownloadUrl;
      if (textUrl == null) {
        throw Exception('No text format available for this book');
      }

      // Fetch the content
      final content = await getBookContent(textUrl);

      // Cache the content
      await _cacheService.setBookContent(gutenbergId, content);

      return content;
    } catch (e) {
      developer.log('Error fetching book content by Gutenberg ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> getBooksBatch(List<int> ids) async {
    try {
      // Check cache first for all books
      final cachedBooks = <BookModel>[];
      final uncachedIds = <int>[];

      for (final id in ids) {
        final cachedBook = await _cacheService.getBookDetails(id);
        if (cachedBook != null) {
          cachedBooks.add(BookModel.fromJson(cachedBook));
        } else {
          uncachedIds.add(id);
        }
      }

      // If all books are cached, return them
      if (uncachedIds.isEmpty) {
        return cachedBooks;
      }

      // Fetch uncached books in parallel
      final futures = uncachedIds.map((id) => getBookById(id));
      final fetchedBooks = await Future.wait(futures);

      // Combine cached and fetched books
      final allBooks = [
        ...cachedBooks,
        ...fetchedBooks.where((book) => book != null).cast<BookModel>()
      ];
      return allBooks;
    } catch (e) {
      developer.log('Error fetching books batch: $e');
      rethrow;
    }
  }

  @override
  Future<Map<int, String>> getBookContentsBatch(List<String> textUrls) async {
    try {
      final results = <int, String>{};

      // Check cache first for all URLs
      final uncachedUrls = <String>[];
      final urlToId = <String, int>{};

      for (final url in textUrls) {
        final bookId = _extractBookIdFromUrl(url);
        if (bookId != null) {
          urlToId[url] = bookId;
          final cachedContent = await _cacheService.getBookContent(bookId);
          if (cachedContent != null) {
            results[bookId] = cachedContent;
          } else {
            uncachedUrls.add(url);
          }
        }
      }

      // If all contents are cached, return them
      if (uncachedUrls.isEmpty) {
        return results;
      }

      // Fetch uncached contents in parallel
      final futures = uncachedUrls.map((url) => getBookContent(url));
      final fetchedContents = await Future.wait(futures);

      // Add fetched contents to results
      for (int i = 0; i < uncachedUrls.length; i++) {
        final url = uncachedUrls[i];
        final content = fetchedContents[i];
        final bookId = urlToId[url];
        if (bookId != null) {
          results[bookId] = content;
        }
      }

      return results;
    } catch (e) {
      developer.log('Error fetching book contents batch: $e');
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

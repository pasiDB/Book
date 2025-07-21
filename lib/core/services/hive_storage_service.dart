import 'package:hive/hive.dart';
import '../../data/models/book_hive_model.dart';
import '../../domain/entities/book.dart';
import '../../core/constants/app_constants.dart';
import 'dart:developer' as developer;

class HiveStorageService {
  static const String booksBoxName = AppConstants.downloadedBooksKey;
  static const String categoryCacheBoxName = AppConstants.categoryCacheKey;
  static const String appDataBoxName = AppConstants.appDataKey;
  static const String firstLaunchKey = AppConstants.firstLaunchKey;

  // Lazy boxes for better performance
  late final LazyBox<BookHiveModel> _booksBox;
  late final LazyBox<BookCategoryCache> _categoryCacheBox;
  late final Box<dynamic> _appDataBox;

  static HiveStorageService? _instance;
  static HiveStorageService get instance {
    _instance ??= HiveStorageService._internal();
    return _instance!;
  }

  HiveStorageService._internal();

  /// Initialize all Hive boxes
  Future<void> initialize() async {
    await _openBoxes();
  }

  Future<void> _openBoxes() async {
    _booksBox = await Hive.openLazyBox<BookHiveModel>(booksBoxName);
    _categoryCacheBox =
        await Hive.openLazyBox<BookCategoryCache>(categoryCacheBoxName);
    _appDataBox = await Hive.openBox<dynamic>(appDataBoxName);
  }

  /// Check if this is the first time the app is being launched
  Future<bool> isFirstLaunch() async {
    return !(_appDataBox.get(firstLaunchKey, defaultValue: false) as bool);
  }

  /// Mark first launch as completed
  Future<void> markFirstLaunchCompleted() async {
    await _appDataBox.put(firstLaunchKey, true);
  }

  /// Reset first launch flag (for testing or clearing data)
  Future<void> resetFirstLaunchFlag() async {
    await _appDataBox.delete(firstLaunchKey);
  }

  /// Cache books for a specific category
  Future<void> cacheBooksForCategory(String category, List<Book> books) async {
    try {
      developer.log(
          '💾 Starting to cache ${books.length} books for category: $category');
      final hiveBooks =
          books.map((book) => BookHiveModel.fromBook(book)).toList();

      final categoryCache = BookCategoryCache(
        category: category,
        books: hiveBooks,
      );

      await _categoryCacheBox.put(category, categoryCache);

      // Also store individual books in the books box
      for (final hiveBook in hiveBooks) {
        await _booksBox.put(hiveBook.id, hiveBook);
      }

      developer.log('✅ Cached ${books.length} books for category: $category');

      // Verification
      final verification = await getCachedBooksForCategory(category);
      developer.log(
          '🔍 Verification: ${verification?.length ?? 0} books retrieved after caching for $category');
    } catch (e) {
      developer.log('❌ Error caching books for category $category: $e');
      rethrow;
    }
  }

  /// Get cached books for a specific category
  Future<List<Book>?> getCachedBooksForCategory(String category) async {
    try {
      developer.log('🔍 Looking for cached books in category: $category');
      final categoryCache = await _categoryCacheBox.get(category);

      if (categoryCache == null) {
        developer.log('📭 No cached books found for category: $category');
        return null;
      }

      // Check if cache is expired
      if (categoryCache.isExpired) {
        developer.log('⏰ Cache expired for category: $category');
        await _categoryCacheBox.delete(category);
        return null;
      }

      final books =
          categoryCache.books.map((hiveBook) => hiveBook.toBook()).toList();
      developer.log(
          '�� Retrieved ${books.length} cached books for category: $category');
      return books;
    } catch (e) {
      developer
          .log('❌ Error retrieving cached books for category $category: $e');
      return null;
    }
  }

  /// Check if books are cached for a category
  Future<bool> hasCachedBooksForCategory(String category) async {
    try {
      final categoryCache = await _categoryCacheBox.get(category);
      return categoryCache != null && !categoryCache.isExpired;
    } catch (e) {
      developer.log('❌ Error checking cache for category $category: $e');
      return false;
    }
  }

  /// Cache a single book by ID
  Future<void> cacheBook(Book book) async {
    try {
      final hiveBook = BookHiveModel.fromBook(book);
      await _booksBox.put(book.id, hiveBook);
      developer.log('✅ Cached book: ${book.title}');
    } catch (e) {
      developer.log('❌ Error caching book ${book.id}: $e');
      rethrow;
    }
  }

  /// Get a cached book by ID
  Future<Book?> getCachedBook(int bookId) async {
    try {
      final hiveBook = await _booksBox.get(bookId);
      if (hiveBook == null) {
        return null;
      }
      return hiveBook.toBook();
    } catch (e) {
      developer.log('❌ Error retrieving cached book $bookId: $e');
      return null;
    }
  }

  /// Get all cached categories
  Future<List<String>> getCachedCategories() async {
    try {
      final categories = <String>[];
      for (final key in _categoryCacheBox.keys) {
        if (key is String) {
          final cache = await _categoryCacheBox.get(key);
          if (cache != null && !cache.isExpired) {
            categories.add(key);
          }
        }
      }
      return categories;
    } catch (e) {
      developer.log('❌ Error getting cached categories: $e');
      return [];
    }
  }

  /// Get total number of cached books across all categories
  Future<int> getTotalCachedBooksCount() async {
    try {
      return _booksBox.length;
    } catch (e) {
      developer.log('❌ Error getting total cached books count: $e');
      return 0;
    }
  }

  /// Clear cache for a specific category
  Future<void> clearCategoryCache(String category) async {
    try {
      await _categoryCacheBox.delete(category);
      developer.log('🧹 Cleared cache for category: $category');
    } catch (e) {
      developer.log('❌ Error clearing cache for category $category: $e');
    }
  }

  /// Clear all cached books and categories
  Future<void> clearAllCache() async {
    try {
      await _booksBox.clear();
      await _categoryCacheBox.clear();
      developer.log('🧹 Cleared all book cache');
    } catch (e) {
      developer.log('❌ Error clearing all cache: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final expiredKeys = <String>[];

      for (final key in _categoryCacheBox.keys) {
        if (key is String) {
          final cache = await _categoryCacheBox.get(key);
          if (cache != null && cache.isExpired) {
            expiredKeys.add(key);
          }
        }
      }

      for (final key in expiredKeys) {
        await _categoryCacheBox.delete(key);
      }

      developer.log('🧹 Cleared ${expiredKeys.length} expired cache entries');
    } catch (e) {
      developer.log('❌ Error clearing expired cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final totalBooks = await getTotalCachedBooksCount();
      final cachedCategories = await getCachedCategories();

      return {
        'totalBooks': totalBooks,
        'cachedCategories': cachedCategories.length,
        'categoryNames': cachedCategories,
        'cacheSize': _approximateCacheSize(),
      };
    } catch (e) {
      developer.log('❌ Error getting cache stats: $e');
      return {
        'totalBooks': 0,
        'cachedCategories': 0,
        'categoryNames': <String>[],
        'cacheSize': '0 KB',
      };
    }
  }

  String _approximateCacheSize() {
    // Simple estimation - in production, you might want more accurate measurement
    final booksCount = _booksBox.length;
    final categoriesCount = _categoryCacheBox.length;
    final estimatedSizeKB =
        (booksCount * 2) + (categoriesCount * 0.5); // Rough estimate

    if (estimatedSizeKB > 1024) {
      return '${(estimatedSizeKB / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${estimatedSizeKB.toStringAsFixed(1)} KB';
    }
  }

  /// Optimize cache by removing old books not in any category
  Future<void> optimizeCache() async {
    try {
      final categoriesBookIds = <int>{};

      // Collect all book IDs from cached categories
      for (final key in _categoryCacheBox.keys) {
        if (key is String) {
          final cache = await _categoryCacheBox.get(key);
          if (cache != null && !cache.isExpired) {
            categoriesBookIds.addAll(cache.books.map((book) => book.id));
          }
        }
      }

      // Remove books that are not referenced by any category
      final booksToRemove = <int>[];
      for (final key in _booksBox.keys) {
        if (key is int && !categoriesBookIds.contains(key)) {
          booksToRemove.add(key);
        }
      }

      for (final bookId in booksToRemove) {
        await _booksBox.delete(bookId);
      }

      developer.log(
          '🧹 Optimized cache: removed ${booksToRemove.length} orphaned books');
    } catch (e) {
      developer.log('❌ Error optimizing cache: $e');
    }
  }

  /// Close all boxes (call this when app is closing)
  Future<void> close() async {
    try {
      await _booksBox.close();
      await _categoryCacheBox.close();
      await _appDataBox.close();
      developer.log('🔒 Closed all Hive boxes');
    } catch (e) {
      developer.log('❌ Error closing Hive boxes: $e');
    }
  }

  /// Force data persistence (useful before app shutdown)
  Future<void> flush() async {
    try {
      // Force write any pending data to disk
      await _booksBox.flush();
      await _categoryCacheBox.flush();
      await _appDataBox.flush();
    } catch (e) {
      developer.log('❌ Error flushing Hive data: $e');
    }
  }
}

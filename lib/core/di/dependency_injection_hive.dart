import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/hive_storage_service.dart';
import '../services/api_service_optimized.dart';
import '../services/cache_service_optimized.dart';
import '../../data/datasources/book_remote_data_source_optimized_v2.dart';
import '../../data/datasources/book_local_data_source_hive.dart';
import '../../data/repositories/book_repository_optimized.dart';
import '../../data/repositories/reading_repository_impl.dart';
import '../../data/models/book_hive_model.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/usecases/get_books_by_topic.dart';
import '../../domain/usecases/search_books.dart';
import '../../domain/usecases/get_book_content.dart';
import '../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../presentation/bloc/book/book_bloc_optimized_v2.dart';
import '../../presentation/bloc/book/book_event.dart';
import '../constants/app_constants.dart';

class DependencyInjectionHive {
  static late final Dio _dio;
  static late final SharedPreferences _sharedPreferences;
  static late final HiveStorageService _hiveStorageService;
  static late final ApiServiceOptimized _apiService;
  static late final CacheServiceOptimized _cacheService;
  static late final BookRemoteDataSourceOptimized _remoteDataSource;
  static late final BookLocalDataSourceHive _localDataSource;
  static late final BookRepository _bookRepository;
  static late final ReadingRepository _readingRepository;
  static late final BookBlocOptimizedV2 _bookBloc;

  static Future<void> initialize() async {
    print('🚀 Initializing Hive-based dependency injection...');

    try {
      // Initialize Hive first
      print('📦 Step 1: Initializing Hive storage...');
      await _initializeHive();

      // Initialize core dependencies
      print('🔧 Step 2: Initializing core dependencies...');
      await _initializeCore();

      // Initialize services
      print('⚙️ Step 3: Initializing services...');
      await _initializeServices();

      // Initialize data sources
      print('📊 Step 4: Initializing data sources...');
      _initializeDataSources();

      // Initialize repositories
      print('🏪 Step 5: Initializing repositories...');
      _initializeRepositories();

      // Initialize use cases
      print('🎯 Step 6: Initializing use cases...');
      _initializeUseCases();

      // Initialize BLoCs
      print('🧠 Step 7: Initializing BLoCs...');
      _initializeBlocs();

      print('✅ Hive-based dependency injection initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error during Hive DI initialization: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _initializeHive() async {
    print('📦 Initializing Hive storage...');

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BookHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BookCategoryCacheAdapter());
    }

    // Initialize and open Hive storage service
    _hiveStorageService = HiveStorageService.instance;
    await _hiveStorageService.initialize();

    print('✅ Hive storage initialized');
  }

  static Future<void> _initializeCore() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30), // Increased from 15
      receiveTimeout: const Duration(seconds: 60), // Increased from 15
      sendTimeout: const Duration(seconds: 30), // Increased from 15
      headers: {
        'User-Agent': AppConstants.userAgent,
        'Accept': AppConstants.acceptHeader,
        'Connection': AppConstants.connectionHeader,
      },
    ));

    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> _initializeServices() async {
    _apiService = ApiServiceOptimized(_dio);
    _cacheService = CacheServiceOptimized(_sharedPreferences);
  }

  static void _initializeDataSources() {
    _remoteDataSource =
        BookRemoteDataSourceOptimizedImpl(_apiService, _cacheService);
    _localDataSource = BookLocalDataSourceHive(_sharedPreferences);
  }

  static void _initializeRepositories() {
    _bookRepository = BookRepositoryOptimized(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );
    print('🏗️ [Hive DI] Created repository: ${_bookRepository.runtimeType}');
    _readingRepository = ReadingRepositoryImpl(_sharedPreferences);
  }

  static void _initializeUseCases() {
    // Use cases will be created when needed in BLoC
  }

  static void _initializeBlocs() {
    print(
        '🏗️ [Hive DI] Creating BLoC with repository: ${_bookRepository.runtimeType}');
    final getBooksByTopic = GetBooksByTopic(_bookRepository);
    print(
        '🏗️ [Hive DI] Created GetBooksByTopic with repository: ${getBooksByTopic.repository.runtimeType}');

    _bookBloc = BookBlocOptimizedV2(
      getBooksByTopic: getBooksByTopic,
      getBooksByTopicWithPagination:
          GetBooksByTopicWithPagination(_bookRepository),
      searchBooks: SearchBooks(_bookRepository),
      getBookContent: GetBookContent(_bookRepository),
      getBookContentByGutenbergId: GetBookContentByGutenbergId(_bookRepository),
      bookRepository: _bookRepository,
      readingRepository: _readingRepository,
    );
    print('🏗️ [Hive DI] Created BLoC: ${_bookBloc.runtimeType}');
  }

  // Getters for dependencies
  static Dio get dio => _dio;
  static SharedPreferences get sharedPreferences => _sharedPreferences;
  static HiveStorageService get hiveStorageService => _hiveStorageService;
  static ApiServiceOptimized get apiService => _apiService;
  static CacheServiceOptimized get cacheService => _cacheService;
  static BookRemoteDataSourceOptimized get remoteDataSource =>
      _remoteDataSource;
  static BookLocalDataSourceHive get localDataSource => _localDataSource;
  static BookRepository get bookRepository => _bookRepository;
  static ReadingRepository get readingRepository => _readingRepository;
  static BookBlocOptimizedV2 get bookBloc => _bookBloc;

  // Factory methods for use cases
  static GetBooksByTopic getBooksByTopic() => GetBooksByTopic(_bookRepository);
  static GetBooksByTopicWithPagination getBooksByTopicWithPagination() =>
      GetBooksByTopicWithPagination(_bookRepository);
  static SearchBooks searchBooks() => SearchBooks(_bookRepository);
  static GetBookContent getBookContent() => GetBookContent(_bookRepository);
  static GetBookContentByGutenbergId getBookContentByGutenbergId() =>
      GetBookContentByGutenbergId(_bookRepository);

  // Performance and cache monitoring
  static Map<String, dynamic> get performanceStats => {
        'cacheStats': _cacheService.cacheStats,
        'hiveStats': _getHiveStats(),
        'memoryUsage': _getMemoryUsage(),
      };

  static Future<Map<String, dynamic>> _getHiveStats() async {
    try {
      return await _hiveStorageService.getCacheStats();
    } catch (e) {
      print('❌ Error getting Hive stats: $e');
      return {
        'totalBooks': 0,
        'cachedCategories': 0,
        'cacheSize': '0 KB',
      };
    }
  }

  static double _getMemoryUsage() {
    // Simple memory usage estimation
    return 0.0; // TODO: Implement actual memory monitoring
  }

  // First launch and cache management methods
  static Future<bool> isFirstLaunch() async {
    final result = await _localDataSource.isFirstLaunch();
    print('🔍 First launch check: $result');
    return result;
  }

  static Future<void> markFirstLaunchCompleted() async {
    print('✅ Marking first launch as completed');
    await _localDataSource.markFirstLaunchCompleted();
    final verification = await _localDataSource.isFirstLaunch();
    print('🔍 First launch verification after marking complete: $verification');
  }

  static Future<bool> areAllCategoriesCached() async {
    final result = await _localDataSource.areAllCategoriesCached();
    print('🔍 Are all categories cached: $result');
    if (!result) {
      final cacheStats = await _localDataSource.getCacheStatistics();
      print('📊 Cache stats: $cacheStats');
    }
    return result;
  }

  static Future<Map<String, dynamic>> getCacheStatistics() async {
    return await _localDataSource.getCacheStatistics();
  }

  static Future<void> optimizeCache() async {
    await _localDataSource.optimizeCache();
  }

  static Future<void> clearExpiredCache() async {
    await _localDataSource.clearExpiredCache();
  }

  static Future<void> resetToFirstLaunch() async {
    await _localDataSource.resetFirstLaunchFlag();
    await _localDataSource.clearAllBookCache();
    print('🔄 Reset to first launch - cleared all cache');
  }

  // Cleanup method
  static Future<void> dispose() async {
    try {
      _bookBloc.close();
      await _hiveStorageService.flush();
      await _hiveStorageService.close();
      _dio.close();
      print('🧹 Hive-based dependencies disposed');
    } catch (e) {
      print('❌ Error disposing dependencies: $e');
    }
  }
}

/// Enhanced BLoC with Hive-based caching logic
class BookBlocHiveOptimized extends BookBlocOptimizedV2 {
  final BookLocalDataSourceHive _localDataSource;

  BookBlocHiveOptimized({
    required GetBooksByTopic getBooksByTopic,
    required GetBooksByTopicWithPagination getBooksByTopicWithPagination,
    required SearchBooks searchBooks,
    required GetBookContent getBookContent,
    required GetBookContentByGutenbergId getBookContentByGutenbergId,
    required BookRepository bookRepository,
    required ReadingRepository readingRepository,
    required BookLocalDataSourceHive localDataSource,
  })  : _localDataSource = localDataSource,
        super(
          getBooksByTopic: getBooksByTopic,
          getBooksByTopicWithPagination: getBooksByTopicWithPagination,
          searchBooks: searchBooks,
          getBookContent: getBookContent,
          getBookContentByGutenbergId: getBookContentByGutenbergId,
          bookRepository: bookRepository,
          readingRepository: readingRepository,
        );

  /// Enhanced default category loading with first launch detection
  @override
  Future<void> loadDefaultCategoryAndSetState() async {
    if (AppConstants.bookCategories.isEmpty) return;

    final defaultCategory = AppConstants.bookCategories.first;

    print('📱 Loading default category: $defaultCategory');

    // Check if this is the first launch
    final isFirstLaunch = await _localDataSource.isFirstLaunch();

    if (isFirstLaunch) {
      print('🚀 First launch detected - will load all categories');
      // On first launch, load default category first, then load others in background
      add(LoadBooksByTopic(defaultCategory));

      // Mark first launch as completed and start background loading
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _localDataSource.markFirstLaunchCompleted();
        await preloadOtherCategoriesInBackground();
      });
    } else {
      // Not first launch - check if we have cached data
      final hasCachedBooks =
          await _localDataSource.hasCachedBooksForCategory(defaultCategory);

      if (hasCachedBooks) {
        print('📦 Loading from cache: $defaultCategory');
        add(LoadBooksByTopic(defaultCategory));
      } else {
        print('⚠️ No cached data found, loading from API');
        add(LoadBooksByTopic(defaultCategory));
      }
    }
  }

  /// Enhanced preloading that respects first launch logic
  @override
  Future<void> preloadOtherCategoriesInBackground() async {
    if (AppConstants.bookCategories.length <= 1) return;

    final categoriesToPreload = AppConstants.bookCategories.skip(1);

    print(
        '🔄 Preloading ${categoriesToPreload.length} categories in background...');

    for (final category in categoriesToPreload) {
      try {
        // Check if already cached
        final hasCached =
            await _localDataSource.hasCachedBooksForCategory(category);
        if (!hasCached) {
          print('📥 Preloading category: $category');
          add(PreloadBooksByTopic(category));

          // Add small delay between requests to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          print('✅ Category already cached: $category');
        }
      } catch (e) {
        print('❌ Error preloading category $category: $e');
      }
    }

    print('✅ Background preloading completed');
  }

  /// Get cache statistics for debugging/analytics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    return await _localDataSource.getCacheStatistics();
  }

  /// Force refresh all categories (useful for pull-to-refresh)
  Future<void> forceRefreshAllCategories() async {
    print('🔄 Force refreshing all categories...');
    await _localDataSource.clearAllBookCache();

    for (final category in AppConstants.bookCategories) {
      add(LoadBooksByTopic(category));
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

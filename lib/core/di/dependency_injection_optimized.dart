import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service_optimized.dart';
import '../services/cache_service_optimized.dart';
import '../../data/datasources/book_remote_data_source_optimized_v2.dart';
import '../../data/datasources/book_local_data_source.dart';
import '../../data/repositories/book_repository_optimized.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/usecases/get_books_by_topic.dart';
import '../../domain/usecases/search_books.dart';
import '../../domain/usecases/get_book_content.dart';
import '../../presentation/bloc/book/book_bloc_optimized_v2.dart';
import '../constants/app_constants.dart';

class DependencyInjectionOptimized {
  static late final Dio _dio;
  static late final SharedPreferences _sharedPreferences;
  static late final ApiServiceOptimized _apiService;
  static late final CacheServiceOptimized _cacheService;
  static late final BookRemoteDataSourceOptimized _remoteDataSource;
  static late final BookLocalDataSource _localDataSource;
  static late final BookRepository _bookRepository;
  static late final ReadingRepository _readingRepository;
  static late final BookBlocOptimizedV2 _bookBloc;

  static Future<void> initialize() async {
    print('🚀 Initializing optimized dependency injection...');

    // Initialize core dependencies
    await _initializeCore();

    // Initialize data sources
    _initializeDataSources();

    // Initialize repositories
    _initializeRepositories();

    // Initialize use cases
    _initializeUseCases();

    // Initialize BLoCs
    _initializeBlocs();

    print('✅ Optimized dependency injection initialized successfully');
  }

  static Future<void> _initializeCore() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'BookReader/2.0.0',
        'Accept': 'application/json',
        'Connection': 'keep-alive',
      },
    ));

    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static void _initializeDataSources() {
    _apiService = ApiServiceOptimized();
    _cacheService = CacheServiceOptimized(_sharedPreferences);
    _remoteDataSource =
        BookRemoteDataSourceOptimizedImpl(_apiService, _cacheService);
    _localDataSource = BookLocalDataSourceImpl(_sharedPreferences);
  }

  static void _initializeRepositories() {
    _bookRepository = BookRepositoryOptimized(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );
    _readingRepository = _bookRepository as ReadingRepository;
  }

  static void _initializeUseCases() {
    // Use cases will be created when needed
  }

  static void _initializeBlocs() {
    _bookBloc = BookBlocOptimizedV2(
      getBooksByTopic: GetBooksByTopic(_bookRepository),
      getBooksByTopicWithPagination:
          GetBooksByTopicWithPagination(_bookRepository),
      searchBooks: SearchBooks(_bookRepository),
      getBookContent: GetBookContent(_bookRepository),
      bookRepository: _bookRepository,
    );
  }

  // Getters for dependencies
  static Dio get dio => _dio;
  static SharedPreferences get sharedPreferences => _sharedPreferences;
  static ApiServiceOptimized get apiService => _apiService;
  static CacheServiceOptimized get cacheService => _cacheService;
  static BookRemoteDataSourceOptimized get remoteDataSource =>
      _remoteDataSource;
  static BookLocalDataSource get localDataSource => _localDataSource;
  static BookRepository get bookRepository => _bookRepository;
  static ReadingRepository get readingRepository => _readingRepository;
  static BookBlocOptimizedV2 get bookBloc => _bookBloc;

  // Factory methods for use cases
  static GetBooksByTopic getBooksByTopic() => GetBooksByTopic(_bookRepository);
  static GetBooksByTopicWithPagination getBooksByTopicWithPagination() =>
      GetBooksByTopicWithPagination(_bookRepository);
  static SearchBooks searchBooks() => SearchBooks(_bookRepository);
  static GetBookContent getBookContent() => GetBookContent(_bookRepository);

  // Performance monitoring
  static Map<String, dynamic> get performanceStats => {
        'cacheStats': _cacheService.cacheStats,
        'memoryUsage': _getMemoryUsage(),
      };

  static double _getMemoryUsage() {
    // Simple memory usage estimation
    return 0.0; // TODO: Implement actual memory monitoring
  }

  // Cleanup method
  static void dispose() {
    _apiService.dispose();
    _bookBloc.close();
    print('🧹 Optimized dependencies disposed');
  }
}

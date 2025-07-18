import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../../data/datasources/book_remote_data_source.dart';
import '../../data/datasources/book_local_data_source.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/usecases/get_books_by_topic.dart';
import '../../domain/usecases/get_book_content.dart';
import '../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../domain/usecases/search_books.dart';
import '../../presentation/bloc/book/book_bloc_optimized.dart';

class DependencyInjection {
  static late final Dio _dio;
  static late final SharedPreferences _sharedPreferences;
  static late final ApiService _apiService;
  static late final CacheService _cacheService;
  static late final BookRemoteDataSource _remoteDataSource;
  static late final BookLocalDataSource _localDataSource;
  static late final BookRepository _bookRepository;
  static late final ReadingRepository _readingRepository;
  static late final BookBlocOptimized _bookBloc;

  // Expose dependencies for access
  static Dio get dio => _dio;
  static SharedPreferences get sharedPreferences => _sharedPreferences;
  static ApiService get apiService => _apiService;
  static CacheService get cacheService => _cacheService;
  static BookRemoteDataSource get remoteDataSource => _remoteDataSource;
  static BookLocalDataSource get localDataSource => _localDataSource;
  static BookRepository get bookRepository => _bookRepository;
  static ReadingRepository get readingRepository => _readingRepository;
  static BookBlocOptimized get bookBloc => _bookBloc;

  static Future<void> initialize() async {
    print('🚀 Initializing dependency injection...');

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

    print('✅ Dependency injection initialized successfully');
  }

  static Future<void> _initializeCore() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': 'BookReader/1.0.0',
        'Accept': 'application/json',
      },
    ));

    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static void _initializeDataSources() {
    _apiService = ApiService(_dio);
    _cacheService = CacheService(_sharedPreferences);
    _remoteDataSource = BookRemoteDataSourceImpl(_dio);
    _localDataSource = BookLocalDataSourceImpl(_sharedPreferences);
  }

  static void _initializeRepositories() {
    _bookRepository = BookRepositoryImpl(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );
    _readingRepository = _bookRepository as ReadingRepository;
  }

  static void _initializeUseCases() {
    // Initialize use cases for BLoC initialization
    final getBooksByTopic = GetBooksByTopic(_bookRepository);
    final getBooksByTopicWithPagination =
        GetBooksByTopicWithPagination(_bookRepository);
    final searchBooks = SearchBooks(_bookRepository);
    final getBookContent = GetBookContent(_bookRepository);
    final getBookContentByGutenbergId =
        GetBookContentByGutenbergId(_bookRepository);

    // Initialize BLoC with use cases
    _bookBloc = BookBlocOptimized(
      getBooksByTopic: getBooksByTopic,
      getBooksByTopicWithPagination: getBooksByTopicWithPagination,
      searchBooks: searchBooks,
      getBookContent: getBookContent,
      getBookContentByGutenbergId: getBookContentByGutenbergId,
      bookRepository: _bookRepository,
    );
  }

  static void _initializeBlocs() {
    // BLoC is already initialized in _initializeUseCases
  }

  static void dispose() {
    _dio.close();
    _bookBloc.close();
  }
}

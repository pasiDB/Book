import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../../data/datasources/book_remote_data_source.dart';
import '../../data/datasources/book_local_data_source.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/usecases/get_books_by_topic.dart';
import '../../domain/usecases/search_books.dart';
import '../../domain/usecases/get_book_content.dart';
import '../../domain/usecases/get_book_content_by_gutenberg_id.dart';
import '../../presentation/bloc/book/book_bloc_optimized.dart';
import '../constants/app_constants.dart';

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

  static Future<void> initialize() async {
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
    // Use cases will be created when needed
  }

  static void _initializeBlocs() {
    _bookBloc = BookBlocOptimized(
      getBooksByTopic: GetBooksByTopic(_bookRepository),
      getBooksByTopicWithPagination:
          GetBooksByTopicWithPagination(_bookRepository),
      searchBooks: SearchBooks(_bookRepository),
      getBookContent: GetBookContent(_bookRepository),
      getBookContentByGutenbergId: GetBookContentByGutenbergId(_bookRepository),
      bookRepository: _bookRepository,
    );
  }

  // Getters for dependencies
  static Dio get dio => _dio;
  static SharedPreferences get sharedPreferences => _sharedPreferences;
  static BookRemoteDataSource get remoteDataSource => _remoteDataSource;
  static BookLocalDataSource get localDataSource => _localDataSource;
  static BookRepository get bookRepository => _bookRepository;
  static ReadingRepository get readingRepository => _readingRepository;
  static BookBlocOptimized get bookBloc => _bookBloc;

  // Factory methods for use cases
  static GetBooksByTopic getBooksByTopic() => GetBooksByTopic(_bookRepository);
  static GetBooksByTopicWithPagination getBooksByTopicWithPagination() =>
      GetBooksByTopicWithPagination(_bookRepository);
  static SearchBooks searchBooks() => SearchBooks(_bookRepository);
  static GetBookContent getBookContent() => GetBookContent(_bookRepository);
  static GetBookContentByGutenbergId getBookContentByGutenbergId() =>
      GetBookContentByGutenbergId(_bookRepository);
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/book_remote_data_source.dart';
import 'data/datasources/book_local_data_source.dart';
import 'data/repositories/book_repository_impl.dart';
import 'data/repositories/reading_repository_impl.dart';
import 'domain/repositories/book_repository.dart';
import 'domain/repositories/reading_repository.dart';
import 'domain/usecases/get_books_by_topic.dart';
import 'domain/usecases/search_books.dart';
import 'domain/usecases/get_book_content.dart';
import 'domain/usecases/get_book_content_by_gutenberg_id.dart';
import 'presentation/bloc/book/book_bloc_optimized_v2.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/search_page.dart';
import 'presentation/pages/library_page.dart';
import 'presentation/pages/book_detail_page.dart';
import 'presentation/pages/book_reader_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/widgets/modern_loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(MyApp(sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    // Initialize Dio with increased timeouts
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60), // Increased from 30
      receiveTimeout: const Duration(seconds: 60), // Increased from 30
      sendTimeout: const Duration(seconds: 60), // Added send timeout
      headers: {
        'User-Agent': 'BookReader/1.0 (Flutter App)',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for better error handling
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        print('Dio Error: ${error.message}');
        print('Error Type: ${error.type}');
        print('Error Response: ${error.response?.statusCode}');

        // Handle specific error types
        if (error.type == DioExceptionType.receiveTimeout) {
          print('Network timeout - request took too long to receive data');
        } else if (error.type == DioExceptionType.connectionTimeout) {
          print('Connection timeout - failed to establish connection');
        } else if (error.type == DioExceptionType.connectionError) {
          print('Connection error - no internet connection');
        }

        handler.next(error);
      },
      onRequest: (options, handler) {
        print('Making request to: ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('Received response: ${response.statusCode}');
        handler.next(response);
      },
    ));

    // Initialize data sources
    final bookRemoteDataSource = BookRemoteDataSourceImpl(dio);
    final bookLocalDataSource = BookLocalDataSourceImpl(sharedPreferences);

    // Initialize repositories
    final BookRepository bookRepository = BookRepositoryImpl(
      remoteDataSource: bookRemoteDataSource,
      localDataSource: bookLocalDataSource,
    );

    final ReadingRepository readingRepository =
        ReadingRepositoryImpl(sharedPreferences);

    // Initialize use cases
    final getBooksByTopic = GetBooksByTopic(bookRepository);
    final getBooksByTopicWithPagination =
        GetBooksByTopicWithPagination(bookRepository);
    final searchBooks = SearchBooks(bookRepository);
    final getBookContent = GetBookContent(bookRepository);
    final getBookContentByGutenbergId =
        GetBookContentByGutenbergId(bookRepository);

    // Initialize BLoCs
    final bookBloc = BookBlocOptimizedV2(
      getBooksByTopic: getBooksByTopic,
      getBooksByTopicWithPagination: getBooksByTopicWithPagination,
      searchBooks: searchBooks,
      getBookContent: getBookContent,
      getBookContentByGutenbergId: getBookContentByGutenbergId,
      bookRepository: bookRepository,
      readingRepository: readingRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<BookBlocOptimizedV2>.value(value: bookBloc),
      ],
      child: MaterialApp(
        title: 'Book Reader',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(bookBloc: bookBloc),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final BookBlocOptimizedV2 bookBloc;
  const SplashScreen({super.key, required this.bookBloc});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  bool _loadingDone = false;

  @override
  void initState() {
    super.initState();
    _preloadAllCategories();
  }

  Future<void> _preloadAllCategories() async {
    await widget.bookBloc.loadDefaultCategoryAndSetState();
    setState(() {
      _progress = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _loadingDone = true;
    });
    // Start preloading other categories in the background
    widget.bookBloc.preloadOtherCategoriesInBackground();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDone) {
      // Use router-based navigation after splash
      return _MainAppRouter(bookBloc: widget.bookBloc);
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ModernLoadingIndicator(),
            const SizedBox(height: 32),
            Text(
              'Loading your library...',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surface,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${(_progress * 100).toInt()}%',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MainAppRouter extends StatelessWidget {
  final BookBlocOptimizedV2 bookBloc;

  const _MainAppRouter({required this.bookBloc});

  @override
  Widget build(BuildContext context) {
    // Rebuild the router-based app after splash
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final shellNavigatorKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/book/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final bookId = int.parse(state.pathParameters['id']!);
            return BookDetailPage(bookId: bookId);
          },
        ),
        GoRoute(
          path: '/reader/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final bookId = int.parse(state.pathParameters['id']!);
            return BookReaderPage(bookId: bookId);
          },
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookBlocOptimizedV2>.value(value: bookBloc),
      ],
      child: MaterialApp.router(
        title: 'Book Reader',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/library');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/dependency_injection_hive.dart';
import 'core/theme/app_theme.dart';
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

  print('🚀 [Main] Starting Hive-optimized app initialization...');

  try {
    // Initialize Hive
    print('📦 [Main] Initializing Hive...');
    await Hive.initFlutter();
    print('✅ [Main] Hive initialized successfully');

    // Initialize Hive-optimized dependency injection
    print('🏗️ [Main] Initializing Hive dependency injection...');
    await DependencyInjectionHive.initialize();

    print('✅ [Main] Hive dependency injection completed');

    print('🎉 [Main] All initialization completed successfully');
  } catch (e, stackTrace) {
    print('❌ [Main] Initialization failed: $e');
    print('📍 [Main] Stack trace: $stackTrace');
    // Still run the app to see what happens
  }

  runApp(const MyAppHiveOptimized());
}

class MyAppHiveOptimized extends StatelessWidget {
  const MyAppHiveOptimized({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookBlocOptimizedV2>.value(
          value: DependencyInjectionHive.bookBloc,
        ),
      ],
      child: MaterialApp(
        title: 'Book Reader - Hive Optimized',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SplashScreenHiveOptimized(),
      ),
    );
  }
}

class SplashScreenHiveOptimized extends StatefulWidget {
  const SplashScreenHiveOptimized({super.key});

  @override
  State<SplashScreenHiveOptimized> createState() =>
      _SplashScreenHiveOptimizedState();
}

class _SplashScreenHiveOptimizedState extends State<SplashScreenHiveOptimized> {
  double _progress = 0.0;
  bool _loadingDone = false;

  @override
  void initState() {
    super.initState();
    _preloadAllCategories();
  }

  Future<void> _preloadAllCategories() async {
    final bookBloc = DependencyInjectionHive.bookBloc;
    await bookBloc.loadDefaultCategoryAndSetState();
    setState(() {
      _progress = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _loadingDone = true;
    });
    // Start preloading other categories in the background
    bookBloc.preloadOtherCategoriesInBackground();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDone) {
      // Use router-based navigation after splash
      return _MainAppRouterHiveOptimized();
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

class _MainAppRouterHiveOptimized extends StatelessWidget {
  const _MainAppRouterHiveOptimized();

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
        BlocProvider<BookBlocOptimizedV2>.value(
          value: DependencyInjectionHive.bookBloc,
        ),
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

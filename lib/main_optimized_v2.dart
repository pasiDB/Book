import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/dependency_injection_optimized.dart';
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

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize optimized dependency injection
  await DependencyInjectionOptimized.initialize();

  runApp(const MyAppOptimizedV2());
}

class MyAppOptimizedV2 extends StatelessWidget {
  const MyAppOptimizedV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookBlocOptimizedV2>.value(
          value: DependencyInjectionOptimized.bookBloc,
        ),
      ],
      child: MaterialApp(
        title: 'Book Reader Optimized',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SplashScreenOptimizedV2(),
      ),
    );
  }
}

class SplashScreenOptimizedV2 extends StatefulWidget {
  const SplashScreenOptimizedV2({super.key});

  @override
  State<SplashScreenOptimizedV2> createState() =>
      _SplashScreenOptimizedV2State();
}

class _SplashScreenOptimizedV2State extends State<SplashScreenOptimizedV2> {
  double _progress = 0.0;
  bool _loadingDone = false;

  @override
  void initState() {
    super.initState();
    _preloadAllCategories();
  }

  Future<void> _preloadAllCategories() async {
    final bookBloc = DependencyInjectionOptimized.bookBloc;

    // Load default category
    await bookBloc.loadDefaultCategoryAndSetState();

    setState(() {
      _progress = 0.5;
    });

    // Preload other categories in background
    await bookBloc.preloadOtherCategoriesInBackground();

    setState(() {
      _progress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _loadingDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDone) {
      return const _MainAppRouterOptimizedV2();
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
              'Loading your optimized library...',
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
            const SizedBox(height: 16),
            Text(
              'Optimized for speed and performance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainAppRouterOptimizedV2 extends StatelessWidget {
  const _MainAppRouterOptimizedV2();

  @override
  Widget build(BuildContext context) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final shellNavigatorKey = GlobalKey<NavigatorState>();

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) =>
              MainScaffoldOptimizedV2(child: child),
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
            final workKey = state.pathParameters['id']!;
            return BookDetailPage(workKey: workKey);
          },
        ),
        GoRoute(
          path: '/reader/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final workKey = state.pathParameters['id']!;
            return BookReaderPage(workKey: workKey);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Book Reader Optimized',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffoldOptimizedV2 extends StatefulWidget {
  final Widget child;

  const MainScaffoldOptimizedV2({super.key, required this.child});

  @override
  State<MainScaffoldOptimizedV2> createState() =>
      _MainScaffoldOptimizedV2State();
}

class _MainScaffoldOptimizedV2State extends State<MainScaffoldOptimizedV2> {
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

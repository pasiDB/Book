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
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final bookBloc = DependencyInjectionHive.bookBloc;

    try {
      // Check if this is the first launch
      final isFirstLaunch = await DependencyInjectionHive.isFirstLaunch();

      if (isFirstLaunch) {
        await _handleFirstLaunch(bookBloc);
      } else {
        await _handleSubsequentLaunch(bookBloc);
      }
    } catch (e) {
      print('❌ Error during app initialization: $e');
      // Fallback to normal loading
      await _handleSubsequentLaunch(bookBloc);
    }
  }

  Future<void> _handleFirstLaunch(BookBlocOptimizedV2 bookBloc) async {
    setState(() {
      _loadingMessage = 'Setting up your library...';
      _progress = 0.1;
    });

    print('🚀 First launch - Loading all categories');

    // Load default category first to show content quickly
    await bookBloc.loadDefaultCategoryAndSetState();

    setState(() {
      _loadingMessage = 'Loading books...';
      _progress = 0.5;
    });

    // Give time for the default category to load
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _loadingMessage = 'Almost ready...';
      _progress = 0.8;
    });

    // Start background preloading (this will continue after navigation)
    bookBloc.preloadOtherCategoriesInBackground();

    setState(() {
      _progress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _loadingDone = true;
    });
  }

  Future<void> _handleSubsequentLaunch(BookBlocOptimizedV2 bookBloc) async {
    setState(() {
      _loadingMessage = 'Loading your library...';
      _progress = 0.3;
    });

    // Check if we have cached data
    final areAllCached = await DependencyInjectionHive.areAllCategoriesCached();

    if (areAllCached) {
      print('📦 All categories cached - Fast load');
      setState(() {
        _loadingMessage = 'Ready!';
        _progress = 0.9;
      });
    } else {
      print('⚠️ Some categories missing - Loading from cache and API');
      setState(() {
        _loadingMessage = 'Loading missing data...';
        _progress = 0.6;
      });
    }

    // Load default category (will use cache if available)
    await bookBloc.loadDefaultCategoryAndSetState();

    setState(() {
      _progress = 1.0;
      _loadingMessage = 'Ready!';
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _loadingDone = true;
    });

    // Start background preloading if needed
    if (!areAllCached) {
      bookBloc.preloadOtherCategoriesInBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDone) {
      return const _MainAppRouterHiveOptimized();
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
              _loadingMessage,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
            const SizedBox(height: 16),
            Text(
              '${(_progress * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            // Show cache info for debugging
            FutureBuilder<Map<String, dynamic>>(
              future: DependencyInjectionHive.getCacheStatistics(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Text(
                    'Cached: ${stats['totalBooks']} books, ${stats['cachedCategories']} categories',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final shellNavigatorKey = GlobalKey<NavigatorState>();

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) =>
              MainScaffoldHiveOptimized(child: child),
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
              builder: (context, state) => const SettingsPageHiveOptimized(),
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

    return MaterialApp.router(
      title: 'Book Reader - Hive Optimized',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffoldHiveOptimized extends StatefulWidget {
  final Widget child;

  const MainScaffoldHiveOptimized({super.key, required this.child});

  @override
  State<MainScaffoldHiveOptimized> createState() =>
      _MainScaffoldHiveOptimizedState();
}

class _MainScaffoldHiveOptimizedState extends State<MainScaffoldHiveOptimized> {
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

// Enhanced Settings Page with Hive cache management
class SettingsPageHiveOptimized extends StatefulWidget {
  const SettingsPageHiveOptimized({super.key});

  @override
  State<SettingsPageHiveOptimized> createState() =>
      _SettingsPageHiveOptimizedState();
}

class _SettingsPageHiveOptimizedState extends State<SettingsPageHiveOptimized> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Cache Statistics
          FutureBuilder<Map<String, dynamic>>(
            future: DependencyInjectionHive.getCacheStatistics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  leading: Icon(Icons.storage),
                  title: Text('Cache Statistics'),
                  subtitle: Text('Loading...'),
                );
              }

              final stats = snapshot.data!;
              return ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Cache Statistics'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Books: ${stats['totalBooks']}'),
                    Text('Categories: ${stats['cachedCategories']}'),
                    Text('Size: ${stats['cacheSize']}'),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Cache Management
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh All Data'),
            subtitle: const Text('Re-download all books from server'),
            onTap: _isClearing ? null : _refreshAllData,
          ),

          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Optimize Cache'),
            subtitle: const Text('Clean up unused data'),
            onTap: _isClearing ? null : _optimizeCache,
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Reset app to first launch state'),
            onTap: _isClearing ? null : _clearAllData,
          ),

          if (_isClearing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshAllData() async {
    setState(() => _isClearing = true);

    try {
      await DependencyInjectionHive.resetToFirstLaunch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Data refreshed successfully. Please restart the app.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  Future<void> _optimizeCache() async {
    setState(() => _isClearing = true);

    try {
      await DependencyInjectionHive.optimizeCache();
      await DependencyInjectionHive.clearExpiredCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache optimized successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error optimizing cache: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will delete all cached books and reset the app. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);

      try {
        await DependencyInjectionHive.resetToFirstLaunch();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('All data cleared. Restart the app to see changes.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      } finally {
        setState(() => _isClearing = false);
      }
    }
  }
}

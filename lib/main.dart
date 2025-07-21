import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'remote_config_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';

import 'core/di/dependency_injection_hive.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'presentation/bloc/book/book_bloc_optimized_v2.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/search_page.dart';
import 'presentation/pages/library_page.dart';
import 'presentation/pages/book_detail_page.dart';
import 'presentation/pages/book_reader_page.dart';
import 'presentation/pages/settings_page.dart';

import 'presentation/widgets/modern_loading_indicator.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('🚀 [Main] Starting Hive-optimized app initialization...');

  try {
    // Initialize Hive
    developer.log('📦 [Main] Initializing Hive...');
    await Hive.initFlutter();
    developer.log('✅ [Main] Hive initialized successfully');

    // Initialize Hive-optimized dependency injection
    developer.log('🏗️ [Main] Initializing Hive dependency injection...');
    await DependencyInjectionHive.initialize();

    developer.log('✅ [Main] Hive dependency injection completed');

    developer.log('🎉 [Main] All initialization completed successfully');
  } catch (e, stackTrace) {
    developer.log('❌ [Main] Initialization failed: $e');
    developer.log('📍 [Main] Stack trace: $stackTrace');
    // Still run the app to see what happens
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await RemoteConfigService.instance.init();
  RemoteConfigService.instance.listenForUrlChanges();

  // Initialize settings service
  await SettingsService.instance.init();

  runApp(const GlobalWebViewWrapper(child: MyAppHiveOptimized()));
}

class MyAppHiveOptimized extends StatelessWidget {
  const MyAppHiveOptimized({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: SettingsService.instance,
      child: Consumer<SettingsService>(
        builder: (context, settings, child) {
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
              themeMode: settings.themeMode,
              debugShowCheckedModeBanner: false,
              home: const SplashScreenHiveOptimized(),
            ),
          );
        },
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
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
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
            themeMode: settings.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
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

class GlobalWebViewWrapper extends StatefulWidget {
  final Widget child;
  const GlobalWebViewWrapper({super.key, required this.child});

  @override
  State<GlobalWebViewWrapper> createState() => _GlobalWebViewWrapperState();
}

class _GlobalWebViewWrapperState extends State<GlobalWebViewWrapper> {
  String? _url;
  late final ValueNotifier<String?> _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = RemoteConfigService.instance.urlNotifier;
    _url = RemoteConfigService.instance.actualUrl;
    _notifier.addListener(_onUrlChanged);
    // Set initial value if already present
    if (_url != null && _url!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
    }
  }

  void _onUrlChanged() {
    final newUrl = _notifier.value;
    if (newUrl != null && newUrl.isNotEmpty && newUrl != _url) {
      setState(() {
        _url = newUrl;
      });
    } else if ((newUrl == null || newUrl.isEmpty) &&
        _url != null &&
        _url!.isNotEmpty) {
      setState(() {
        _url = null;
      });
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_onUrlChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_url != null && _url!.isNotEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadRequest(Uri.parse(_url!)),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

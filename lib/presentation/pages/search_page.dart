import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/book/book_bloc_optimized_v2.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/book_card.dart';
import '../widgets/modern_loading_indicator.dart';
import '../../core/services/search_history_service.dart';
import '../../core/constants/app_constants.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isSearching = false;
  bool _showHistory = false;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initHistory();
  }

  Future<void> _initHistory() async {
    await SearchHistoryService.instance.init();
    setState(() {
      _history = SearchHistoryService.instance.history;
    });
  }

  void _addToHistory(String query) async {
    await SearchHistoryService.instance.addQuery(query);
    setState(() {
      _history = SearchHistoryService.instance.history;
    });
  }

  void _clearHistory() async {
    await SearchHistoryService.instance.clearHistory();
    setState(() {
      _history = [];
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {
      _showHistory = _searchController.text.isEmpty;
    });
    _debounce = Timer(AppConstants.defaultDebounce, () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        setState(() => _isSearching = true);
        final bloc = context.read<BookBlocOptimizedV2>();
        bloc.add(SearchBooksEvent(query));
        _addToHistory(query);
      } else {
        setState(() => _isSearching = false);
      }
    });
  }

  void _onSubmitted(String value) {
    final query = value.trim();
    if (query.isNotEmpty) {
      setState(() => _isSearching = true);
      final bloc = context.read<BookBlocOptimizedV2>();
      bloc.add(SearchBooksEvent(query));
      _addToHistory(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _showHistory = true;
    });
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _showHistory = hasFocus && _searchController.text.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final focusNode = FocusNode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 1,
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        titleTextStyle: theme.appBarTheme.titleTextStyle,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Focus(
              onFocusChange: _onFocusChange,
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSubmitted,
                decoration: InputDecoration(
                  hintText: 'Search for books...',
                  prefixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(
                              12.0), // Could be AppConstants.defaultPadding if used elsewhere
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                ),
              ),
            ),
          ),
          // Search History
          if (_showHistory && _history.isNotEmpty)
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Searches',
                            style: theme.textTheme.titleSmall),
                        TextButton(
                          onPressed: _clearHistory,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  ..._history.map((q) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(q),
                        onTap: () {
                          _searchController.text = q;
                          _onSubmitted(q);
                          setState(() => _showHistory = false);
                        },
                      )),
                ],
              ),
            ),
          if (!_showHistory)
            // Search Results
            Expanded(
              child: BlocConsumer<BookBlocOptimizedV2, BookState>(
                listener: (context, state) {
                  if (!state.isLoading) {
                    setState(() => _isSearching = false);
                  }
                },
                builder: (context, state) {
                  if (_searchController.text.trim().isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search for your favorite books',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter a title, author, or subject',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.isLoading) {
                    return const ModernLoadingIndicator();
                  }

                  if (state.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search failed',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.books.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No books found',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return isLargeScreen
                      ? GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.defaultPadding),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            return BookCard(
                              book: book,
                              onTap: () {
                                context.go('/book/${book.id}',
                                    extra: {'fromSearch': true});
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.defaultPadding),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            return BookCard(
                              book: book,
                              onTap: () {
                                context.go('/book/${book.id}',
                                    extra: {'fromSearch': true});
                              },
                            );
                          },
                        );
                },
              ),
            ),
        ],
      ),
    );
  }
}

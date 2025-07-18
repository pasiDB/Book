import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/book/book_bloc_optimized_v2.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/book_card.dart';
import '../widgets/modern_loading_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<BookBlocOptimizedV2>();
    final state = bloc.state;
    // Only set selectedCategory if not already set
    if (selectedCategory == null && AppConstants.bookCategories.isNotEmpty) {
      if (state.category != null) {
        selectedCategory = state.category;
      } else {
        selectedCategory = AppConstants.bookCategories.first;
        // Only dispatch if cache is empty (should not happen after splash)
        final cachedBooks = bloc.getCachedBooksForCategory(selectedCategory!);
        if (cachedBooks == null || cachedBooks.isEmpty) {
          bloc.add(LoadBooksByTopic(selectedCategory!));
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _switchCategory(String category) {
    setState(() {
      selectedCategory = category;
    });

    // Reset scroll position to top
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    final bloc = context.read<BookBlocOptimizedV2>();
    final cachedBooks = bloc.getCachedBooksForCategory(category);
    if (cachedBooks != null && cachedBooks.isNotEmpty) {
      bloc.emit(bloc.state.copyWith(
        books: cachedBooks,
        isLoading: false,
        category: category,
      ));
    } else {
      bloc.add(LoadBooksByTopic(category));
    }
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('timeout') || error.contains('Timeout')) {
      return 'The request took too long to complete. This might be due to a slow internet connection or server issues. Please try again.';
    } else if (error.contains('connection') || error.contains('Connection')) {
      return 'No internet connection. Please check your network settings and try again.';
    } else if (error.contains('Failed to fetch books')) {
      return 'Failed to load books from the server. Please try again later or select a different category.';
    } else if (error.contains('No books found')) {
      return 'No books found for this category. Please try a different category.';
    } else if (error.contains('DioException')) {
      return 'Network error occurred. Please check your internet connection and try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Shelf'),
        elevation: 1,
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        titleTextStyle: theme.appBarTheme.titleTextStyle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Section - Always visible
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'Categories',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppConstants.bookCategories.length,
              itemBuilder: (context, index) {
                final category = AppConstants.bookCategories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label:
                        Text(category[0].toUpperCase() + category.substring(1)),
                    selected: isSelected,
                    onSelected: (_) {
                      _switchCategory(category);
                    },
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.chipTheme.backgroundColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : (theme.chipTheme.labelStyle?.color ?? Colors.black),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: isSelected ? 2 : 0,
                  ),
                );
              },
            ),
          ),
          // Books Section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text(
              'Books',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: BlocBuilder<BookBlocOptimizedV2, BookState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const ModernLoadingIndicator();
                } else if (state.error != null) {
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
                          'Unable to load books',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _getUserFriendlyErrorMessage(state.error!),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                final bloc =
                                    context.read<BookBlocOptimizedV2>();
                                bloc.add(LoadBooksByTopic(selectedCategory!));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                // Try a different category
                                final categories = AppConstants.bookCategories;
                                final currentIndex =
                                    categories.indexOf(selectedCategory!);
                                final nextIndex =
                                    (currentIndex + 1) % categories.length;
                                _switchCategory(categories[nextIndex]);
                              },
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Try Different Category'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else if (state.books.isNotEmpty) {
                  return isLargeScreen
                      ? GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                context.go('/book/${book.id}');
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            return BookCard(
                              book: book,
                              onTap: () {
                                context.go('/book/${book.id}');
                              },
                            );
                          },
                        );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/book/book_bloc.dart';
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
    final bloc = context.read<BookBloc>();
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

    final bloc = context.read<BookBloc>();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Reader'),
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
            child: BlocBuilder<BookBloc, BookState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const ModernLoadingIndicator();
                } else if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load books',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            final bloc = context.read<BookBloc>();
                            bloc.add(LoadBooksByTopic(selectedCategory!));
                          },
                          child: const Text('Retry'),
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
                            return BookCard(book: book);
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            return BookCard(book: book);
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

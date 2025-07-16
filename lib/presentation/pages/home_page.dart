import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/book_card.dart';
import '../widgets/category_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/modern_loading_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCategory;

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
      body: BlocBuilder<BookBloc, BookState>(
        builder: (context, state) {
          final currentCategory = state.category ?? selectedCategory;
          if (state.isLoading) {
            return const ModernLoadingIndicator();
          } else if (state.error != null) {
            return Center(child: Text('Error:  {state.error}'));
          } else if (state.books.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories Section
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
                      final isSelected = currentCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(category[0].toUpperCase() +
                              category.substring(1)),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                            final bloc = context.read<BookBloc>();
                            final cachedBooks =
                                bloc.getCachedBooksForCategory(category);
                            if (cachedBooks != null && cachedBooks.isNotEmpty) {
                              bloc.emit(bloc.state.copyWith(
                                books: cachedBooks,
                                isLoading: false,
                                category: category,
                              ));
                            } else {
                              bloc.add(LoadBooksByTopic(category));
                            }
                          },
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.chipTheme.backgroundColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : (theme.chipTheme.labelStyle?.color ??
                                    Colors.black),
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
                  child: isLargeScreen
                      ? GridView.builder(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            return BookCard(book: book);
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

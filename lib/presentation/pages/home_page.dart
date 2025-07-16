import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/book_card.dart';
import '../widgets/category_card.dart';
import '../widgets/loading_shimmer.dart';

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
        bloc.add(LoadBooksByTopic(selectedCategory!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Reader'),
        elevation: 0,
      ),
      body: BlocBuilder<BookBloc, BookState>(
        builder: (context, state) {
          final currentCategory = state.category ?? selectedCategory;
          if (state.isLoading) {
            return const LoadingShimmer();
          } else if (state.error != null) {
            return Center(child: Text('Error:  {state.error}'));
          } else if (state.books.isNotEmpty) {
            return Column(
              children: [
                // Categories Section
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AppConstants.bookCategories.length,
                    itemBuilder: (context, index) {
                      final category = AppConstants.bookCategories[index];
                      final isSelected = currentCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CategoryCard(
                          category: category,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                            });
                            context
                                .read<BookBloc>()
                                .add(LoadBooksByTopic(category));
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Books Section
                Expanded(
                  child: ListView.builder(
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

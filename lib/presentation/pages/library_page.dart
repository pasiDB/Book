import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/book/book_bloc_optimized_v2.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/book_card.dart';
import '../widgets/modern_loading_indicator.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // Load currently reading books when the page is initialized
    context.read<BookBlocOptimizedV2>().add(const LoadCurrentlyReadingBooks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        elevation: 1,
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: BlocBuilder<BookBlocOptimizedV2, BookState>(
        builder: (context, state) {
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
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading library',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<BookBlocOptimizedV2>()
                          .add(const LoadCurrentlyReadingBooks());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.currentlyReadingBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your library is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add books to your library to see them here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Books'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.currentlyReadingBooks.length,
            itemBuilder: (context, index) {
              final book = state.currentlyReadingBooks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BookCard(
                  book: book,
                  onTap: () {
                    context.go('/book/${book.id}');
                  },
                  isInLibrary: true,
                  showProgress: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

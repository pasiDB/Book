import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/book/book_bloc_optimized_v2.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../../domain/entities/book.dart';
import '../widgets/modern_loading_indicator.dart';
//import 'dart:developer' as developer;

class BookDetailPage extends StatefulWidget {
  final int bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _addedToLibrary = false;

  @override
  void initState() {
    super.initState();
    context.read<BookBlocOptimizedV2>().add(LoadBookById(widget.bookId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        }
        // Optionally, you can navigate to home instead of closing the app
        context.go('/');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Book Details'),
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        body: BlocListener<BookBlocOptimizedV2, BookState>(
          listenWhen: (previous, current) {
            // Listen for changes in currentlyReadingBooks
            return previous.currentlyReadingBooks.length !=
                current.currentlyReadingBooks.length;
          },
          listener: (context, state) {
            final selectedBook = state.selectedBook;
            if (selectedBook != null &&
                state.currentlyReadingBooks
                    .any((b) => b.id == selectedBook.id)) {
              if (!_addedToLibrary) {
                setState(() {
                  _addedToLibrary = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Book added to Library!'),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: BlocBuilder<BookBlocOptimizedV2, BookState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const ModernLoadingIndicator();
              } else if (state.selectedBook != null) {
                final alreadyInLibrary = state.currentlyReadingBooks
                    .any((b) => b.id == state.selectedBook!.id);
                return _buildBookDetails(state.selectedBook!, alreadyInLibrary);
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
                        'Book Not Available',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This book could not be loaded or is no longer available.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const ModernLoadingIndicator();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetails(Book book, bool alreadyInLibrary) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipBg = isDark
        ? theme.colorScheme.surfaceVariant
        : theme.colorScheme.surfaceVariant;
    final chipText = isDark
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover and Basic Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              Hero(
                tag: 'book_cover_${book.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 180,
                    child: book.coverUrl != null
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.book,
                                size: 60,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.book,
                              size: 60,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${book.authorNames}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: book.hasTextFormat || book.hasHtmlFormat
                      ? () => context.push('/reader/${book.id}')
                      : null,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Read Now'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: alreadyInLibrary
                      ? null
                      : () {
                          context
                              .read<BookBlocOptimizedV2>()
                              .add(AddBookToLibrary(book));
                        },
                  icon: const Icon(Icons.library_add),
                  label:
                      Text(alreadyInLibrary ? 'In Library' : 'Add to Library'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Subjects
          if (book.subjects.isNotEmpty) ...[
            Text(
              'Subjects:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.subjects.take(5).map((subject) {
                return Chip(
                  label: Text(subject, style: TextStyle(color: chipText)),
                  backgroundColor: chipBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Languages
          if (book.languages.isNotEmpty) ...[
            Text(
              'Languages:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.languages.map((language) {
                return Chip(
                  label: Text(language.toUpperCase(),
                      style: TextStyle(color: chipText)),
                  backgroundColor: chipBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }).toList(),
            ),
          ],

          // Bookshelves
          if (book.bookshelves.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Bookshelves:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.bookshelves.map((shelf) {
                return Chip(
                  label: Text(shelf, style: TextStyle(color: chipText)),
                  backgroundColor: chipBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

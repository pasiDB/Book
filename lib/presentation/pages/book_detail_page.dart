import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../../domain/entities/book.dart';

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
    context.read<BookBloc>().add(LoadBookById(widget.bookId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Book Details'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<BookBloc, BookState>(
        listenWhen: (previous, current) {
          // Listen for changes in currentlyReadingBooks
          return previous.currentlyReadingBooks.length !=
              current.currentlyReadingBooks.length;
        },
        listener: (context, state) {
          final selectedBook = state.selectedBook;
          if (selectedBook != null &&
              state.currentlyReadingBooks.any((b) => b.id == selectedBook.id)) {
            if (!_addedToLibrary) {
              setState(() {
                _addedToLibrary = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book added to Library!')),
              );
            }
          }
        },
        child: BlocBuilder<BookBloc, BookState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.selectedBook != null) {
              final alreadyInLibrary = state.currentlyReadingBooks
                  .any((b) => b.id == state.selectedBook!.id);
              return _buildBookDetails(state.selectedBook!, alreadyInLibrary);
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
                      'Error:  {state.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<BookBloc>()
                            .add(LoadBookById(widget.bookId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Loading...'));
          },
        ),
      ),
    );
  }

  Widget _buildBookDetails(Book book, bool alreadyInLibrary) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: book.coverImageUrl != null
                      ? Image.network(
                          book.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.book,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.book,
                            size: 60,
                            color: Colors.grey,
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${book.authorNames}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Format Availability
                    if (book.hasReadableFormat || book.hasEpubFormat)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Formats:',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          // Replace Row with Wrap for format chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (book.hasTextFormat)
                                const Chip(
                                  label: Text('TXT'),
                                  backgroundColor: Colors.blue,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              if (book.hasHtmlFormat)
                                const Chip(
                                  label: Text('HTML'),
                                  backgroundColor: Colors.orange,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              if (book.hasEpubFormat)
                                const Chip(
                                  label: Text('EPUB'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ],
                      ),
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
                child: ElevatedButton.icon(
                  onPressed: book.hasReadableFormat
                      ? () => context.push('/reader/${book.id}')
                      : null,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Read Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: alreadyInLibrary
                      ? null
                      : () {
                          context.read<BookBloc>().add(AddBookToLibrary(book));
                        },
                  icon: const Icon(Icons.library_add),
                  label:
                      Text(alreadyInLibrary ? 'In Library' : 'Add to Library'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.subjects.take(5).map((subject) {
                return Chip(
                  label: Text(subject),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Languages
          if (book.languages.isNotEmpty) ...[
            Text(
              'Languages:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.languages.map((language) {
                return Chip(
                  label: Text(language),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Bookshelves
          if (book.bookshelves.isNotEmpty) ...[
            Text(
              'Bookshelves:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.bookshelves.take(3).map((bookshelf) {
                return Chip(
                  label: Text(bookshelf),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

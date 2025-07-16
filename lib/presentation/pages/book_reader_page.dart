import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../../core/constants/app_constants.dart';

class BookReaderPage extends StatefulWidget {
  final int bookId;

  const BookReaderPage({super.key, required this.bookId});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  double fontSize = AppConstants.defaultFontSize;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBookContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBookContent() async {
    // First get book details to find the text URL
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
        title: BlocBuilder<BookBloc, BookState>(
          builder: (context, state) {
            if (state is BookLoaded) {
              return Text(
                state.book.title,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              );
            }
            return const Text('Reader');
          },
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showFontSizeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Implement bookmarking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarking coming soon!')),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<BookBloc, BookState>(
        listener: (context, state) {
          if (state is BookLoaded) {
            // Book details loaded, now load the content
            // Try to load content using Gutenberg ID first (more reliable)
            context
                .read<BookBloc>()
                .add(LoadBookContentByGutenbergId(state.book.id));
          }
        },
        builder: (context, state) {
          if (state is BookContentLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading book content...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This may take a moment as we fetch the content from Project Gutenberg.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else if (state is BookContentLoaded) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                state.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: fontSize,
                      height: 1.6,
                    ),
              ),
            );
          } else if (state is BookContentError) {
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
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The app is trying to load content using a CORS proxy. If this continues, the book content may be temporarily unavailable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _loadBookContent,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Try loading content directly by Gutenberg ID
                          context
                              .read<BookBloc>()
                              .add(LoadBookContentByGutenbergId(widget.bookId));
                        },
                        child: const Text('Try Direct Load'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Show book details to get the URL
                          context
                              .read<BookBloc>()
                              .add(LoadBookById(widget.bookId));
                        },
                        child: const Text('View Book Info'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else if (state is BookError) {
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
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookContent,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: fontSize,
              min: AppConstants.minFontSize,
              max: AppConstants.maxFontSize,
              divisions: 12,
              label: fontSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  fontSize = value;
                });
              },
            ),
            Text('${fontSize.round()}px'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

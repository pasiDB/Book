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
  bool _isAtEnd = false;

  @override
  void initState() {
    super.initState();
    _loadBookContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = 50.0; // px from bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      if (!_isAtEnd) {
        setState(() {
          _isAtEnd = true;
        });
      }
    } else if (_isAtEnd) {
      setState(() {
        _isAtEnd = false;
      });
    }
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
            if (state.selectedBook != null) {
              return Text(
                state.selectedBook!.title,
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
          if (state.selectedBook != null &&
              (state.bookContentChunks.isEmpty || state.bookContent == null)) {
            // Book details loaded, now load the content
            context
                .read<BookBloc>()
                .add(LoadBookContentByGutenbergId(state.selectedBook!.id));
          }
        },
        builder: (context, state) {
          Widget? progressBar;
          if (state.bookContentChunks.isNotEmpty) {
            final progress =
                (state.currentChunkIndex + 1) / state.bookContentChunks.length;
            progressBar = LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            );
          }
          if (state.isLoading) {
            return Column(
              children: [
                if (progressBar != null) progressBar,
                Expanded(
                  child: Center(
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
                  ),
                ),
              ],
            );
          } else if (state.bookContent != null) {
            return Column(
              children: [
                if (progressBar != null) progressBar,
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      state.bookContent!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: fontSize,
                            height: 1.6,
                          ),
                    ),
                  ),
                ),
                if (state.hasMoreContent && _isAtEnd)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<BookBloc>().add(
                              LoadBookContentChunk(
                                  chunkIndex: state.currentChunkIndex + 1),
                            );
                        // Removed auto-scroll to bottom
                      },
                      child: const Text('Read next'),
                    ),
                  ),
                if (!state.hasMoreContent && _isAtEnd)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Completed',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          } else if (state.error != null) {
            return Column(
              children: [
                if (progressBar != null) progressBar,
                Expanded(
                  child: Center(
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
                          onPressed: _loadBookContent,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

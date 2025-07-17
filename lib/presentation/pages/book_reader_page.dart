import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../../core/constants/app_constants.dart';

import '../../presentation/widgets/modern_loading_indicator.dart';

class BookReaderPage extends StatefulWidget {
  final String workKey;

  const BookReaderPage({super.key, required this.workKey});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  double fontSize = AppConstants.defaultFontSize;
  final ScrollController _scrollController = ScrollController();
  bool _isAtEnd = false;
  bool _progressLoaded = false;
  bool _progressRequested = false;
  bool _contentRequested = false;
  bool _restorationDone = false;

  @override
  void initState() {
    super.initState();
    // Step 1: Always load book details first
    context.read<BookBloc>().add(LoadBookById(widget.workKey));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveReadingProgress();
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
    _saveReadingProgress();
  }

  void _saveReadingProgress() {
    final bloc = context.read<BookBloc>();
    final state = bloc.state;
    if (state.selectedBook != null) {
      bloc.add(SaveReadingProgress(
        workKey: state.selectedBook!.id.toString(),
        chunkIndex: state.currentChunkIndex,
        scrollOffset:
            _scrollController.hasClients ? _scrollController.offset : 0.0,
      ));
    }
  }

  Future<void> _loadBookContent() async {
    // First get book details to find the text URL
    context.read<BookBloc>().add(LoadBookById(widget.workKey));
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
          // Step 2: When book details are loaded, load reading progress (once)
          if (state.selectedBook != null && !_progressRequested) {
            context
                .read<BookBloc>()
                .add(LoadReadingProgress(state.selectedBook!.id));
            _progressRequested = true;
          }
          // Step 3: When book details are loaded, always load content (once)
          if (state.selectedBook != null && !_contentRequested) {
            // For Open Library, trigger content loading here (custom event or direct logic)
            context
                .read<BookBloc>()
                .add(LoadBookContent(state.selectedBook!.id));
            _contentRequested = true;
          }
          // Step 4: When content is loaded, restore chunk and scroll (once, if progress exists)
          if (!_restorationDone &&
              state.bookContentChunks.isNotEmpty &&
              state.readingProgress != null) {
            final progress = state.readingProgress!;
            if (progress.currentPosition < state.bookContentChunks.length) {
              context.read<BookBloc>().add(
                  LoadBookContentChunk(chunkIndex: progress.currentPosition));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (progress.scrollOffset > 0.0) {
                _scrollController.jumpTo(progress.scrollOffset);
              }
              _restorationDone = true;
            });
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
                const Expanded(
                  child: Center(
                    child: ModernLoadingIndicator(),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/book/book_bloc_optimized_v2.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/modern_loading_indicator.dart';
import '../../domain/entities/book.dart';

class BookReaderPage extends StatefulWidget {
  final int bookId;

  const BookReaderPage({super.key, required this.bookId});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentChunkIndex = 0;
  double _scrollOffset = 0.0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Load book details
    context.read<BookBlocOptimizedV2>().add(LoadBookById(widget.bookId));

    // Load reading progress
    context.read<BookBlocOptimizedV2>().add(LoadReadingProgress(widget.bookId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadBookContent() {
    final bloc = context.read<BookBlocOptimizedV2>();
    final state = bloc.state;

    if (state.selectedBook != null) {
      final book = state.selectedBook!;
      if (book.hasTextFormat) {
        context
            .read<BookBlocOptimizedV2>()
            .add(LoadBookContent(book.textDownloadUrl!));
      } else if (book.hasHtmlFormat) {
        context
            .read<BookBlocOptimizedV2>()
            .add(LoadBookContent(book.htmlDownloadUrl!));
      }
    }
  }

  void _loadNextChunk() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      final nextChunkIndex = _currentChunkIndex + 1;
      context
          .read<BookBlocOptimizedV2>()
          .add(LoadBookContentChunk(chunkIndex: nextChunkIndex));

      setState(() {
        _currentChunkIndex = nextChunkIndex;
        _isLoadingMore = false;
      });
    }
  }

  void _saveProgress() {
    final state = context.read<BookBlocOptimizedV2>().state;
    if (state.bookContentChunks.isNotEmpty) {
      context.read<BookBlocOptimizedV2>().add(SaveReadingProgress(
            bookId: widget.bookId,
            chunkIndex: _currentChunkIndex,
            scrollOffset: _scrollOffset,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () {
            _saveProgress();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: BlocBuilder<BookBlocOptimizedV2, BookState>(
          builder: (context, state) {
            if (state.selectedBook != null) {
              return Text(
                state.selectedBook!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
            return const Text('Reading');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Show reading settings
            },
          ),
        ],
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: BlocConsumer<BookBlocOptimizedV2, BookState>(
        listener: (context, state) {
          // Handle reading progress updates
          if (state.readingProgress != null) {
            setState(() {
              _currentChunkIndex = state.readingProgress!.currentPosition;
              _scrollOffset = state.readingProgress!.scrollOffset;
            });
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.selectedBook == null) {
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
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading book',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<BookBlocOptimizedV2>()
                          .add(LoadBookById(widget.bookId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.selectedBook == null) {
            return const ModernLoadingIndicator();
          }

          final book = state.selectedBook!;

          // If no content loaded yet, load it
          if (state.bookContentChunks.isEmpty) {
            _loadBookContent();
            return const ModernLoadingIndicator();
          }

          return Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: state.readingProgress?.progress ?? 0.0,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),

              // Content area
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current chunk content
                      if (_currentChunkIndex < state.bookContentChunks.length)
                        Text(
                          state.bookContentChunks[_currentChunkIndex],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 16,
                          ),
                        ),

                      // Load more button
                      if (state.hasMoreContent &&
                          _currentChunkIndex <
                              state.bookContentChunks.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _isLoadingMore ? null : _loadNextChunk,
                              child: _isLoadingMore
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Load More'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Navigation controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentChunkIndex > 0
                          ? () {
                              setState(() {
                                _currentChunkIndex--;
                              });
                              context.read<BookBlocOptimizedV2>().add(
                                    LoadBookContentChunk(
                                        chunkIndex: _currentChunkIndex),
                                  );
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      '${_currentChunkIndex + 1} / ${state.bookContentChunks.length}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    IconButton(
                      onPressed: state.hasMoreContent
                          ? () {
                              _loadNextChunk();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

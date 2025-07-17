import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../presentation/widgets/modern_loading_indicator.dart';

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
  bool _progressLoaded = false;
  bool _progressRequested = false;
  bool _contentRequested = false;
  bool _restorationDone = false;
  bool _isLoadingNextChunk = false;
  bool _isScrolling = false;
  bool _showControls = true;
  DateTime _lastProgressSave = DateTime.now();
  static const _progressSaveThrottle = Duration(seconds: 2);
  static const _scrollThreshold = 500.0; // Increased threshold
  static const _scrollAnimationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    // Step 1: Always load book details first
    context.read<BookBloc>().add(LoadBookById(widget.bookId));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingNextChunk || !_scrollController.hasClients) return;

    final now = DateTime.now();
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final viewportDimension = _scrollController.position.viewportDimension;

    // Calculate how close to the bottom we are as a percentage
    final scrollPercentage = (maxScroll - currentScroll) / viewportDimension;

    if (!_isScrolling && scrollPercentage <= 0.3) {
      // Within 30% of the bottom
      setState(() {
        _isAtEnd = true;
      });
    } else if (_isAtEnd && scrollPercentage > 0.4) {
      // Move away more than 40% from bottom
      setState(() {
        _isAtEnd = false;
      });
    }

    // Throttle progress saving
    if (now.difference(_lastProgressSave) > _progressSaveThrottle) {
      _lastProgressSave = now;
      _saveReadingProgress();
    }
  }

  void _saveReadingProgress() {
    if (!_scrollController.hasClients) return;

    final bloc = context.read<BookBloc>();
    final state = bloc.state;
    if (state.selectedBook != null) {
      bloc.add(SaveReadingProgress(
        bookId: state.selectedBook!.id,
        chunkIndex: state.currentChunkIndex,
        scrollOffset: _scrollController.offset,
      ));
    }
  }

  Future<void> _loadBookContent() async {
    context.read<BookBloc>().add(LoadBookById(widget.bookId));
  }

  Future<void> _loadNextChunk(BookState state) async {
    if (_isLoadingNextChunk ||
        !state.hasMoreContent ||
        !_scrollController.hasClients) return;

    setState(() {
      _isLoadingNextChunk = true;
      _isScrolling = true;
    });

    try {
      // Save the current content height and scroll position
      final previousContentHeight = _scrollController.position.maxScrollExtent;
      final previousScrollPosition = _scrollController.offset;

      // Load next chunk
      context.read<BookBloc>().add(
            LoadBookContentChunk(chunkIndex: state.currentChunkIndex + 1),
          );

      // Wait for the content to be updated
      await Future.delayed(const Duration(milliseconds: 150));

      // Calculate new scroll position to maintain relative position
      if (_scrollController.hasClients) {
        final newContentHeight = _scrollController.position.maxScrollExtent;
        final heightDifference = newContentHeight - previousContentHeight;

        // If we're near the bottom, scroll to show new content
        if (previousScrollPosition > previousContentHeight - _scrollThreshold) {
          await _scrollController.animateTo(
            previousScrollPosition +
                (heightDifference * 0.3), // Scroll to show 30% of new content
            duration: _scrollAnimationDuration,
            curve: Curves.easeOutCubic,
          );
        }
      }
    } finally {
      setState(() {
        _isLoadingNextChunk = false;
        _isScrolling = false;
        _isAtEnd = false;
      });
    }
  }

  Widget _buildBookContent(String content) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate approximate number of characters that fit in viewport
            final charPerLine =
                (constraints.maxWidth / (fontSize * 0.6)).floor();
            final linesInViewport =
                (constraints.maxHeight / (fontSize * 1.6)).floor();
            final charsInViewport = charPerLine * linesInViewport;

            // Split content into smaller chunks for virtualization
            final chunks = <String>[];
            for (var i = 0; i < content.length; i += charsInViewport) {
              chunks.add(content.substring(
                  i,
                  (i + charsInViewport) < content.length
                      ? i + charsInViewport
                      : content.length));
            }

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 +
                    (MediaQuery.of(context).padding.bottom +
                        56), // Bottom bar height
              ),
              itemCount: chunks.length,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemBuilder: (context, index) {
                final isLastChunk = index == chunks.length - 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectionArea(
                      child: Text(
                        chunks[index],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: fontSize,
                              height: 1.6,
                            ),
                      ),
                    ),
                    if (isLastChunk) const SizedBox(height: 32),
                  ],
                );
              },
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return BlocBuilder<BookBloc, BookState>(
      builder: (context, state) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: _showControls ? Offset.zero : const Offset(0, 1),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Font size decrease
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (fontSize > AppConstants.minFontSize) {
                          setState(() {
                            fontSize = (fontSize - 1).clamp(
                              AppConstants.minFontSize,
                              AppConstants.maxFontSize,
                            );
                          });
                        }
                      },
                    ),
                    // Current font size
                    Text('${fontSize.round()}'),
                    // Font size increase
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (fontSize < AppConstants.maxFontSize) {
                          setState(() {
                            fontSize = (fontSize + 1).clamp(
                              AppConstants.minFontSize,
                              AppConstants.maxFontSize,
                            );
                          });
                        }
                      },
                    ),
                    const Spacer(),
                    // Progress indicator or load more button
                    if (state.hasMoreContent && _isAtEnd)
                      ElevatedButton(
                        onPressed: _isLoadingNextChunk
                            ? null
                            : () => _loadNextChunk(state),
                        child: _isLoadingNextChunk
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load More'),
                      )
                    else if (!state.hasMoreContent && _isAtEnd)
                      const Text(
                        'Completed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarking coming soon!')),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (!_showControls) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }
        },
        child: BlocConsumer<BookBloc, BookState>(
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
              context
                  .read<BookBloc>()
                  .add(LoadBookContentByGutenbergId(state.selectedBook!.id));
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
              final progress = (state.currentChunkIndex + 1) /
                  state.bookContentChunks.length;
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
                    child: _buildBookContent(state.bookContent!),
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
                            'Error: ${state.error}',
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
      ),
    );
  }
}

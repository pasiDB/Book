import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../../core/constants/app_constants.dart';
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
  final PageController _pageController = PageController();
  bool _isAtEnd = false;
  bool _progressLoaded = false;
  bool _progressRequested = false;
  bool _contentRequested = false;
  bool _restorationDone = false;
  bool _isLoadingNextChunk = false;
  bool _isScrolling = false;
  bool _showControls = true;
  int _currentPage = 0;
  List<String> _pages = [];
  DateTime _lastProgressSave = DateTime.now();
  static const _progressSaveThrottle = Duration(seconds: 2);
  final EdgeInsets contentPadding = const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  @override
  void initState() {
    super.initState();
    context.read<BookBloc>().add(LoadBookById(widget.bookId));
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isAtEnd = page == _pages.length - 1;
    });

    final now = DateTime.now();
    if (now.difference(_lastProgressSave) > _progressSaveThrottle) {
      _lastProgressSave = now;
      _saveReadingProgress();
    }
  }

  void _saveReadingProgress() {
    final bloc = context.read<BookBloc>();
    final state = bloc.state;
    if (state.selectedBook != null) {
      bloc.add(SaveReadingProgress(
        bookId: state.selectedBook!.id,
        chunkIndex: state.currentChunkIndex,
        scrollOffset: _currentPage.toDouble(),
      ));
    }
  }

  Future<void> _loadBookContent() async {
    context.read<BookBloc>().add(LoadBookById(widget.bookId));
  }

  Future<void> _loadNextChunk(BookState state) async {
    if (_isLoadingNextChunk || !state.hasMoreContent) return;

    setState(() {
      _isLoadingNextChunk = true;
    });

    try {
      context.read<BookBloc>().add(
            LoadBookContentChunk(chunkIndex: state.currentChunkIndex + 1),
          );

      await Future.delayed(const Duration(milliseconds: 150));
    } finally {
      setState(() {
        _isLoadingNextChunk = false;
        _isAtEnd = false;
      });
    }
  }

  List<String> _splitIntoPages(String content, BoxConstraints constraints) {
    final availableHeight =
        constraints.maxHeight - (contentPadding.top + contentPadding.bottom);
    final availableWidth =
        constraints.maxWidth - (contentPadding.left + contentPadding.right);

    // Calculate how many characters fit in one line
    final charPerLine = (availableWidth / (fontSize * 0.6)).floor();

    // Calculate how many lines fit in one page
    final linesPerPage = (availableHeight / (fontSize * 1.6)).floor();

    // Calculate approximate characters per page
    final charsPerPage = charPerLine * linesPerPage;

    final pages = <String>[];
    int startIndex = 0;

    while (startIndex < content.length) {
      // Find the end of the last complete sentence in this page
      int endIndex = startIndex + charsPerPage;
      if (endIndex < content.length) {
        // Look for the end of a sentence (.!?) followed by a space or newline
        final searchEnd = endIndex + 100; // Look ahead up to 100 chars
        final searchEndIndex =
            searchEnd < content.length ? searchEnd : content.length;
        final searchText = content.substring(endIndex, searchEndIndex);
        final sentenceEndMatch = RegExp(r'[.!?]\s+').firstMatch(searchText);

        if (sentenceEndMatch != null) {
          endIndex += sentenceEndMatch.end;
        } else {
          // If no sentence end found, look for last space
          final lastSpace =
              content.substring(startIndex, endIndex).lastIndexOf(' ');
          if (lastSpace > 0) {
            endIndex = startIndex + lastSpace;
          }
        }
      } else {
        endIndex = content.length;
      }

      pages.add(content.substring(startIndex, endIndex).trim());
      startIndex = endIndex;
    }

    return pages;
  }

  Widget _buildPageContent(String content) {
    return SelectionArea(
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: fontSize,
              height: 1.6,
            ),
      ),
    );
  }

  Widget _buildReader(String content) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            _pages = _splitIntoPages(content, constraints);

            return PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: contentPadding,
                  child: _buildPageContent(_pages[index]),
                );
              },
            );
          },
        ),
        if (_showControls) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 60,
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 60,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
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
                  children: [
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
                    Text('${fontSize.round()}'),
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
                    Text('${_currentPage + 1} / ${_pages.length}'),
                    const Spacer(),
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
            if (state.selectedBook != null && !_progressRequested) {
              context
                  .read<BookBloc>()
                  .add(LoadReadingProgress(state.selectedBook!.id));
              _progressRequested = true;
            }
            if (state.selectedBook != null && !_contentRequested) {
              context
                  .read<BookBloc>()
                  .add(LoadBookContentByGutenbergId(state.selectedBook!.id));
              _contentRequested = true;
            }
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
                  _pageController.jumpToPage(progress.scrollOffset.round());
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
                    child: _buildReader(state.bookContent!),
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

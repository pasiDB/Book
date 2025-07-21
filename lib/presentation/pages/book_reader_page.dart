import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../bloc/book/book_bloc_optimized_v2.dart';
import '../bloc/book/book_event.dart';
import '../bloc/book/book_state.dart';
import '../widgets/modern_loading_indicator.dart';

class BookReaderPage extends StatefulWidget {
  final int bookId;

  const BookReaderPage({super.key, required this.bookId});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  List<String> _pages = [];
  bool _isLoadingMore = false;
  bool _isProcessingContent = false;
  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  final EdgeInsets _pagePadding = const EdgeInsets.all(16.0);

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
    _pageController.dispose();
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

      final nextChunkIndex = _currentPageIndex + 1;
      context
          .read<BookBlocOptimizedV2>()
          .add(LoadBookContentChunk(chunkIndex: nextChunkIndex));

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _saveProgress() {
    if (_pages.isNotEmpty) {
      context.read<BookBlocOptimizedV2>().add(SaveReadingProgress(
            bookId: widget.bookId,
            chunkIndex: _currentPageIndex,
            scrollOffset: 0.0, // No scroll offset in page mode
          ));
    }
  }

  Future<List<String>> _splitContentIntoPagesAsync(
      String content, Size pageSize) async {
    return await compute(
        _splitContentIntoPages,
        _SplitContentParams(
          content: content,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          pagePadding: _pagePadding,
          pageSize: pageSize,
        ));
  }

  static List<String> _splitContentIntoPages(_SplitContentParams params) {
    final availableWidth = params.pageSize.width -
        (params.pagePadding.left + params.pagePadding.right);
    final availableHeight = params.pageSize.height -
        (params.pagePadding.top + params.pagePadding.bottom);

    // Estimate characters per line based on average character width
    final avgCharWidth = params.fontSize *
        0.6; // Could be AppConstants.charWidthEstimate if reused
    final charsPerLine = (availableWidth / avgCharWidth).round();

    // Estimate lines per page
    final lineHeight = params.fontSize * params.lineHeight;
    final linesPerPage = (availableHeight / lineHeight).round();

    // Estimate characters per page
    final charsPerPage = charsPerLine * linesPerPage;

    final pages = <String>[];
    int currentIndex = 0;

    while (currentIndex < params.content.length) {
      final endIndex =
          (currentIndex + charsPerPage).clamp(0, params.content.length);

      // Find the last complete word within the estimated page size
      String pageContent;
      if (endIndex >= params.content.length) {
        pageContent = params.content.substring(currentIndex);
      } else {
        // Find the last space before the estimated end
        final lastSpaceIndex = params.content.lastIndexOf(' ', endIndex);
        if (lastSpaceIndex > currentIndex) {
          pageContent = params.content.substring(currentIndex, lastSpaceIndex);
        } else {
          // No space found, use the estimated size
          pageContent = params.content.substring(currentIndex, endIndex);
        }
      }

      if (pageContent.isNotEmpty) {
        pages.add(pageContent.trim());
      }

      currentIndex = endIndex;

      // Safety check to prevent infinite loops
      if (currentIndex >= params.content.length) break;
    }

    return pages;
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
    });
    _saveProgress();
  }

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_isLoadingMore) {
      _loadNextChunk();
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

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
              _showReadingSettings(context);
            },
          ),
        ],
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: BlocConsumer<BookBlocOptimizedV2, BookState>(
        listener: (context, state) {
          // Clear pages when book content is cleared (new book loaded)
          if (state.bookContentChunks.isEmpty && _pages.isNotEmpty) {
            setState(() {
              _pages.clear();
              _currentPageIndex = 0;
              _isProcessingContent = false;
            });
          }

          // Handle reading progress updates
          if (state.readingProgress != null) {
            setState(() {
              _currentPageIndex = state.readingProgress!.currentPosition;
            });
            // Restore page position if pages are loaded
            if (_pages.isNotEmpty && _pageController.hasClients) {
              _pageController.jumpToPage(_currentPageIndex);
            }
          }

          // Split content into pages when content is loaded
          if (state.bookContentChunks.isNotEmpty &&
              _pages.isEmpty &&
              !_isProcessingContent) {
            _processContent(state, screenSize);
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

          if (state.selectedBook == null) {
            return const ModernLoadingIndicator();
          }

          // If no content loaded yet, load it
          if (state.bookContentChunks.isEmpty) {
            _loadBookContent();
            return const ModernLoadingIndicator();
          }

          // If processing content, show loading
          if (_isProcessingContent) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ModernLoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Processing book content...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // If pages are empty, show loading
          if (_pages.isEmpty) {
            return const ModernLoadingIndicator();
          }

          final isInLibrary = state.selectedBook != null &&
              state.currentlyReadingBooks
                  .any((b) => b.id == state.selectedBook!.id);
          return Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: _pages.isNotEmpty
                    ? (_currentPageIndex + 1) / _pages.length
                    : 0.0,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),

              // Add to Library button (if not already in library)
              // if (!isInLibrary && state.selectedBook != null)
              //   Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 8.0),
              //     child: ElevatedButton.icon(
              //       icon: const Icn(Icons.library_add),
              //       label: const Text('Add to Library'),
              //       onPressed: () {
              //         context
              //             .read<BookBlocOptimizedV2>()
              //             .add(AddBookToLibrary(state.selectedBook!));
              //       },
              //     ),
              //   )

              // Page content area
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: _pagePadding,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Text(
                              _pages[index],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: _lineHeight,
                                fontSize: _fontSize,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                      onPressed:
                          _currentPageIndex > 0 ? _goToPreviousPage : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      '${_currentPageIndex + 1} / ${_pages.length}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    IconButton(
                      onPressed: _currentPageIndex < _pages.length - 1 ||
                              state.hasMoreContent
                          ? _goToNextPage
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

  void _processContent(BookState state, Size screenSize) async {
    setState(() {
      _isProcessingContent = true;
    });

    try {
      final content = state.bookContentChunks.join('\n\n');
      final pages = await _splitContentIntoPagesAsync(content, screenSize);

      if (mounted) {
        setState(() {
          _pages = pages;
          _isProcessingContent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingContent = false;
        });
        // Show error or fallback to simple splitting
        final content = state.bookContentChunks.join('\n\n');
        _pages = _simpleSplitContent(content, screenSize);
        setState(() {});
      }
    }
  }

  List<String> _simpleSplitContent(String content, Size pageSize) {
    // Fallback simple splitting method
    const charsPerPage = 2000; // Rough estimate
    final pages = <String>[];

    for (int i = 0; i < content.length; i += charsPerPage) {
      final end = (i + charsPerPage).clamp(0, content.length);
      pages.add(content.substring(i, end));
    }

    return pages;
  }

  void _showReadingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        double tempFontSize = _fontSize;
        double tempLineHeight = _lineHeight;
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Text(
                  'Font Size',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: tempFontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 12,
                        label: tempFontSize.round().toString(),
                        onChanged: (value) {
                          setModalState(() => tempFontSize = value);
                        },
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${tempFontSize.round()} px',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Line Height',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Text('1.2',
                        style: TextStyle(
                            fontSize:
                                14)), // Could be AppConstants.minLineHeight
                    Expanded(
                      child: Slider(
                        value: tempLineHeight,
                        min: 1.2, // AppConstants.minLineHeight
                        max: 2.0, // AppConstants.maxLineHeight
                        divisions: 8,
                        label: tempLineHeight.toStringAsFixed(1),
                        onChanged: (value) {
                          setModalState(() => tempLineHeight = value);
                        },
                      ),
                    ),
                    const Text('2.0',
                        style: TextStyle(
                            fontSize: 18)), // AppConstants.maxLineHeight
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    tempLineHeight.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fontSize = tempFontSize;
                        _lineHeight = tempLineHeight;
                      });
                      // Recalculate pages with new settings
                      final state = context.read<BookBlocOptimizedV2>().state;
                      if (state.bookContentChunks.isNotEmpty) {
                        _processContent(state, MediaQuery.of(context).size);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplitContentParams {
  final String content;
  final double fontSize;
  final double lineHeight;
  final EdgeInsets pagePadding;
  final Size pageSize;

  _SplitContentParams({
    required this.content,
    required this.fontSize,
    required this.lineHeight,
    required this.pagePadding,
    required this.pageSize,
  });
}

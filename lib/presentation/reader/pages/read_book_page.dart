import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/reader_helper.dart';
import '../bloc/read_book_bloc.dart';

class ReadBookPage extends StatelessWidget {
  final String bookTitle;
  final String bookUrl;
  final String? bookFormat;
  const ReadBookPage(
      {super.key,
      required this.bookTitle,
      required this.bookUrl,
      this.bookFormat});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReadBookBloc(
        downloadBookFileUseCase: RepositoryProvider.of(context),
        prefsFuture: SharedPreferences.getInstance(),
      )..add(LoadBook(bookUrl, bookTitle, format: bookFormat)),
      child: _ReadBookView(bookTitle: bookTitle),
    );
  }
}

class _ReadBookView extends StatefulWidget {
  final String bookTitle;
  const _ReadBookView({required this.bookTitle});
  @override
  State<_ReadBookView> createState() => _ReadBookViewState();
}

class _ReadBookViewState extends State<_ReadBookView> {
  final ScrollController _scrollController = ScrollController();
  double fontSize = 18;
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle, overflow: TextOverflow.ellipsis),
        actions: [
          BlocBuilder<ReadBookBloc, ReadBookState>(
            builder: (context, state) {
              if (state is ReadBookTextLoaded) {
                return IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: () => _showFontSizeDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ReadBookBloc, ReadBookState>(
        listener: (context, state) {
          if (state is ReadBookTextLoaded && state.scrollPosition != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(state.scrollPosition!);
              }
            });
          }
        },
        builder: (context, state) {
          if (state is ReadBookLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReadBookTextLoaded) {
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  context.read<ReadBookBloc>().add(
                        SaveScrollPosition(
                            widget.bookTitle, _scrollController.offset),
                      );
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  state.content,
                  style: TextStyle(fontSize: fontSize, height: 1.6),
                ),
              ),
            );
          } else if (state is ReadBookPdfLoaded) {
            return _PdfReader(
                filePath: state.filePath, title: widget.bookTitle);
          } else if (state is ReadBookError) {
            return Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: fontSize,
                min: 12,
                max: 32,
                divisions: 10,
                label: fontSize.round().toString(),
                onChanged: (value) => setState(() => fontSize = value),
              ),
              Text('${fontSize.round()}px'),
            ],
          ),
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

class _PdfReader extends StatefulWidget {
  final String filePath;
  final String title;
  const _PdfReader({required this.filePath, required this.title});
  @override
  State<_PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<_PdfReader> {
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _controller;
  bool _isReady = false;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PDFView(
          filePath: widget.filePath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          },
          onViewCreated: (controller) => _controller = controller,
          onPageChanged: (page, total) {
            setState(() {
              _currentPage = page ?? 0;
              _totalPages = total ?? 0;
            });
          },
        ),
        if (!_isReady) const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_totalPages > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

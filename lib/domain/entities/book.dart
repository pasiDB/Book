import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final int id;
  final String title;
  final List<String> authors;
  final List<String> subjects;
  final List<String> bookshelves;
  final List<String> languages;
  final String? downloadCount;
  final Map<String, String> formats;
  final String? coverImageUrl;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.subjects,
    required this.bookshelves,
    required this.languages,
    this.downloadCount,
    required this.formats,
    this.coverImageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        authors,
        subjects,
        bookshelves,
        languages,
        downloadCount,
        formats,
        coverImageUrl,
      ];

  String get authorNames =>
      authors.isNotEmpty ? authors.join(', ') : 'Unknown Author';

  String? get textDownloadUrl {
    // Try different text formats in order of preference
    return formats['text/plain; charset=us-ascii'] ??
        formats['text/plain'] ??
        formats['text/plain; charset=utf-8'] ??
        formats['text/plain; charset=iso-8859-1'];
  }

  String? get epubDownloadUrl => formats['application/epub+zip'];
  String? get htmlDownloadUrl => formats['text/html'];
  String? get mobiDownloadUrl => formats['application/x-mobipocket-ebook'];

  bool get hasTextFormat => textDownloadUrl != null;
  bool get hasEpubFormat => epubDownloadUrl != null;
  bool get hasHtmlFormat => htmlDownloadUrl != null;
  bool get hasMobiFormat => mobiDownloadUrl != null;

  // Check if book has any readable format
  bool get hasReadableFormat => hasTextFormat || hasHtmlFormat;

  // Get the best available format for reading
  String? get bestReadableFormatUrl {
    return textDownloadUrl ?? htmlDownloadUrl;
  }
}

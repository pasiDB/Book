import 'package:equatable/equatable.dart';
import 'reading_progress.dart';

class Book extends Equatable {
  final int id;
  final String title;
  final String? author;
  final List<String> authors;
  final String? coverUrl;
  final String? coverImageUrl;
  final String? description;
  final List<String> languages;
  final List<String> subjects;
  final List<String> bookshelves;
  final ReadingProgress? readingProgress;
  final bool isDownloaded;
  final String? downloadPath;
  final DateTime? lastReadAt;
  final Map<String, String> formats;

  const Book({
    required this.id,
    required this.title,
    this.author,
    this.authors = const [],
    this.coverUrl,
    this.coverImageUrl,
    this.description,
    this.languages = const [],
    this.subjects = const [],
    this.bookshelves = const [],
    this.readingProgress,
    this.isDownloaded = false,
    this.downloadPath,
    this.lastReadAt,
    this.formats = const {},
  });

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        authors,
        coverUrl,
        coverImageUrl,
        description,
        languages,
        subjects,
        bookshelves,
        readingProgress,
        isDownloaded,
        downloadPath,
        lastReadAt,
        formats,
      ];

  Book copyWith({
    int? id,
    String? title,
    String? author,
    List<String>? authors,
    String? coverUrl,
    String? coverImageUrl,
    String? description,
    List<String>? languages,
    List<String>? subjects,
    List<String>? bookshelves,
    ReadingProgress? readingProgress,
    bool? isDownloaded,
    String? downloadPath,
    DateTime? lastReadAt,
    Map<String, String>? formats,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      authors: authors ?? this.authors,
      coverUrl: coverUrl ?? this.coverUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      languages: languages ?? this.languages,
      subjects: subjects ?? this.subjects,
      bookshelves: bookshelves ?? this.bookshelves,
      readingProgress: readingProgress ?? this.readingProgress,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadPath: downloadPath ?? this.downloadPath,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      formats: formats ?? this.formats,
    );
  }

  String? get textDownloadUrl {
    // Try different text formats in order of preference
    return formats['text/plain; charset=us-ascii'] ??
        formats['text/plain'] ??
        formats['text/plain; charset=utf-8'] ??
        formats['text/plain; charset=iso-8859-1'];
  }

  String? get epubDownloadUrl => formats['application/epub+zip'];
  String? get htmlDownloadUrl => formats['text/html'];

  bool get hasTextFormat => textDownloadUrl != null;
  bool get hasEpubFormat => epubDownloadUrl != null;
  bool get hasHtmlFormat => htmlDownloadUrl != null;
  bool get hasReadableFormat => hasTextFormat || hasHtmlFormat;

  // Get the best available format for reading
  String? get bestReadableFormatUrl {
    return textDownloadUrl ?? htmlDownloadUrl;
  }

  // Get author names as a comma-separated string
  String get authorNames {
    if (authors.isNotEmpty) {
      return authors.join(', ');
    }
    return author ?? 'Unknown Author';
  }
}

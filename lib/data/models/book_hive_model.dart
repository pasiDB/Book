import 'package:hive/hive.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_progress.dart';

part 'book_hive_model.g.dart';

@HiveType(typeId: 0)
class BookHiveModel extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? author;

  @HiveField(3)
  List<String> authors;

  @HiveField(4)
  String? coverUrl;

  @HiveField(5)
  String? coverImageUrl;

  @HiveField(6)
  String? description;

  @HiveField(7)
  List<String> languages;

  @HiveField(8)
  List<String> subjects;

  @HiveField(9)
  List<String> bookshelves;

  @HiveField(10)
  ReadingProgress? readingProgress;

  @HiveField(11)
  bool isDownloaded;

  @HiveField(12)
  String? downloadPath;

  @HiveField(13)
  DateTime? lastReadAt;

  @HiveField(14)
  Map<String, String> formats;

  @HiveField(15)
  DateTime cachedAt; // When this book was cached

  BookHiveModel({
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
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  // Convert from Book entity
  factory BookHiveModel.fromBook(Book book) {
    return BookHiveModel(
      id: book.id,
      title: book.title,
      author: book.author,
      authors: List<String>.from(book.authors),
      coverUrl: book.coverUrl,
      coverImageUrl: book.coverImageUrl,
      description: book.description,
      languages: List<String>.from(book.languages),
      subjects: List<String>.from(book.subjects),
      bookshelves: List<String>.from(book.bookshelves),
      readingProgress: book.readingProgress,
      isDownloaded: book.isDownloaded,
      downloadPath: book.downloadPath,
      lastReadAt: book.lastReadAt,
      formats: Map<String, String>.from(book.formats),
    );
  }

  // Convert to Book entity
  Book toBook() {
    return Book(
      id: id,
      title: title,
      author: author,
      authors: List<String>.from(authors),
      coverUrl: coverUrl,
      coverImageUrl: coverImageUrl,
      description: description,
      languages: List<String>.from(languages),
      subjects: List<String>.from(subjects),
      bookshelves: List<String>.from(bookshelves),
      readingProgress: readingProgress,
      isDownloaded: isDownloaded,
      downloadPath: downloadPath,
      lastReadAt: lastReadAt,
      formats: Map<String, String>.from(formats),
    );
  }

  // Factory from JSON (for API responses)
  factory BookHiveModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse ID
      final id = json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0;

      // Parse title
      final title = json['title']?.toString() ?? 'Unknown Title';

      // Parse authors
      String? author;
      List<String> authors = [];
      if (json['authors'] is List && (json['authors'] as List).isNotEmpty) {
        for (final authorData in json['authors'] as List) {
          if (authorData is Map) {
            final name = authorData['name']?.toString();
            if (name != null && name.isNotEmpty) {
              authors.add(name);
            }
          } else {
            final name = authorData?.toString();
            if (name != null && name.isNotEmpty) {
              authors.add(name);
            }
          }
        }
        // Set the primary author as the first one
        if (authors.isNotEmpty) {
          author = authors.first;
        }
      }

      // Parse languages
      final languages = (json['languages'] as List<dynamic>?)
              ?.map((lang) => lang?.toString() ?? '')
              .where((lang) => lang.isNotEmpty)
              .toList() ??
          [];

      // Parse subjects
      final subjects = (json['subjects'] as List<dynamic>?)
              ?.map((subject) => subject?.toString() ?? '')
              .where((subject) => subject.isNotEmpty)
              .toList() ??
          [];

      // Parse bookshelves
      final bookshelves = (json['bookshelves'] as List<dynamic>?)
              ?.map((shelf) => shelf?.toString() ?? '')
              .where((shelf) => shelf.isNotEmpty)
              .toList() ??
          [];

      // Parse formats
      final formats = (json['formats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          ) ??
          {};

      // Get cover URL from formats
      String? coverUrl;
      if (formats.containsKey('image/jpeg')) {
        coverUrl = formats['image/jpeg'];
      }

      return BookHiveModel(
        id: id,
        title: title,
        author: author,
        authors: authors,
        coverUrl: coverUrl,
        languages: languages,
        subjects: subjects,
        bookshelves: bookshelves,
        formats: formats,
      );
    } catch (e) {
      print('Error parsing book hive model: $e');
      // Return a default book model with minimal data
      return BookHiveModel(
        id: 0,
        title: 'Error Loading Book',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'authors': authors,
      'cover_url': coverUrl,
      'cover_image_url': coverImageUrl,
      'description': description,
      'languages': languages,
      'subjects': subjects,
      'bookshelves': bookshelves,
      'reading_progress': readingProgress,
      'is_downloaded': isDownloaded,
      'download_path': downloadPath,
      'last_read_at': lastReadAt?.toIso8601String(),
      'formats': formats,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  // Getter for text download URL similar to Book entity
  String? get textDownloadUrl {
    return formats['text/plain; charset=us-ascii'] ??
        formats['text/plain'] ??
        formats['text/plain; charset=utf-8'] ??
        formats['text/plain; charset=iso-8859-1'];
  }
}

@HiveType(typeId: 1)
class BookCategoryCache extends HiveObject {
  @HiveField(0)
  late String category;

  @HiveField(1)
  late List<BookHiveModel> books;

  @HiveField(2)
  late DateTime cachedAt;

  @HiveField(3)
  late DateTime lastUpdated;

  BookCategoryCache({
    required this.category,
    required this.books,
    DateTime? cachedAt,
    DateTime? lastUpdated,
  })  : cachedAt = cachedAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  bool get isExpired {
    const cacheExpiry = Duration(days: 7); // Cache for 7 days
    return DateTime.now().difference(lastUpdated) > cacheExpiry;
  }
}

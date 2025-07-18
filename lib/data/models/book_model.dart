import '../../domain/entities/book.dart';

class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    super.author,
    super.coverUrl,
    super.description,
    super.languages = const [],
    super.subjects = const [],
    super.readingProgress,
    super.isDownloaded = false,
    super.downloadPath,
    super.lastReadAt,
    super.formats = const {},
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse ID
      final id = json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0;

      // Parse title
      final title = json['title']?.toString() ?? 'Unknown Title';

      // Parse author (take first author if available)
      String? author;
      if (json['authors'] is List && (json['authors'] as List).isNotEmpty) {
        final firstAuthor = json['authors'][0];
        if (firstAuthor is Map) {
          author = firstAuthor['name']?.toString();
        } else {
          author = firstAuthor?.toString();
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

      return BookModel(
        id: id,
        title: title,
        author: author,
        coverUrl: coverUrl,
        languages: languages,
        subjects: subjects,
        formats: formats,
      );
    } catch (e) {
      print('Error parsing book model: $e');
      // Return a default book model with minimal data
      return const BookModel(
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
      'cover_url': coverUrl,
      'description': description,
      'languages': languages,
      'subjects': subjects,
      'reading_progress': readingProgress,
      'is_downloaded': isDownloaded,
      'download_path': downloadPath,
      'last_read_at': lastReadAt?.toIso8601String(),
      'formats': formats,
    };
  }
}

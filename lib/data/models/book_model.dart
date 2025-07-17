import '../../domain/entities/book.dart';

class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    required super.authors,
    required super.subjects,
    required super.bookshelves,
    required super.languages,
    super.downloadCount,
    required super.formats,
    super.coverImageUrl,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      authors: (json['authors'] as List<dynamic>?)
              ?.map((author) {
                if (author is Map && author.containsKey('name')) {
                  return author['name'] as String;
                } else if (author is String) {
                  return author;
                } else {
                  return '';
                }
              })
              .where((name) => name.isNotEmpty)
              .toList() ??
          [],
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((subject) => subject as String)
              .toList() ??
          [],
      bookshelves: (json['bookshelves'] as List<dynamic>?)
              ?.map((bookshelf) => bookshelf as String)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((language) => language as String)
              .toList() ??
          [],
      downloadCount: json['download_count']?.toString(),
      formats: Map<String, String>.from(json['formats'] as Map),
      coverImageUrl: json['formats']?['image/jpeg'] as String?,
    );
  }

  factory BookModel.fromOpenLibrarySubject(Map<String, dynamic> json) {
    // Open Library subject API: https://openlibrary.org/subjects/{subject}.json
    // Each work in 'works' array
    return BookModel(
      id: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((a) => a['name'] as String? ?? '')
              .where((a) => a.isNotEmpty)
              .toList() ??
          [],
      subjects: (json['subject'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      bookshelves: [],
      languages: [],
      downloadCount: null,
      formats: {},
      coverImageUrl: json['cover_id'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_id']}-L.jpg'
          : null,
    );
  }

  factory BookModel.fromOpenLibrarySearch(Map<String, dynamic> json) {
    // Open Library search API: https://openlibrary.org/search.json?q=...
    return BookModel(
      id: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: (json['author_name'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      subjects: (json['subject'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      bookshelves: [],
      languages: (json['language'] as List<dynamic>?)
              ?.map((l) => l as String)
              .toList() ??
          [],
      downloadCount: null,
      formats: {},
      coverImageUrl: json['cover_i'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_i']}-L.jpg'
          : null,
    );
  }

  factory BookModel.fromOpenLibraryWork(Map<String, dynamic> json) {
    // Open Library work API: https://openlibrary.org/works/OL12345W.json
    return BookModel(
      id: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((a) {
                if (a is Map && a.containsKey('name')) {
                  return a['name'] as String? ?? '';
                } else if (a is Map && a.containsKey('author')) {
                  // Sometimes 'author' is a map with a 'key' (reference)
                  return a['author']?['key']?.toString() ?? '';
                } else if (a is String) {
                  return a;
                } else {
                  return '';
                }
              })
              .where((a) => a.isNotEmpty)
              .toList() ??
          [],
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      bookshelves: [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((l) => l['key']?.toString() ?? '')
              .toList() ??
          [],
      downloadCount: null,
      formats: {},
      coverImageUrl: json['covers'] != null &&
              (json['covers'] as List).isNotEmpty
          ? 'https://covers.openlibrary.org/b/id/${(json['covers'] as List).first}-L.jpg'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'subjects': subjects,
      'bookshelves': bookshelves,
      'languages': languages,
      'download_count': downloadCount,
      'formats': formats,
      'cover_image_url': coverImageUrl,
    };
  }
}

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
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        // Remove any non-numeric characters and try parsing
        final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
        return cleanedValue.isEmpty ? 0 : int.parse(cleanedValue);
      }
      return 0;
    }

    try {
      return BookModel(
        id: parseId(json['id']),
        title: json['title'] as String? ?? 'Unknown Title',
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
    } catch (e) {
      // Log the error for debugging purposes
      print('Error parsing BookModel from JSON: $e');
      return BookModel(
        id: 0,
        title: 'Unknown Title',
        authors: [],
        subjects: [],
        bookshelves: [],
        languages: [],
        downloadCount: '0',
        formats: {},
        coverImageUrl: null,
      );
    }
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

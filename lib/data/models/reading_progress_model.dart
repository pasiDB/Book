import '../../domain/entities/reading_progress.dart';
import 'dart:developer' as developer;

class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    required super.bookId,
    required super.progress,
    required super.currentPosition,
    required super.scrollOffset,
    required super.lastReadAt,
    super.bookmarks = const [],
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    try {
      return ReadingProgressModel(
        bookId: json['book_id'] as int,
        progress: (json['progress'] as num).toDouble(),
        currentPosition: json['current_position'] as int,
        scrollOffset: (json['scroll_offset'] as num).toDouble(),
        lastReadAt: DateTime.parse(json['last_read_at'] as String),
        bookmarks: (json['bookmarks'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
      );
    } catch (e) {
      developer.log('Error parsing reading progress model: $e');
      // Return a default reading progress with minimal data
      return ReadingProgressModel(
        bookId: 0,
        progress: 0.0,
        currentPosition: 0,
        scrollOffset: 0.0,
        lastReadAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'progress': progress,
      'current_position': currentPosition,
      'scroll_offset': scrollOffset,
      'last_read_at': lastReadAt.toIso8601String(),
      'bookmarks': bookmarks,
    };
  }
}

import 'package:equatable/equatable.dart';

class ReadingProgress extends Equatable {
  final int bookId;
  final double progress; // 0.0 to 1.0
  final int currentPosition; // Character position in text
  final DateTime lastReadAt;
  final List<int> bookmarks; // List of character positions

  const ReadingProgress({
    required this.bookId,
    required this.progress,
    required this.currentPosition,
    required this.lastReadAt,
    this.bookmarks = const [],
  });

  @override
  List<Object?> get props => [
        bookId,
        progress,
        currentPosition,
        lastReadAt,
        bookmarks,
      ];

  ReadingProgress copyWith({
    int? bookId,
    double? progress,
    int? currentPosition,
    DateTime? lastReadAt,
    List<int>? bookmarks,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      progress: progress ?? this.progress,
      currentPosition: currentPosition ?? this.currentPosition,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

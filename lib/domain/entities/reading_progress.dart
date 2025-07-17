import 'package:equatable/equatable.dart';

class ReadingProgress extends Equatable {
  final String bookId;
  final double progress; // 0.0 to 1.0
  final int currentPosition; // Character position in text
  final double scrollOffset; // Scroll position in the reader
  final DateTime lastReadAt;
  final List<int> bookmarks; // List of character positions

  const ReadingProgress({
    required this.bookId,
    required this.progress,
    required this.currentPosition,
    required this.scrollOffset,
    required this.lastReadAt,
    this.bookmarks = const [],
  });

  @override
  List<Object?> get props => [
        bookId,
        progress,
        currentPosition,
        scrollOffset,
        lastReadAt,
        bookmarks,
      ];

  ReadingProgress copyWith({
    String? bookId,
    double? progress,
    int? currentPosition,
    double? scrollOffset,
    DateTime? lastReadAt,
    List<int>? bookmarks,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      progress: progress ?? this.progress,
      currentPosition: currentPosition ?? this.currentPosition,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

import 'package:equatable/equatable.dart';

class DownloadedBook extends Equatable {
  final int bookId;
  final String title;
  final String author;
  final String filePath;
  final String format; // 'text' or 'epub'
  final DateTime downloadedAt;
  final int fileSize; // in bytes

  const DownloadedBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.filePath,
    required this.format,
    required this.downloadedAt,
    required this.fileSize,
  });

  @override
  List<Object?> get props => [
        bookId,
        title,
        author,
        filePath,
        format,
        downloadedAt,
        fileSize,
      ];

  bool get isTextFormat => format == 'text';
  bool get isEpubFormat => format == 'epub';
}

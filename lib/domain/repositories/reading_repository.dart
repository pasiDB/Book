import '../entities/reading_progress.dart';

abstract class ReadingRepository {
  Future<ReadingProgress?> getReadingProgress(int bookId);
  Future<void> saveReadingProgress(ReadingProgress progress);
  Future<void> updateCurrentPosition(
      int bookId, int position, double progress, double scrollOffset);
  Future<void> addBookmark(int bookId, int position);
  Future<void> removeBookmark(int bookId, int position);
  Future<List<ReadingProgress>> getCurrentlyReadingBooks();
}

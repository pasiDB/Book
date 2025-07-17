import '../entities/reading_progress.dart';

abstract class ReadingRepository {
  Future<ReadingProgress?> getReadingProgress(String workKey);
  Future<void> saveReadingProgress(ReadingProgress progress);
  Future<void> updateCurrentPosition(
      String workKey, int position, double progress, double scrollOffset);
  Future<void> addBookmark(String workKey, int position);
  Future<void> removeBookmark(String workKey, int position);
  Future<List<ReadingProgress>> getCurrentlyReadingBooks();
}

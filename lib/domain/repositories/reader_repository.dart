abstract class ReaderRepository {
  /// Downloads and caches a book file, returns the local file path.
  Future<String> downloadAndCacheBook(String url, String title);

  /// Loads the content of a .txt file from local storage.
  Future<String> loadTxtContent(String filePath);

  /// Returns true if the file exists locally.
  Future<bool> isFileCached(String url, String title);
}

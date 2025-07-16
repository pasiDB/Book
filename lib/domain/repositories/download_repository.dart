import '../entities/downloaded_book.dart';
import '../entities/book.dart';

abstract class DownloadRepository {
  Future<List<DownloadedBook>> getDownloadedBooks();
  Future<DownloadedBook?> getDownloadedBook(int bookId);
  Future<void> downloadBook(Book book, String format);
  Future<void> deleteDownloadedBook(int bookId);
  Future<bool> isBookDownloaded(int bookId);
  Future<String?> getBookFilePath(int bookId);
}

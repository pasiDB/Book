import '../entities/book.dart';
import '../repositories/download_repository.dart';

class DownloadBook {
  final DownloadRepository repository;

  DownloadBook(this.repository);

  Future<void> call(Book book, String format) async {
    await repository.downloadBook(book, format);
  }
}

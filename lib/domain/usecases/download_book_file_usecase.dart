import '../repositories/reader_repository.dart';

class DownloadBookFileUseCase {
  final ReaderRepository repository;
  DownloadBookFileUseCase(this.repository);

  Future<String> call(String url, String title) async {
    return await repository.downloadAndCacheBook(url, title);
  }
}

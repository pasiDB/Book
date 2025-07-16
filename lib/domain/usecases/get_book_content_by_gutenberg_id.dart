import '../repositories/book_repository.dart';

class GetBookContentByGutenbergId {
  final BookRepository repository;

  GetBookContentByGutenbergId(this.repository);

  Future<String> call(int gutenbergId) async {
    return await repository.getBookContentByGutenbergId(gutenbergId);
  }
}

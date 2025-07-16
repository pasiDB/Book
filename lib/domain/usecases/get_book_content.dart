import '../repositories/book_repository.dart';

class GetBookContent {
  final BookRepository repository;

  GetBookContent(this.repository);

  Future<String> call(String textUrl) async {
    return await repository.getBookContent(textUrl);
  }
}

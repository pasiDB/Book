import '../entities/book.dart';
import '../repositories/book_repository.dart';

class GetBooksByTopic {
  final BookRepository repository;

  GetBooksByTopic(this.repository);

  Future<List<Book>> call(String topic) async {
    return await repository.getBooksByTopic(topic);
  }
}

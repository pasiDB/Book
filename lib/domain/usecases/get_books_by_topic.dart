import '../entities/book.dart';
import '../repositories/book_repository.dart';

class GetBooksByTopic {
  final BookRepository repository;

  GetBooksByTopic(this.repository);

  Future<List<Book>> call(String topic) async {
    return await repository.getBooksByTopic(topic);
  }
}

class GetBooksByTopicWithPagination {
  final BookRepository repository;

  GetBooksByTopicWithPagination(this.repository);

  Future<List<Book>> call(String topic,
      {int limit = 10, int offset = 0}) async {
    return await repository.getBooksByTopicWithPagination(topic,
        limit: limit, offset: offset);
  }
}

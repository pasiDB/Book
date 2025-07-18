import '../entities/book.dart';
import '../repositories/book_repository.dart';

class GetBooksByTopic {
  final BookRepository repository;

  GetBooksByTopic(this.repository);

  Future<List<Book>> call(String topic) async {
    print('🎯 [UseCase] GetBooksByTopic called for topic: $topic');
    print('🎯 [UseCase] Repository type: ${repository.runtimeType}');
    final result = await repository.getBooksByTopic(topic);
    print(
        '🎯 [UseCase] Repository returned ${result.length} books for topic: $topic');
    return result;
  }
}

class GetBooksByTopicWithPagination {
  final BookRepository repository;

  GetBooksByTopicWithPagination(this.repository);

  Future<List<Book>> call(String topic,
      {int limit = 10, int offset = 0}) async {
    print(
        '🎯 [UseCase] GetBooksByTopicWithPagination called for topic: $topic (limit: $limit, offset: $offset)');
    print('🎯 [UseCase] Repository type: ${repository.runtimeType}');
    final result = await repository.getBooksByTopicWithPagination(topic,
        limit: limit, offset: offset);
    print(
        '🎯 [UseCase] Repository returned ${result.length} books for topic: $topic');
    return result;
  }
}

import '../entities/book.dart';
import '../repositories/book_repository.dart';
import 'dart:developer' as developer;

class GetBooksByTopic {
  final BookRepository repository;

  GetBooksByTopic(this.repository);

  Future<List<Book>> call(String topic) async {
    developer.log('🎯 [UseCase] GetBooksByTopic called for topic: $topic');
    developer.log('🎯 [UseCase] Repository type: ${repository.runtimeType}');
    final result = await repository.getBooksByTopic(topic);
    developer.log(
        '🎯 [UseCase] Repository returned ${result.length} books for topic: $topic');
    return result;
  }
}

class GetBooksByTopicWithPagination {
  final BookRepository repository;

  GetBooksByTopicWithPagination(this.repository);

  Future<List<Book>> call(String topic,
      {int limit = 10, int offset = 0}) async {
    developer.log(
        '🎯 [UseCase] GetBooksByTopicWithPagination called for topic: $topic (limit: $limit, offset: $offset)');
    developer.log('🎯 [UseCase] Repository type: ${repository.runtimeType}');
    final result = await repository.getBooksByTopicWithPagination(topic,
        limit: limit, offset: offset);
    developer.log(
        '🎯 [UseCase] Repository returned ${result.length} books for topic: $topic');
    return result;
  }
}

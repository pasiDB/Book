import 'package:equatable/equatable.dart';
import '../../../domain/entities/book.dart';

abstract class BookEvent extends Equatable {
  const BookEvent();

  @override
  List<Object?> get props => [];
}

class LoadBooksByTopic extends BookEvent {
  final String topic;

  const LoadBooksByTopic(this.topic);

  @override
  List<Object?> get props => [topic];
}

class SearchBooksEvent extends BookEvent {
  final String query;

  const SearchBooksEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadBookById extends BookEvent {
  final String workKey;

  const LoadBookById(this.workKey);

  @override
  List<Object?> get props => [workKey];
}

class LoadBooksByPage extends BookEvent {
  final int page;

  const LoadBooksByPage(this.page);

  @override
  List<Object?> get props => [page];
}

class LoadBookContent extends BookEvent {
  final String textUrl;

  const LoadBookContent(this.textUrl);

  @override
  List<Object?> get props => [textUrl];
}

class LoadBookContentChunk extends BookEvent {
  final int chunkIndex;
  final int? gutenbergId;
  final String? textUrl;

  const LoadBookContentChunk(
      {required this.chunkIndex, this.gutenbergId, this.textUrl});

  @override
  List<Object?> get props => [chunkIndex, gutenbergId, textUrl];
}

class AddBookToLibrary extends BookEvent {
  final Book book;
  const AddBookToLibrary(this.book);
  @override
  List<Object?> get props => [book];
}

class LoadCurrentlyReadingBooks extends BookEvent {
  const LoadCurrentlyReadingBooks();
  @override
  List<Object?> get props => [];
}

class LoadReadingProgress extends BookEvent {
  final String workKey;
  const LoadReadingProgress(this.workKey);
  @override
  List<Object?> get props => [workKey];
}

class SaveReadingProgress extends BookEvent {
  final String workKey;
  final int chunkIndex;
  final double scrollOffset;
  const SaveReadingProgress({
    required this.workKey,
    required this.chunkIndex,
    required this.scrollOffset,
  });
  @override
  List<Object?> get props => [workKey, chunkIndex, scrollOffset];
}

class PreloadBooksByTopic extends BookEvent {
  final String topic;
  const PreloadBooksByTopic(this.topic);
  @override
  List<Object?> get props => [topic];
}

class LoadMoreBooks extends BookEvent {
  final String category;
  final int currentCount;
  const LoadMoreBooks({required this.category, required this.currentCount});
  @override
  List<Object?> get props => [category, currentCount];
}

class LoadEditionsForWork extends BookEvent {
  final String workKey;
  const LoadEditionsForWork(this.workKey);
  @override
  List<Object?> get props => [workKey];
}

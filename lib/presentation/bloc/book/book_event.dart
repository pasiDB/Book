import 'package:equatable/equatable.dart';

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
  final int bookId;

  const LoadBookById(this.bookId);

  @override
  List<Object?> get props => [bookId];
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

class LoadBookContentByGutenbergId extends BookEvent {
  final int gutenbergId;

  const LoadBookContentByGutenbergId(this.gutenbergId);

  @override
  List<Object?> get props => [gutenbergId];
}

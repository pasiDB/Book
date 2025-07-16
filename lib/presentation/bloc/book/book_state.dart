import 'package:equatable/equatable.dart';
import '../../../domain/entities/book.dart';

abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

class BookInitial extends BookState {}

class BookLoading extends BookState {}

class BooksLoaded extends BookState {
  final List<Book> books;
  final String? category;

  const BooksLoaded(this.books, {this.category});

  @override
  List<Object?> get props => [books, category];
}

class BookLoaded extends BookState {
  final Book book;

  const BookLoaded(this.book);

  @override
  List<Object?> get props => [book];
}

class BookError extends BookState {
  final String message;

  const BookError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookContentLoading extends BookState {}

class BookContentLoaded extends BookState {
  final String content;

  const BookContentLoaded(this.content);

  @override
  List<Object?> get props => [content];
}

class BookContentError extends BookState {
  final String message;

  const BookContentError(this.message);

  @override
  List<Object?> get props => [message];
}

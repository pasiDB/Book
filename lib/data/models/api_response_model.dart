import 'book_model.dart';

class ApiResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<BookModel> results;

  const ApiResponseModel({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((bookJson) =>
              BookModel.fromJson(bookJson as Map<String, dynamic>))
          .toList(),
    );
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/reader_helper.dart';
import '../../domain/repositories/reader_repository.dart';

class ReaderRepositoryImpl implements ReaderRepository {
  final Dio dio;
  ReaderRepositoryImpl(this.dio);

  @override
  Future<String> downloadAndCacheBook(String url, String title) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        ReaderHelper.getLocalFilePath(dir.path, url, fallback: title);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    final response =
        await dio.get(url, options: Options(responseType: ResponseType.bytes));
    await file.writeAsBytes(response.data);
    return filePath;
  }

  @override
  Future<String> loadTxtContent(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw Exception('File not found: $filePath');
  }

  @override
  Future<bool> isFileCached(String url, String title) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        ReaderHelper.getLocalFilePath(dir.path, url, fallback: title);
    return File(filePath).exists();
  }
}

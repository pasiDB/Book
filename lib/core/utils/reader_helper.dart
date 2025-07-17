import 'package:path/path.dart' as p;

class ReaderHelper {
  static bool isPdf(String urlOrPath) {
    return urlOrPath.toLowerCase().endsWith('.pdf');
  }

  static bool isTxt(String urlOrPath) {
    return urlOrPath.toLowerCase().endsWith('.txt');
  }

  static String getFileNameFromUrl(String url, {String? fallback}) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return fallback ?? 'book_file';
  }

  static String getLocalFilePath(String dir, String url, {String? fallback}) {
    final fileName = getFileNameFromUrl(url, fallback: fallback);
    return p.join(dir, fileName);
  }
}

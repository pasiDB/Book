import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'search_history';
  static const int maxHistory = 10;
  static final SearchHistoryService instance = SearchHistoryService._internal();
  SearchHistoryService._internal();

  List<String> _history = [];
  SharedPreferences? _prefs;

  List<String> get history => List.unmodifiable(_history);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _history = _prefs?.getStringList(_key) ?? [];
  }

  Future<void> addQuery(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > maxHistory) {
      _history = _history.sublist(0, maxHistory);
    }
    await _prefs?.setStringList(_key, _history);
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _prefs?.remove(_key);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  SettingsService._internal();

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = AppConstants.defaultFontSize;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load theme mode
    final themeIndex = _prefs.getInt(AppConstants.themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    // Load font size
    _fontSize = _prefs.getDouble(AppConstants.fontSizeKey) ??
        AppConstants.defaultFontSize;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setInt(AppConstants.themeKey, mode.index);
      notifyListeners();
    }
  }

  Future<void> setFontSize(double size) async {
    if (_fontSize != size) {
      _fontSize = size;
      await _prefs.setDouble(AppConstants.fontSizeKey, size);
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setFontSize(AppConstants.defaultFontSize);
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    await _loadSettings();
  }
}

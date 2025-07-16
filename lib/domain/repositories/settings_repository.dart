import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode themeMode);
  Future<double> getFontSize();
  Future<void> setFontSize(double fontSize);
  Future<void> clearAllData();
}

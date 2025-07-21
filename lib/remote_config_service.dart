import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  static RemoteConfigService get instance => _instance;
  late final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService._internal();

  static const Map<String, dynamic> _defaultValues = {
    'url': '{"key":"url","value":""}',
  };

  Future<void> init() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.setDefaults(_defaultValues);
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config fetched and activated');
      debugPrint('Raw URL value: ${_remoteConfig.getString('url')}');
      debugPrint('Parsed actual URL: ${actualUrl}');
    } catch (e, st) {
      debugPrint('Remote Config fetch failed: $e\n$st');
    }
  }

  /// Returns the raw JSON string from Remote Config
  String get rawUrlJson => _remoteConfig.getString('url');

  /// Returns the extracted URL from the JSON string, or empty string if not found
  String get actualUrl {
    try {
      final jsonMap = jsonDecode(rawUrlJson);
      if (jsonMap is Map<String, dynamic> && jsonMap['value'] is String) {
        return jsonMap['value'] as String;
      }
    } catch (e) {
      debugPrint('Error parsing url JSON: $e');
    }
    return '';
  }

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config manually fetched and activated');
      debugPrint('Raw URL value: ${_remoteConfig.getString('url')}');
      debugPrint('Parsed actual URL: ${actualUrl}');
    } catch (e, st) {
      debugPrint('Manual fetch failed: $e\n$st');
    }
  }

  final ValueNotifier<String?> urlNotifier = ValueNotifier<String?>(null);

  void listenForUrlChanges() {
    urlNotifier.value = actualUrl;
    _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      urlNotifier.value = actualUrl;
      debugPrint('Remote Config updated: $actualUrl');
    });
  }
}

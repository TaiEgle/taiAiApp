import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local storage service backed by SharedPreferences
class StorageService {
  static const _kImgConfig = 'ai-image-config';
  static const _kVidConfig = 'ai-video-config';
  static const _kImgHistory = 'ai-image-history';
  static const _kVidHistory = 'ai-video-history';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveImageConfig({
    required String apiUrl,
    required String apiKey,
    required String responseFormat,
  }) async {
    await _prefs?.setString(_kImgConfig, jsonEncode({
      'url': apiUrl,
      'key': apiKey,
      'fmt': responseFormat,
    }));
  }

  static Future<void> saveVideoConfig({
    required String videoBaseUrl,
    required String apiKey,
    required String responseFormat,
  }) async {
    await _prefs?.setString(_kVidConfig, jsonEncode({
      'url': videoBaseUrl,
      'key': apiKey,
      'fmt': responseFormat,
    }));
  }

  static Future<void> saveImageHistory(List<Map<String, dynamic>> history) async {
    await _prefs?.setString(_kImgHistory, jsonEncode(history.take(5).toList()));
  }

  static Future<void> saveVideoHistory(List<Map<String, dynamic>> history) async {
    await _prefs?.setString(_kVidHistory, jsonEncode(history.take(3).toList()));
  }

  // Loaders
  static Map<String, dynamic> loadImageConfig() {
    final raw = _prefs?.getString(_kImgConfig);
    if (raw != null) return jsonDecode(raw) as Map<String, dynamic>;
    return {};
  }

  static Map<String, dynamic> loadVideoConfig() {
    final raw = _prefs?.getString(_kVidConfig);
    if (raw != null) return jsonDecode(raw) as Map<String, dynamic>;
    return {};
  }

  static List<Map<String, dynamic>> loadImageHistory() {
    final raw = _prefs?.getString(_kImgHistory);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static List<Map<String, dynamic>> loadVideoHistory() {
    final raw = _prefs?.getString(_kVidHistory);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

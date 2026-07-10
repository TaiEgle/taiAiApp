import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

/// App-wide state provider using ChangeNotifier
class AppState extends ChangeNotifier {
  // Navigation
  AppMode _appMode = AppMode.image;
  AppMode get appMode => _appMode;
  set appMode(AppMode val) {
    _appMode = val;
    notifyListeners();
  }

  // Shared API config
  String _apiUrl = 'https://apihub.agnes-ai.com/v1/images/generations';
  String get apiUrl => _apiUrl;
  set apiUrl(String val) {
    _apiUrl = val;
    _scheduleSave();
  }

  String _apiKey = '';
  String get apiKey => _apiKey;
  set apiKey(String val) {
    _apiKey = val;
    _scheduleSave();
  }

  String _videoBaseUrl = 'https://apihub.agnes-ai.com';
  String get videoBaseUrl => _videoBaseUrl;
  set videoBaseUrl(String val) {
    _videoBaseUrl = val;
    _scheduleSave();
  }

  ResponseFormat _responseFormat = ResponseFormat.url;
  ResponseFormat get responseFormat => _responseFormat;
  set responseFormat(ResponseFormat val) {
    _responseFormat = val;
    _scheduleSave();
  }

  // Image state
  ImageMode _imageMode = ImageMode.txt2img;
  ImageMode get imageMode => _imageMode;
  set imageMode(ImageMode val) {
    _imageMode = val;
    notifyListeners();
  }

  String _selectedSize = '1024x1024';
  String get selectedSize => _selectedSize;
  set selectedSize(String val) {
    _selectedSize = val;
    notifyListeners();
  }

  List<ImageHistoryItem> _history = [];
  List<ImageHistoryItem> get history => _history;
  set history(List<ImageHistoryItem> val) {
    _history = val;
    notifyListeners();
  }

  void addToHistory(ImageHistoryItem item) {
    _history.insert(0, item);
    if (_history.length > 5) _history = _history.take(5).toList();
    notifyListeners();
    _saveImageHistory();
  }

  // Video state
  VideoMode _videoMode = VideoMode.txt2video;
  VideoMode get videoMode => _videoMode;
  set videoMode(VideoMode val) {
    _videoMode = val;
    notifyListeners();
  }

  String _videoAspectRatio = '16:9';
  String get videoAspectRatio => _videoAspectRatio;
  set videoAspectRatio(String val) {
    _videoAspectRatio = val;
    notifyListeners();
  }

  String _videoDuration = '5';
  String get videoDuration => _videoDuration;
  set videoDuration(String val) {
    _videoDuration = val;
    notifyListeners();
  }

  int _videoFrameRate = 24;
  int get videoFrameRate => _videoFrameRate;
  set videoFrameRate(int val) {
    _videoFrameRate = val;
    notifyListeners();
  }

  int? _videoSeed;
  int? get videoSeed => _videoSeed;
  set videoSeed(int? val) {
    _videoSeed = val;
    notifyListeners();
  }

  String _videoNegativePrompt = '';
  String get videoNegativePrompt => _videoNegativePrompt;
  set videoNegativePrompt(String val) {
    _videoNegativePrompt = val;
    notifyListeners();
  }

  List<VideoHistoryItem> _videoHistory = [];
  List<VideoHistoryItem> get videoHistory => _videoHistory;
  set videoHistory(List<VideoHistoryItem> val) {
    _videoHistory = val;
    notifyListeners();
  }

  void addToVideoHistory(VideoHistoryItem item) {
    _videoHistory.insert(0, item);
    if (_videoHistory.length > 3) _videoHistory = _videoHistory.take(3).toList();
    notifyListeners();
    _saveVideoHistory();
  }

  // Config panel visibility
  bool _configVisible = false;
  bool get configVisible => _configVisible;
  set configVisible(bool val) {
    _configVisible = val;
    notifyListeners();
  }

  void toggleConfig() => _configVisible = !_configVisible;

  // Debounced save timer
  Timer? _saveTimer;
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveConfigs();
    });
  }

  Future<void> _saveConfigs() async {
    await StorageService.saveImageConfig(
      apiUrl: _apiUrl,
      apiKey: _apiKey,
      responseFormat: _responseFormat.name,
    );
    await StorageService.saveVideoConfig(
      videoBaseUrl: _videoBaseUrl,
      apiKey: _apiKey,
      responseFormat: _responseFormat.name,
    );
  }

  Future<void> _saveImageHistory() async {
    await StorageService.saveImageHistory(_history.map((e) => e.toJson()).toList());
  }

  Future<void> _saveVideoHistory() async {
    await StorageService.saveVideoHistory(_videoHistory.map((e) => e.toJson()).toList());
  }

  // Load persisted state
  Future<void> loadState() async {
    final imgConfig = StorageService.loadImageConfig();
    if (imgConfig['url'] != null) _apiUrl = imgConfig['url'] as String;
    if (imgConfig['key'] != null) _apiKey = imgConfig['key'] as String;
    if (imgConfig['fmt'] != null) {
      _responseFormat = imgConfig['fmt'] == 'b64_json' ? ResponseFormat.b64Json : ResponseFormat.url;
    }

    final vidConfig = StorageService.loadVideoConfig();
    if (vidConfig['url'] != null) _videoBaseUrl = vidConfig['url'] as String;
    if (vidConfig['key'] != null) _apiKey = vidConfig['key'] as String;
    if (vidConfig['fmt'] != null) {
      _responseFormat = vidConfig['fmt'] == 'b64_json' ? ResponseFormat.b64Json : ResponseFormat.url;
    }

    _history = StorageService.loadImageHistory()
        .map((e) => ImageHistoryItem.fromJson(e))
        .toList();

    _videoHistory = StorageService.loadVideoHistory()
        .map((e) => VideoHistoryItem.fromJson(e))
        .toList();

    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

/// Top-level mode enum
enum AppMode { image, video }

/// Provider helper
ChangeNotifierProvider<AppState> appProvider() {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const SizedBox.shrink(),
  );
}

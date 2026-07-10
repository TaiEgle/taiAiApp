import 'dart:convert';

// Image size preset
class ImageSize {
  final String label;
  final String value;
  ImageSize({required this.label, required this.value});
}

final List<ImageSize> imageSizes = [
  ImageSize(label: '1024×1024', value: '1024x1024'),
  ImageSize(label: '1024×768', value: '1024x768'),
  ImageSize(label: '768×1024', value: '768x1024'),
  ImageSize(label: '512×512', value: '512x512'),
  ImageSize(label: '512×768', value: '512x768'),
  ImageSize(label: '768×512', value: '768x512'),
];

// Image history item
class ImageHistoryItem {
  final String displaySrc;
  final String prompt;
  final int timestamp;
  ImageHistoryItem({required this.displaySrc, required this.prompt, required this.timestamp});
  Map<String, dynamic> toJson() => {'displaySrc': displaySrc, 'prompt': prompt, 'timestamp': timestamp};
  factory ImageHistoryItem.fromJson(Map<String, dynamic> json) =>
      ImageHistoryItem(displaySrc: json['displaySrc'] as String, prompt: json['prompt'] as String, timestamp: json['timestamp'] as int);
}

// Video history item
class VideoHistoryItem {
  final String videoUrl;
  final String prompt;
  final String durationLabel;
  final int timestamp;
  VideoHistoryItem({required this.videoUrl, required this.prompt, required this.durationLabel, required this.timestamp});
  Map<String, dynamic> toJson() => {'videoUrl': videoUrl, 'prompt': prompt, 'durationLabel': durationLabel, 'timestamp': timestamp};
  factory VideoHistoryItem.fromJson(Map<String, dynamic> json) =>
      VideoHistoryItem(videoUrl: json['videoUrl'] as String, prompt: json['prompt'] as String, durationLabel: json['durationLabel'] as String, timestamp: json['timestamp'] as int);
}

// Video aspect ratio dimensions
class AspectRatioDim {
  final String ratio;
  final int width;
  final int height;
  AspectRatioDim({required this.ratio, required this.width, required this.height});
}

final List<AspectRatioDim> aspectRatioDimensions = [
  AspectRatioDim(ratio: '16:9', width: 1280, height: 720),
  AspectRatioDim(ratio: '9:16', width: 720, height: 1280),
  AspectRatioDim(ratio: '1:1', width: 1024, height: 1024),
  AspectRatioDim(ratio: '4:3', width: 1024, height: 768),
  AspectRatioDim(ratio: '3:4', width: 768, height: 1024),
];

// Video duration -> num_frames mapping
Map<String, int> durationFrameMap = {
  '3': 81,
  '5': 121,
  '10': 241,
  '18': 441,
};

final List<String> durationLabels = ['3', '5', '10', '18'];

// Video mode enum
enum VideoMode { txt2video, img2video, multiImg, keyframes }

// Image mode enum
enum ImageMode { txt2img, img2img }

// Response format enum
enum ResponseFormat { url, b64Json }

// API response models
class ImageApiResponse {
  final List<ImageResult>? data;
  ImageApiResponse({this.data});
  factory ImageApiResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>?;
    return ImageApiResponse(data: list?.map((e) => ImageResult.fromJson(e as Map<String, dynamic>)).toList());
  }
}

class ImageResult {
  final String? url;
  final String? b64Json;
  ImageResult({this.url, this.b64Json});
  factory ImageResult.fromJson(Map<String, dynamic> json) =>
      ImageResult(url: json['url'] as String?, b64Json: json['b64_json'] as String?);
}

class VideoSubmitResponse {
  final String? videoId;
  final String? taskId;
  final String? id;
  VideoSubmitResponse({this.videoId, this.taskId, this.id});
  String? get idValue => videoId ?? taskId ?? id;
  factory VideoSubmitResponse.fromJson(Map<String, dynamic> json) =>
      VideoSubmitResponse(videoId: json['video_id'] as String?, taskId: json['task_id'] as String?, id: json['id'] as String?);
}

class VideoPollResponse {
  final double? progress;
  final String? status;
  final String? videoUrl;
  final String? remixedFromVideoId;
  final String? error;
  final String? prompt;
  VideoPollResponse({this.progress, this.status, this.videoUrl, this.remixedFromVideoId, this.error, this.prompt});
  bool get isCompleted => status == 'completed' || remixedFromVideoId != null;
  bool get isFailed => status == 'failed' || error != null;
  factory VideoPollResponse.fromJson(Map<String, dynamic> json) => VideoPollResponse(
    progress: (json['progress'] as num?)?.toDouble(),
    status: json['status'] as String?,
    videoUrl: json['video_url'] as String?,
    remixedFromVideoId: json['remixed_from_video_id'] as String?,
    error: json['error'] as String?,
    prompt: json['prompt'] as String?,
  );
}

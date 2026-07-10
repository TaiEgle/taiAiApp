import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

/// Video generation API service with async polling
class VideoService {
  final Dio _dio;
  Timer? _pollTimer;
  String? _videoId;

  VideoGenerationState state = VideoGenerationState.initial();

  VideoService(this._dio);

  /// Submit a video generation task
  Future<String> submit({
    required String apiKey,
    required String videoBaseUrl,
    required VideoMode videoMode,
    required String prompt,
    required String aspectRatio,
    required String duration,
    required int frameRate,
    int? seed,
    String? negativePrompt,
    ResponseFormat format = ResponseFormat.url,
    String? singleImagePath,
    String? singleImageUrl,
    List<String>? imagePaths,
  }) async {
    final dims = aspectRatioDimensions.firstWhere(
      (a) => a.ratio == aspectRatio,
      orElse: () => aspectRatioDimensions.first,
    );

    final body = <String, dynamic>{
      'model': 'agnes-video-v2.0',
      'prompt': prompt,
      'extra_body': <String, dynamic>{
        'response_format': format == ResponseFormat.b64Json ? 'b64_json' : 'url',
        'width': dims.width,
        'height': dims.height,
        'num_frames': durationFrameMap[duration] ?? 121,
        'frame_rate': frameRate,
      },
    };

    if (seed != null && seed != -1) {
      body['extra_body']!['seed'] = seed;
    }
    if (negativePrompt != null && negativePrompt.isNotEmpty) {
      body['extra_body']!['negative_prompt'] = negativePrompt;
    }

    if (videoMode == VideoMode.img2video) {
      final img = singleImagePath ?? singleImageUrl;
      if (img != null) body['image'] = img;
    } else if (videoMode == VideoMode.multiImg || videoMode == VideoMode.keyframes) {
      final urls = (imagePaths ?? []).where((p) => p.isNotEmpty).toList();
      if (urls.length >= 2) {
        body['extra_body']!['image'] = urls;
      }
      if (videoMode == VideoMode.keyframes) {
        body['extra_body']!['mode'] = 'keyframes';
      }
    }

    final baseUrl = videoBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final response = await _dio.post(
      '$baseUrl/v1/videos',
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('请求失败 (${response.statusCode})');
    }

    final json = response.data as Map<String, dynamic>;
    final submitResp = VideoSubmitResponse.fromJson(json);
    final id = submitResp.idValue;

    if (id == null) {
      throw Exception('未获取到视频任务 ID，请检查 API 响应');
    }

    _videoId = id;
    return id;
  }

  /// Start polling for video completion
  void startPolling({
    required String apiKey,
    required String videoBaseUrl,
    required VoidCallback onComplete,
    required Function(VideoPollResponse?) onError,
    Duration interval = const Duration(seconds: 5),
  }) {
    state = state.copyWith(isPolling: true, progress: 0, status: '排队中...');

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      if (_videoId == null) return;

      try {
        final baseUrl = videoBaseUrl.replaceAll(RegExp(r'/+$'), '');
        final pollUrl = '$baseUrl/agnesapi?video_id=$_videoId&model_name=agnes-video-v2.0';

        final response = await _dio.get(
          pollUrl,
          options: Options(
            headers: {'Authorization': 'Bearer $apiKey'},
          ),
        );

        if (response.statusCode != 200) {
          if (response.statusCode == 401) {
            onError(null);
            stopPolling();
            return;
          }
          throw Exception('轮询失败 (${response.statusCode})');
        }

        final json = response.data as Map<String, dynamic>;
        final pollResp = VideoPollResponse.fromJson(json);

        // Update progress
        if (pollResp.progress != null) {
          final p = pollResp.progress!;
          state = state.copyWith(progress: p.round().clamp(0, 100));
        }

        // Update status
        if (pollResp.status != null) {
          final statusMap = <String, String>{
            'queued': '排队中...',
            'completed': '已完成！',
            'failed': '生成失败',
          };
          if (pollResp.status == 'in_progress') {
            state = state.copyWith(status: '生成中 ${state.progress}%');
          } else {
            state = state.copyWith(status: statusMap[pollResp.status!] ?? pollResp.status!);
          }
        }

        if (pollResp.isCompleted) {
          stopPolling();
          final finalUrl = pollResp.remixedFromVideoId ?? pollResp.videoUrl ?? '';
          state = state.copyWith(
            isPolling: false,
            videoUrl: finalUrl,
            progress: 100,
            status: '已完成！',
          );
          onComplete.call();
        }

        if (pollResp.isFailed) {
          stopPolling();
          state = state.copyWith(isPolling: false, error: pollResp.error ?? '视频生成失败');
          onError.call(pollResp);
        }
      } catch (e) {
        stopPolling();
        state = state.copyWith(isPolling: false, error: e.toString());
        onError.call(null);
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _videoId = null;
    state = state.copyWith(isPolling: false);
  }

  void reset() {
    stopPolling();
    state = VideoGenerationState.initial();
  }
}

/// Immutable state holder for video generation
class VideoGenerationState {
  final bool isPolling;
  final int progress;
  final String status;
  final String? videoUrl;
  final String? error;

  const VideoGenerationState({
    required this.isPolling,
    required this.progress,
    required this.status,
    this.videoUrl,
    this.error,
  });

  factory VideoGenerationState.initial() => const VideoGenerationState(
        isPolling: false,
        progress: 0,
        status: '',
      );

  VideoGenerationState copyWith({
    bool? isPolling,
    int? progress,
    String? status,
    String? videoUrl,
    String? error,
  }) {
    return VideoGenerationState(
      isPolling: isPolling ?? this.isPolling,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      error: error ?? this.error,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Video result area with polling progress and download
class VideoResultArea extends StatefulWidget {
  final bool polling;
  final double progress;
  final String status;
  final String currentVideoUrl;
  final String error;
  final VoidCallback onStopPolling;

  const VideoResultArea({
    super.key,
    required this.polling,
    required this.progress,
    required this.status,
    required this.currentVideoUrl,
    required this.error,
    required this.onStopPolling,
  });

  @override
  State<VideoResultArea> createState() => _VideoResultAreaState();
}

class _VideoResultAreaState extends State<VideoResultArea> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _spinAnimation;
  int elapsedSeconds = 0;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant VideoResultArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.polling && !oldWidget.polling) {
      elapsedSeconds = 0;
      _startElapsedTimer();
    } else if (!widget.polling && oldWidget.polling) {
      _stopElapsedTimer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopElapsedTimer();
    super.dispose();
  }

  void _startElapsedTimer() {
    _stopElapsedTimer();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsedSeconds++);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1AF56C6C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4DF56C6C)),
        ),
        child: Text('⚠️ ${widget.error}', style: const TextStyle(color: AppTheme.errorColor, fontSize: 14)),
      );
    }

    // Submitting state (no progress yet)
    if (widget.polling && widget.progress <= 0) {
      return _SubmittingState(
        status: widget.status,
        elapsedSeconds: elapsedSeconds,
        onCancel: widget.onStopPolling,
      );
    }

    // Polling with progress
    if (widget.polling && widget.progress > 0 && widget.currentVideoUrl.isEmpty) {
      return _PollingState(progress: widget.progress, status: widget.status);
    }

    // Video result available
    if (widget.currentVideoUrl.isNotEmpty && !widget.polling) {
      return _VideoResult(videoUrl: widget.currentVideoUrl);
    }

    // Empty state
    return _EmptyState();
  }

  void _emitStopPolling(BuildContext context) {
    // Use ScaffoldMessenger to signal parent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('停止轮询'), duration: Duration(milliseconds: 300)),
    );
  }
}

class _SubmittingState extends StatelessWidget {
  final String status;
  final int elapsedSeconds;
  final VoidCallback onCancel;

  const _SubmittingState({
    required this.status,
    required this.elapsedSeconds,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 20),
          Text(
            status,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 8),
          const Text('视频生成通常需要 3-5 分钟，请耐心等待', style: TextStyle(fontSize: 13, color: AppTheme.textColorHint)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x0F667EEA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('⏱️ 已等待 $elapsedSeconds 秒', style: const TextStyle(fontSize: 13, color: AppTheme.textColorSecondary)),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('✕ 取消生成'),
          ),
        ],
      ),
    );
  }
}

class _PollingState extends StatelessWidget {
  final double progress;
  final String status;
  const _PollingState({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 8,
                    backgroundColor: const Color(0x11667EEA),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                  ),
                ),
                Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    background: Paint()
                      ..shader = LinearGradient(colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)])
                          .createShader(const Rect.fromLTWH(0, 0, 100, 30)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(status, style: const TextStyle(fontSize: 15, color: AppTheme.textColorSecondary)),
        ],
      ),
    );
  }
}

class _VideoResult extends StatelessWidget {
  final String videoUrl;
  const _VideoResult({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: AppTheme.glassCardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () => _showFullscreen(context),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayerWidget(url: videoUrl),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x73000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('🔍 点击全屏预览', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _downloadVideo(context),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('📥 下载视频'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _showFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(url: videoUrl, autoplay: true),
        ),
      ),
    );
  }

  void _downloadVideo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('视频保存功能需要添加 file_saver 包')),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool autoplay;
  const VideoPlayerWidget({super.key, required this.url, this.autoplay = false});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    // For H5 / web builds, use a simple placeholder
    // For mobile, use video_player package
    return _error
        ? const Center(child: Icon(Icons.videocam_off, size: 48, color: AppTheme.textColorSubtle))
        : Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder since video_player needs initialization
                const Icon(Icons.videocam, size: 48, color: Colors.white54),
                const Text('视频播放器', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎬', style: TextStyle(fontSize: 64)),
          SizedBox(height: 12),
          Text('你的视频将在这里展示', style: TextStyle(fontSize: 18, color: AppTheme.textColorHint)),
          SizedBox(height: 8),
          Text('输入描述，点击生成开始创作', style: TextStyle(fontSize: 14, color: AppTheme.textColorSubtle)),
        ],
      ),
    );
  }
}

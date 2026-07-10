import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/image_service.dart';
import '../services/video_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

/// Main app page with all generation modes
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Image state
  bool _imgLoading = false;
  String _imgError = '';
  String _imgResult = '';

  // Video state
  bool _videoPolling = false;
  double _videoProgress = 0;
  String _videoStatus = '';
  String _videoCurrentUrl = '';
  String _videoError = '';

  // Elapsed timer for video
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    // Listen for polling stop events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _stopElapsedTimer();
    _stopVideoPolling();
    super.dispose();
  }

  void _startElapsedTimer() {
    _stopElapsedTimer();
    _elapsedSeconds = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  // ==================== Image Generation ====================
  Future<void> _onImageGenerate({
    required String prompt,
    String? imageUrl,
    String? localImagePath,
  }) async {
    setState(() {
      _imgError = '';
      _imgResult = '';
      _imgLoading = true;
    });

    final state = context.read<AppState>();
    if (state.apiKey.trim().isEmpty) {
      setState(() => _imgError = '请先在配置中心（右上角⚙️）填入你的 API Key');
      setState(() => _imgLoading = false);
      return;
    }

    final service = ImageService(context.read<Dio>());

    try {
      final result = await service.generate(
        apiKey: state.apiKey.trim(),
        apiUrl: state.apiUrl,
        prompt: prompt,
        size: state.selectedSize,
        format: state.responseFormat,
        imageMode: state.imageMode,
        localImagePath: localImagePath,
        imageUrl: imageUrl,
      );

      String displaySrc;
      if (state.responseFormat == ResponseFormat.b64Json && result.b64Json != null) {
        displaySrc = 'data:image/png;base64,${result.b64Json}';
      } else if (result.url != null) {
        displaySrc = result.url!;
      } else {
        throw Exception('无法解析图片数据，请检查响应格式');
      }

      if (mounted) {
        setState(() {
          _imgResult = displaySrc;
          _imgLoading = false;
        });

        state.addToHistory(ImageHistoryItem(
          displaySrc: displaySrc,
          prompt: prompt,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片生成成功！'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imgError = e.toString();
          _imgLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_imgError), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  // ==================== Video Generation ====================
  Future<void> _onVideoGenerate({
    required String prompt,
    required String aspectRatio,
    required String duration,
    required int frameRate,
    int? seed,
    String? negativePrompt,
    String? singleImagePath,
    String? singleImageUrl,
    List<String>? imagePaths,
  }) async {
    setState(() {
      _videoError = '';
      _videoCurrentUrl = '';
      _videoProgress = 0;
      _videoStatus = '提交中...';
      _videoPolling = true;
    });

    _startElapsedTimer();

    final state = context.read<AppState>();
    if (state.apiKey.trim().isEmpty) {
      setState(() => _videoError = '请先在配置中心（右上角⚙️）填入你的 API Key');
      setState(() => _videoPolling = false);
      _stopElapsedTimer();
      return;
    }

    final service = VideoService(context.read<Dio>());

    try {
      final videoId = await service.submit(
        apiKey: state.apiKey.trim(),
        videoBaseUrl: state.videoBaseUrl,
        videoMode: state.videoMode,
        prompt: prompt,
        aspectRatio: aspectRatio,
        duration: duration,
        frameRate: frameRate,
        seed: seed,
        negativePrompt: negativePrompt,
        format: state.responseFormat,
        singleImagePath: singleImagePath,
        singleImageUrl: singleImageUrl,
        imagePaths: imagePaths,
      );

      // Start polling
      service.startPolling(
        apiKey: state.apiKey.trim(),
        videoBaseUrl: state.videoBaseUrl,
        onComplete: () {
          if (!mounted) return;
          setState(() {
            _videoPolling = false;
            _videoCurrentUrl = service.state.videoUrl ?? '';
            _videoProgress = 100;
            _videoStatus = '已完成！';
          });
          _stopElapsedTimer();

          if (_videoCurrentUrl.isNotEmpty) {
            final durationLabels = {'3': '~3秒', '5': '~5秒', '10': '~10秒', '18': '~18秒'};
            state.addToVideoHistory(VideoHistoryItem(
              videoUrl: _videoCurrentUrl,
              prompt: prompt,
              durationLabel: durationLabels[duration] ?? '~5秒',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('视频生成成功！'), duration: Duration(seconds: 2)),
            );
          } else {
            setState(() => _videoError = '视频生成完成但未找到视频链接');
          }
        },
        onError: (pollResp) {
          if (!mounted) return;
          setState(() {
            _videoPolling = false;
            _videoError = pollResp?.error ?? '视频生成失败';
            _videoStatus = '轮询失败';
          });
          _stopElapsedTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_videoError), duration: const Duration(seconds: 3)),
          );
        },
      );

      setState(() {
        _videoProgress = service.state.progress.toDouble();
        _videoStatus = service.state.status;
      });
    } catch (e) {
      setState(() {
        _videoError = e.toString();
        _videoPolling = false;
        _videoStatus = '';
      });
      _stopElapsedTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_videoError), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  void _stopVideoPolling() {
    // Reset local state; VideoService instances are ephemeral per call
    // In production, use a singleton VideoService via Provider
    setState(() {
      _videoPolling = false;
    });
    _stopElapsedTimer();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: AppTheme.bgColor,
          ),
          AppTheme.buildBackground(context),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    constraints.maxWidth < 640 ? 32 : 40,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 680),
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(context),
                        const SizedBox(height: 8),

                        // Top-level navigation
                        _buildTopNav(context),
                        const SizedBox(height: 16),

                        // Main content based on mode
                        if (state.appMode == AppMode.image) ...[
                          _buildCard(const ModeBar()),
                          _buildCard(
                            InputArea(onGenerate: _onImageGenerate),
                          ),
                          _buildCard(
                            ResultArea(
                              loading: _imgLoading,
                              error: _imgError,
                              currentResult: _imgResult,
                            ),
                          ),
                          const HistorySection(),
                        ] else ...[
                          _buildCard(const VideoModeBar()),
                          _buildCard(
                            VideoInputArea(onGenerate: _onVideoGenerate),
                          ),
                          _buildCard(
                            VideoResultArea(
                              polling: _videoPolling,
                              progress: _videoProgress,
                              status: _videoStatus,
                              currentVideoUrl: _videoCurrentUrl,
                              error: _videoError,
                              onStopPolling: _stopVideoPolling,
                            ),
                          ),
                          const VideoHistorySection(),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Settings gear button
          Positioned(
            top: 12,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppTheme.textColorSecondary, size: 24),
              onPressed: () => state.toggleConfig(),
            ),
          ),

          // Config panel overlay
          if (state.configVisible) const ConfigPanelOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppTheme.brandIconDecoration,
            child: const Center(
              child: Text(
                '帧',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: '-apple-system, BlinkMacSystemFont, PingFang SC, sans-serif',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF472B6)],
                ).createShader(bounds),
                child: const Text(
                  '帧不错',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                'AI 图像 · 视频生成',
                style: TextStyle(fontSize: 13, color: AppTheme.textColorHint, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    final state = context.read<AppState>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0x99FFFFFF),
            borderRadius: BorderRadius.all(Radius.circular(14)),
            border: Border.all(color: Color(0x66FFFFFF), width: 1),
            boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              _TopNavTab(
                icon: '🖼️',
                label: '图片',
                isActive: state.appMode == AppMode.image,
                onTap: () => state.appMode = AppMode.image,
              ),
              _TopNavTab(
                icon: '🎬',
                label: '视频',
                isActive: state.appMode == AppMode.video,
                onTap: () => state.appMode = AppMode.video,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration,
      child: child,
    );
  }
}

class _TopNavTab extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TopNavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: isActive ? AppTheme.tabActiveDecoration : AppTheme.tabInactiveDecoration,
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

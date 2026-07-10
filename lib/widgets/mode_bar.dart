import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Image mode selector tabs (Text-to-Image / Image-to-Image)
class ModeBar extends StatelessWidget {
  const ModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TabChip(
            label: '文生图',
            isActive: state.imageMode == ImageMode.txt2img,
            onTap: () => state.imageMode = ImageMode.txt2img,
          ),
          const SizedBox(width: 6),
          _TabChip(
            label: '图生图',
            isActive: state.imageMode == ImageMode.img2img,
            onTap: () => state.imageMode = ImageMode.img2img,
          ),
        ],
      ),
    );
  }
}

/// Video mode selector tabs (4 modes)
class VideoModeBar extends StatelessWidget {
  const VideoModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final modes = [
      (label: '文生视频', mode: VideoMode.txt2video),
      (label: '图生视频', mode: VideoMode.img2video),
      (label: '多图视频', mode: VideoMode.multiImg),
      (label: '关键帧', mode: VideoMode.keyframes),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: modes.map((m) {
          return _TabChip(
            label: m.label,
            isActive: state.videoMode == m.mode,
            onTap: () => state.videoMode = m.mode,
          );
        }).toList(),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: isActive
            ? AppTheme.tabActiveDecoration
            : AppTheme.tabInactiveDecoration,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

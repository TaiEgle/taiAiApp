import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Collapsible video history grid
class VideoHistorySection extends StatefulWidget {
  const VideoHistorySection({super.key});

  @override
  State<VideoHistorySection> createState() => _VideoHistorySectionState();
}

class _VideoHistorySectionState extends State<VideoHistorySection> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        ListTile(
          title: const Text(
            '🎬 视频历史',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColorSecondary),
          ),
          trailing: Icon(
            _collapsed ? Icons.chevron_right : Icons.chevron_down,
            color: AppTheme.textColorSecondary,
          ),
          onTap: () => setState(() => _collapsed = !_collapsed),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_collapsed) ...[
          if (state.videoHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('还没有视频生成记录', style: TextStyle(color: AppTheme.textColorSubtle))),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 16 / 9,
              ),
              itemCount: state.videoHistory.length,
              itemBuilder: (context, idx) => _VideoHistoryTile(item: state.videoHistory[idx]),
            ),
        ],
      ],
    );
  }
}

class _VideoHistoryTile extends StatelessWidget {
  final VideoHistoryItem item;
  const _VideoHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _playFullscreen(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: const Color(0xFF1A1A2E),
              child: const Center(child: Icon(Icons.play_circle_outline, size: 32, color: Colors.white54)),
            ),
          ),
          // Play overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x0F667EEA), width: 2),
              ),
            ),
          ),
          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xB2000000)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  Text(
                    item.durationLabel,
                    style: const TextStyle(fontSize: 10, color: Color(0xB3FFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: const Center(child: Text('视频播放', style: TextStyle(color: Colors.white54))),
        ),
      ),
    );
  }
}

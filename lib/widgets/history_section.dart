import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

/// Collapsible image history grid
class HistorySection extends StatefulWidget {
  const HistorySection({super.key});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        ListTile(
          title: const Text(
            '🖼️ 图片历史',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColorSecondary),
          ),
          trailing: Icon(
            _collapsed ? Icons.chevron_right : Icons.keyboard_arrow_down,
            color: AppTheme.textColorSecondary,
          ),
          onTap: () => setState(() => _collapsed = !_collapsed),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_collapsed) ...[
          if (state.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('还没有图片生成记录', style: TextStyle(color: AppTheme.textColorSubtle))),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: state.history.length,
              itemBuilder: (context, idx) => _HistoryTile(
                item: state.history[idx],
                onTap: () => _showFullscreen(context, state.history[idx].displaySrc, state.history[idx].prompt),
              ),
            ),
        ],
      ],
    );
  }

  void _showFullscreen(BuildContext context, String src, String prompt) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: src.startsWith('data:image')
                  ? Image.memory(base64Decode(src.split(',').last), fit: BoxFit.contain)
                  : Image.network(src, fit: BoxFit.contain),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(prompt, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0x80000000), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ImageHistoryItem item;
  final VoidCallback onTap;
  const _HistoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.displaySrc.startsWith('data:image')
                ? Image.memory(base64Decode(item.displaySrc.split(',').last), fit: BoxFit.cover)
                : Image.network(item.displaySrc, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0x44000000)],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(Icons.zoom_in, size: 18, color: Colors.white, shadows: [
              Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
            ]),
          ),
        ],
      ),
    );
  }
}

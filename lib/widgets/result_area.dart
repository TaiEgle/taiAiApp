import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Image result display with fullscreen and download
class ResultArea extends StatelessWidget {
  final bool loading;
  final String error;
  final String currentResult;

  const ResultArea({
    super.key,
    required this.loading,
    required this.error,
    required this.currentResult,
  });

  @override
  Widget build(BuildContext context) {
    if (error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1AF56C6C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4DF56C6C)),
        ),
        child: Text('⚠️ $error', style: const TextStyle(color: AppTheme.errorColor, fontSize: 14)),
      );
    }

    if (loading) {
      return _ImageSpinner();
    }

    if (currentResult.isNotEmpty) {
      return Column(
        children: [
          GestureDetector(
            onTap: () => _showFullscreen(context, currentResult),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(currentResult),
            ),
          ),
          const SizedBox(height: 12),
          const Text('🔍 点击全屏预览', style: TextStyle(fontSize: 12, color: AppTheme.textColorHint)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _downloadImage(context, currentResult),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('保存图片'),
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

    return _EmptyState(icon: '🖼️', text: '你的图片将在这里展示', sub: '输入描述，点击生成开始创作');
  }

  Widget _buildImage(String src) {
    if (src.startsWith('data:image')) {
      return Image.memory(
        base64Decode(src.split(',').last),
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      src,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 64)),
    );
  }

  void _showFullscreen(BuildContext context, String src) {
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

  Future<void> _downloadImage(BuildContext context, String src) async {
    // In production, use share_plus or file_saver package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片保存功能需要添加 share_plus 或 file_saver 包')),
    );
  }
}

class _ImageSpinner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16),
          Text('正在生成图片…', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String icon;
  final String text;
  final String sub;
  const _EmptyState({required this.icon, required this.text, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎨', style: TextStyle(fontSize: 64)),
          SizedBox(height: 12),
          Text('你的图片将在这里展示', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
          SizedBox(height: 8),
          Text('输入描述，点击生成开始创作', style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB))),
        ],
      ),
    );
  }
}

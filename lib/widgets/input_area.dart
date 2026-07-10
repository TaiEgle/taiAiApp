import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Image input area: prompt textarea + image upload (img2img mode)
class InputArea extends StatefulWidget {
  final Function({String prompt, String? imageUrl, String? localImagePath}) onGenerate;
  const InputArea({super.key, required this.onGenerate});

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final _promptController = TextEditingController();
  final _urlController = TextEditingController();
  String? _localImagePath;
  String? _localImageName;
  bool _loading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _canGenerate {
    if (_promptController.text.trim().isEmpty) return false;
    final state = context.read<AppState>();
    if (state.imageMode == ImageMode.img2img &&
        _localImagePath == null &&
        _urlController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _localImagePath = picked.path;
        _localImageName = File(picked.path).path.split('/').last;
        _urlController.clear();
      });
    }
  }

  void _clearImage() {
    setState(() {
      _localImagePath = null;
      _localImageName = null;
      _urlController.clear();
    });
  }

  Future<void> _generate() async {
    if (_loading || !_canGenerate) return;
    setState(() => _loading = true);
    try {
      widget.onGenerate(
        prompt: _promptController.text.trim(),
        imageUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        localImagePath: _localImagePath,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt textarea
        Container(
          decoration: AppTheme.promptInputDecoration,
          child: TextField(
            controller: _promptController,
            maxLines: 6,
            maxLength: 500,
            style: const TextStyle(fontSize: 15, color: AppTheme.textColorPrimary),
            decoration: InputDecoration(
              hintText: '描述你想要的图片… 例如：一只坐在月球上的猫咪，赛博朋克风格',
              hintStyle: const TextStyle(fontSize: 15, color: AppTheme.textColorHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              counterStyle: const TextStyle(color: AppTheme.textColorSubtle),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Image-to-image section
        if (state.imageMode == ImageMode.img2img) ...[
          // URL input
          Container(
            decoration: AppTheme.promptInputDecoration,
            child: TextField(
              controller: _urlController,
              style: const TextStyle(fontSize: 14, color: AppTheme.textColorPrimary),
              decoration: const InputDecoration(
                hintText: '或输入图片公网 URL',
                hintStyle: TextStyle(fontSize: 14, color: AppTheme.textColorHint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Upload area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x4D667EEA), width: 2),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x66FFFFFF),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _localImagePath != null ? '✓ $_localImageName' : '📁 点击上传图片',
                    style: TextStyle(
                      fontSize: 14,
                      color: _localImagePath != null
                          ? AppTheme.successColor
                          : const Color(0xFF888888),
                      fontWeight: _localImagePath != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Preview
          if (_localImagePath != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_localImagePath!),
                    height: 200,
                    fit: BoxFit.contain,
                    color: Colors.transparent,
                    colorBlendMode: BlendMode.normal,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _clearImage,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0x80000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],

        // Generate button
        ElevatedButton(
          onPressed: _loading || !_canGenerate ? null : _generate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _loading
              ? const Text('⏳ 生成中…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
              : const Text('✨ 生成图片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

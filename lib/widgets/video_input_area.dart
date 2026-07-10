import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

typedef VideoGenerateCallback = void Function({
  String prompt,
  String aspectRatio,
  String duration,
  int frameRate,
  int? seed,
  String? negativePrompt,
  String? singleImagePath,
  String? singleImageUrl,
  List<String>? imagePaths,
});

/// Video input area: prompt + advanced options + image upload
class VideoInputArea extends StatefulWidget {
  final VideoGenerateCallback onGenerate;
  const VideoInputArea({super.key, required this.onGenerate});

  @override
  State<VideoInputArea> createState() => _VideoInputAreaState();
}

class _VideoInputAreaState extends State<VideoInputArea> {
  final _promptController = TextEditingController();
  String _selectedAspectRatio = '16:9';
  String _selectedDuration = '5';
  int _frameRate = 24;
  int? _seed;
  final _negativePromptController = TextEditingController();
  String? _singleImagePath;
  String? _singleImageUrl;
  final List<String> _multiImagePaths = [];
  bool _showAdvanced = false;
  bool _loading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  bool get _canGenerate => _promptController.text.trim().isNotEmpty;

  bool get _needsImageInput {
    final state = context.read<AppState>();
    return state.videoMode == VideoMode.img2video ||
        state.videoMode == VideoMode.multiImg ||
        state.videoMode == VideoMode.keyframes;
  }

  bool get _hasEnoughImages {
    if (!_needsImageInput) return true;
    if (_multiImagePaths.length >= 2) return true;
    if (state.imageMode == VideoMode.img2video && _singleImagePath != null) return true;
    return false;
  }

  AppState get state => context.read<AppState>();

  Future<void> _pickSingleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _singleImagePath = picked.path);
    }
  }

  Future<void> _pickMultiImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickImages(source: ImageSource.gallery, maxImages: 5);
    if (picked != null) {
      setState(() {
        _multiImagePaths.clear();
        _multiImagePaths.addAll(picked.map((p) => p.path));
      });
    }
  }

  void _removeMultiImage(int index) {
    setState(() => _multiImagePaths.removeAt(index));
  }

  Future<void> _generate() async {
    if (_loading || !_canGenerate) return;
    setState(() => _loading = true);
    try {
      widget.onGenerate(
        prompt: _promptController.text.trim(),
        aspectRatio: _selectedAspectRatio,
        duration: _selectedDuration,
        frameRate: _frameRate,
        seed: _seed,
        negativePrompt: _negativePromptController.text.trim().isEmpty ? null : _negativePromptController.text.trim(),
        singleImagePath: _singleImagePath,
        singleImageUrl: _singleImageUrl?.isEmpty ? null : _singleImageUrl,
        imagePaths: _multiImagePaths.isNotEmpty ? List.from(_multiImagePaths) : null,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt
        Container(
          decoration: AppTheme.promptInputDecoration,
          child: TextField(
            controller: _promptController,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(fontSize: 15, color: AppTheme.textColorPrimary),
            decoration: const InputDecoration(
              hintText: '描述你想要的视频…',
              hintStyle: TextStyle(fontSize: 15, color: AppTheme.textColorHint),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
              counterStyle: TextStyle(color: AppTheme.textColorSubtle),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Image input for img2video / multi-img / keyframes
        if (_needsImageInput) ...[
          _buildImageInput(),
          const SizedBox(height: 12),
        ],

        // Advanced options toggle
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.textColorSecondary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '高级选项',
                  style: TextStyle(fontSize: 13, color: AppTheme.textColorSecondary),
                ),
              ],
            ),
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 8),
          _buildAdvancedOptions(),
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
              : const Text('✨ 生成视频', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildImageInput() {
    final mode = state.videoMode;
    if (mode == VideoMode.img2video) {
      return Column(
        children: [
          Container(
            decoration: AppTheme.promptInputDecoration,
            child: TextField(
              onChanged: (v) => _singleImageUrl = v,
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
          GestureDetector(
            onTap: _pickSingleImage,
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
                    _singleImagePath != null ? '✓ 已选择图片' : '📁 点击上传图片',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textColorHint),
                  ),
                ],
              ),
            ),
          ),
          if (_singleImagePath != null) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_singleImagePath!), height: 150, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _singleImagePath = null),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: Color(0x80000000), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    } else {
      // multi-img or keyframes
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._multiImagePaths.asMap().entries.map((e) {
                      final idx = e.key;
                      final path = e.value;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeMultiImage(idx),
                              child: Container(
                                decoration: const BoxDecoration(color: Color(0x80000000), shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_multiImagePaths.length < 5)
                      GestureDetector(
                        onTap: _pickMultiImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0x4D667EEA), width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0x66FFFFFF),
                          ),
                          child: const Icon(Icons.add, color: AppTheme.textColorHint),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _multiImagePaths.isEmpty
                ? '点击 + 上传图片（至少2张）'
                : '${_multiImagePaths.length}/5 张图片已选择',
            style: const TextStyle(fontSize: 12, color: AppTheme.textColorHint),
          ),
        ],
      );
    }
  }

  Widget _buildAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x11667EEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Aspect ratio
          _buildDropdown('画面比例', _selectedAspectRatio, [
            '16:9', '9:16', '1:1', '4:3', '3:4',
          ], (v) => _selectedAspectRatio = v!),
          const SizedBox(height: 12),
          // Duration
          _buildDropdown('视频时长', _selectedDuration, durationLabels, (v) => _selectedDuration = v!),
          const SizedBox(height: 12),
          // Frame rate
          _buildDropdown('帧率', _frameRate.toString(), ['24', '30', '60'], (v) => _frameRate = int.parse(v!)),
          const SizedBox(height: 12),
          // Seed
          Row(
            children: [
              const Text('随机种子', style: TextStyle(fontSize: 14, color: AppTheme.textColorSecondary)),
              const Spacer(),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '留空则随机',
                    filled: true,
                    fillColor: Color(0x88FFFFFF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => _seed = v.isEmpty ? null : int.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Negative prompt
          TextField(
            controller: _negativePromptController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '反向提示词（不需要生成的内容）',
              filled: true,
              fillColor: Color(0x88FFFFFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<String>(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textColorSecondary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0x88FFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

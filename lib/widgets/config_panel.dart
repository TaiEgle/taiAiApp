import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Settings overlay panel (glassmorphism)
class ConfigPanelOverlay extends StatelessWidget {
  const ConfigPanelOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return GestureDetector(
      onTap: () => state.configVisible = false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: const Color(0x99000000),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap-through
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 680),
                margin: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassCardDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '⚙️ 配置中心',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textColorPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textColorSecondary),
                          onPressed: () => state.configVisible = false,
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // API URL
                    _ConfigField(
                      label: '图片 API 地址',
                      initialValue: state.apiUrl,
                      onChanged: (v) => state.apiUrl = v,
                      hintText: 'https://apihub.agnes-ai.com/v1/images/generations',
                    ),
                    const SizedBox(height: 16),

                    // Video API Base URL
                    _ConfigField(
                      label: '视频 API 地址',
                      initialValue: state.videoBaseUrl,
                      onChanged: (v) => state.videoBaseUrl = v,
                      hintText: 'https://apihub.agnes-ai.com',
                    ),
                    const SizedBox(height: 16),

                    // API Key
                    _ConfigField(
                      label: 'API Key',
                      initialValue: state.apiKey,
                      onChanged: (v) => state.apiKey = v,
                      hintText: '输入你的 API Key',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // Response Format
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '返回格式',
                            style: TextStyle(fontSize: 14, color: AppTheme.textColorSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              _FormatChip(
                                label: 'URL',
                                isActive: state.responseFormat == ResponseFormat.url,
                                onTap: () => state.responseFormat = ResponseFormat.url,
                              ),
                              const SizedBox(width: 8),
                              _FormatChip(
                                label: 'Base64',
                                isActive: state.responseFormat == ResponseFormat.b64Json,
                                onTap: () => state.responseFormat = ResponseFormat.b64Json,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Image Size
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '图片尺寸',
                            style: TextStyle(fontSize: 14, color: AppTheme.textColorSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x88FFFFFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: state.selectedSize,
                                isExpanded: true,
                                items: imageSizes
                                    .map((s) => DropdownMenuItem(value: s.value, child: Text(s.label)))
                                    .toList(),
                                onChanged: (v) => state.selectedSize = v!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Save button
                    ElevatedButton(
                      onPressed: () {
                        state.configVisible = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('配置已保存'), duration: Duration(seconds: 1)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('保存配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool obscureText;

  const _ConfigField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textColorSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: AppTheme.promptInputDecoration,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14, color: AppTheme.textColorPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textColorHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FormatChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF667EEA) : const Color(0x88FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF667EEA) : const Color(0x33667EEA),
          ),
        ),
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

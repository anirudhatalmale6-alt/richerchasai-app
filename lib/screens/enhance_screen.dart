import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/auphonic_service.dart';

class EnhanceScreen extends StatefulWidget {
  final File recording;
  const EnhanceScreen({super.key, required this.recording});

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  bool _isProcessing = false;
  String _statusText = '';
  double _progress = 0;
  bool _denoise = true;
  bool _levelAdjust = true;
  String _outputFormat = 'wav';
  File? _enhancedFile;

  Future<void> _enhance() async {
    setState(() { _isProcessing = true; _progress = 0; _statusText = 'Starting...'; });

    try {
      final jwtToken = await AuphonicService.getOrCreateToken();
      final service = AuphonicService(jwtToken);
      final dir = await getApplicationDocumentsDirectory();
      final ext = _outputFormat == 'mp3' ? 'mp3' : 'wav';
      final originalName = widget.recording.path.split('/').last.split('.').first;
      final savePath = '${dir.path}/recordings/${originalName}_enhanced.$ext';

      final result = await service.enhanceRecording(
        filePath: widget.recording.path,
        savePath: savePath,
        outputFormat: _outputFormat,
        onProgress: (status, progress) {
          if (mounted) setState(() { _statusText = status; _progress = progress; });
        },
      );

      setState(() {
        _enhancedFile = result['file'] as File;
        _isProcessing = false;
        _statusText = 'Enhancement complete!';
        _progress = 1.0;
      });
    } catch (e) {
      debugPrint('Auphonic enhance error: $e');
      if (mounted) {
        setState(() { _isProcessing = false; _statusText = 'Error: $e'; _progress = 0; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enhancement failed: $e', maxLines: 3),
            backgroundColor: AppColors.recording,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.recording.path.split('/').last;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: const Text('AI Studio Enhance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.audio_file_rounded, color: AppColors.violet, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_formatSize(widget.recording.lengthSync()), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings
            const Text('Enhancement Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
            const SizedBox(height: 16),

            _settingToggle('AI Noise Reduction', 'Remove background hiss, hums, and clicks', _denoise, (v) => setState(() => _denoise = v)),
            _settingToggle('Loudness Leveling', 'Normalize to -16 LUFS broadcast standard', _levelAdjust, (v) => setState(() => _levelAdjust = v)),

            const SizedBox(height: 16),

            // Output format
            const Text('Output Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                _formatOption('WAV', 'wav', 'Lossless'),
                const SizedBox(width: 12),
                _formatOption('MP3', 'mp3', '320kbps'),
              ],
            ),

            const Spacer(),

            // Progress
            if (_isProcessing || _progress > 0) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(_progress >= 1.0 ? AppColors.mint : AppColors.violet),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(_statusText, style: const TextStyle(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],

            // Enhance button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _enhance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: AppColors.violet.withValues(alpha: 0.3),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : (_enhancedFile != null ? 'Enhance Again' : 'Enhance with AI'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),

            if (_enhancedFile != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mint.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enhanced file saved: ${_enhancedFile!.path.split('/').last}',
                        style: const TextStyle(fontSize: 13, color: AppColors.mint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _settingToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.violet,
          ),
        ],
      ),
    );
  }

  Widget _formatOption(String label, String fmt, String desc) {
    final selected = _outputFormat == fmt;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _outputFormat = fmt),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.violet.withValues(alpha: 0.12) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.violet.withValues(alpha: 0.4) : AppColors.border),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? AppColors.violet : AppColors.textMain)),
              Text(desc, style: TextStyle(fontSize: 11, color: selected ? AppColors.violetLight : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

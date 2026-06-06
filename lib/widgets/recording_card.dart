import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

class RecordingCard extends StatelessWidget {
  final File file;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback? onEnhance;
  final Function(String newPath)? onRenamed;

  const RecordingCard({
    super.key,
    required this.file,
    required this.isPlaying,
    required this.onPlay,
    required this.onDelete,
    this.onEnhance,
    this.onRenamed,
  });

  @override
  Widget build(BuildContext context) {
    final stat = file.statSync();
    final name = file.path.split('/').last;
    final ext = name.split('.').last.toUpperCase();
    final size = _formatSize(stat.size);
    final date = DateFormat('MMM d, yyyy  h:mm a').format(stat.modified);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPlaying ? AppColors.violet.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying ? AppColors.violet : AppColors.violet.withValues(alpha: 0.12),
              ),
              child: Icon(
                isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : AppColors.violet,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info (tap name to rename)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _renameFile(context),
                  child: Row(
                    children: [
                      Flexible(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _tag(ext, ext == 'WAV' ? AppColors.mint : AppColors.violetLight),
                    const SizedBox(width: 8),
                    Text('$size  ·  $date', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          // Save to Downloads
          GestureDetector(
            onTap: () => _saveToDownloads(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.save_alt_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),

          // Share
          GestureDetector(
            onTap: () => Share.shareXFiles([XFile(file.path)], text: 'Recorded with RiCherChasAI'),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.share_rounded, color: AppColors.mint, size: 20),
            ),
          ),

          // Enhance
          if (onEnhance != null)
            GestureDetector(
              onTap: onEnhance,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.violet, size: 20),
              ),
            ),

          // Delete
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
    );
  }

  void _renameFile(BuildContext context) {
    final currentName = file.path.split('/').last;
    final nameWithoutExt = currentName.contains('.') ? currentName.substring(0, currentName.lastIndexOf('.')) : currentName;
    final ext = currentName.contains('.') ? currentName.substring(currentName.lastIndexOf('.')) : '';
    final controller = TextEditingController(text: nameWithoutExt);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Recording', style: TextStyle(color: AppColors.textMain)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textMain),
          decoration: InputDecoration(
            suffixText: ext,
            suffixStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.violet)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != nameWithoutExt) {
                final dir = file.parent.path;
                final newPath = '$dir/$newName$ext';
                try {
                  await file.rename(newPath);
                  onRenamed?.call(newPath);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Rename failed: $e'), backgroundColor: AppColors.recording));
                  }
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename', style: TextStyle(color: AppColors.violet)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDownloads(BuildContext context) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final iosDocsDir = await getApplicationDocumentsDirectory();
      final targetDir = Platform.isAndroid ? downloadsDir : iosDocsDir;
      final fileName = file.path.split('/').last;
      final targetPath = '${targetDir.path}/$fileName';
      await file.copy(targetPath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${Platform.isAndroid ? "Downloads" : "Files"}: $fileName'), backgroundColor: AppColors.mint),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.recording),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Recording?', style: TextStyle(color: AppColors.textMain)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () { Navigator.pop(ctx); onDelete(); }, child: const Text('Delete', style: TextStyle(color: AppColors.recording))),
        ],
      ),
    );
  }
}

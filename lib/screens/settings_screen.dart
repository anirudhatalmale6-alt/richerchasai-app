import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Subscription status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.violet.withValues(alpha: 0.15), AppColors.mint.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.workspace_premium_rounded, color: AppColors.violet, size: 40),
                SizedBox(height: 12),
                Text('Studio Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.violet)),
                SizedBox(height: 4),
                Text('Cloud AI enhancement active', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cloud AI info
          const Text('Cloud AI Enhancement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                    SizedBox(width: 8),
                    Text('Dereverberation', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                    SizedBox(width: 8),
                    Text('AI Noise Reduction', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                    SizedBox(width: 8),
                    Text('Loudness Normalization (-16 LUFS)', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                    SizedBox(width: 8),
                    Text('Voice AutoEQ', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                  ],
                ),
                SizedBox(height: 12),
                Text('All processing happens securely in the cloud. Your recordings are encrypted during transfer and deleted after processing.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // About
          const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 12),
          _aboutItem('Version', '1.3.0'),
          _aboutItem('Developer', 'mediaXtreme LLC'),
          _aboutItem('Contact', 'legal@richerchasai.com'),
        ],
      ),
    );
  }

  Widget _aboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

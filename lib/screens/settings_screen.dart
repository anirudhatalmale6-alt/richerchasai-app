import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenController = TextEditingController();
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _tokenController.text = prefs.getString('auphonic_token') ?? '';
    setState(() => _isPro = prefs.getBool('is_pro') ?? false);
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auphonic_token', _tokenController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API token saved'), backgroundColor: AppColors.mint),
      );
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

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
                colors: _isPro
                    ? [AppColors.violet.withValues(alpha: 0.15), AppColors.mint.withValues(alpha: 0.08)]
                    : [AppColors.bgCard, AppColors.bgCard],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isPro ? AppColors.violet.withValues(alpha: 0.3) : AppColors.border),
            ),
            child: Column(
              children: [
                Icon(_isPro ? Icons.workspace_premium_rounded : Icons.mic_rounded,
                    color: _isPro ? AppColors.violet : AppColors.textMuted, size: 40),
                const SizedBox(height: 12),
                Text(_isPro ? 'Studio Pro' : 'Basic Audio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _isPro ? AppColors.violet : AppColors.textMain)),
                const SizedBox(height: 4),
                Text(_isPro ? 'Cloud AI enhancement active' : 'Free local processing',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // API Token
          const Text('Cloud AI Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 8),
          const Text('Enter your Auphonic API token to enable cloud-based audio enhancement.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),

          TextField(
            controller: _tokenController,
            style: const TextStyle(color: AppColors.textMain, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Paste Auphonic API token',
              hintStyle: const TextStyle(color: AppColors.bgSurface),
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.violet)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Token', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),

          const SizedBox(height: 32),

          // About
          const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 12),
          _aboutItem('Version', '1.0.0'),
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

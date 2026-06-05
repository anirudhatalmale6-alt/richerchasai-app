import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_theme.dart';
import '../services/recording_service.dart';
import '../widgets/waveform_painter.dart';
import '../widgets/recording_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final RecordingService _recordingService = RecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  List<FileSystemEntity> _recordings = [];
  late AnimationController _pulseController;
  RecordingFormat _format = RecordingFormat.wav;
  String? _playingPath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadRecordings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recordingService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final recordings = await _recordingService.getRecordings();
    setState(() => _recordings = recordings);
  }

  void _startTimer() {
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _elapsed = _recordingService.elapsed);
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      if (_isPaused) {
        await _recordingService.resumeRecording();
        setState(() => _isPaused = false);
      } else {
        await _recordingService.stopRecording();
        _timer?.cancel();
        setState(() { _isRecording = false; _isPaused = false; });
        await _loadRecordings();
      }
    } else {
      final hasPermission = await _recordingService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required'), backgroundColor: AppColors.recording),
          );
        }
        return;
      }
      await _recordingService.startRecording(format: _format);
      _startTimer();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _recordingService.pauseRecording();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _playRecording(String path) async {
    if (_playingPath == path) {
      await _audioPlayer.stop();
      setState(() => _playingPath = null);
      return;
    }
    await _audioPlayer.setFilePath(path);
    setState(() => _playingPath = path);
    _audioPlayer.play();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingPath = null);
      }
    });
  }

  Future<void> _deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    await _loadRecordings();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$mins:$secs.$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textMain),
                      children: [
                        const TextSpan(text: 'RiCherChas'),
                        TextSpan(text: 'AI', style: TextStyle(color: AppColors.violet)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _formatToggle(),
                ],
              ),
            ),

            // Recording area
            Expanded(
              flex: 3,
              child: _buildRecordingArea(),
            ),

            // Recordings list
            Expanded(
              flex: 4,
              child: _buildRecordingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatBtn('WAV', RecordingFormat.wav),
          _formatBtn('MP3', RecordingFormat.mp3),
        ],
      ),
    );
  }

  Widget _formatBtn(String label, RecordingFormat fmt) {
    final selected = _format == fmt;
    return GestureDetector(
      onTap: _isRecording ? null : () => setState(() => _format = fmt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.violet.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? AppColors.violet : AppColors.textMuted,
        )),
      ),
    );
  }

  Widget _buildRecordingArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform visualization
        SizedBox(
          height: 80,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => CustomPaint(
              size: Size(MediaQuery.of(context).size.width - 40, 80),
              painter: WaveformPainter(
                isRecording: _isRecording,
                progress: _pulseController.value,
                color: _isRecording ? AppColors.recording : AppColors.violet,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Timer
        Text(
          _formatDuration(_elapsed),
          style: TextStyle(
            fontSize: 44, fontWeight: FontWeight.w300, letterSpacing: 2,
            color: _isRecording ? AppColors.recording : AppColors.textMain,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          _isRecording ? (_isPaused ? 'PAUSED' : 'RECORDING') : 'READY',
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3,
            color: _isRecording ? AppColors.recording : AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 32),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording) ...[
              _controlBtn(Icons.pause, 'Pause', _pauseRecording, AppColors.textMuted),
              const SizedBox(width: 32),
            ],
            _recordButton(),
          ],
        ),
      ],
    );
  }

  Widget _recordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isRecording ? 1.0 + _pulseController.value * 0.08 : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? AppColors.recording : AppColors.violet,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppColors.recording : AppColors.violet).withValues(alpha: 0.4),
                    blurRadius: _isRecording ? 30 : 20,
                    spreadRadius: _isRecording ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white, size: 36,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _controlBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecordingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('Recordings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              const Spacer(),
              Text('${_recordings.length}', style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _recordings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none_rounded, size: 48, color: AppColors.bgSurface),
                      SizedBox(height: 12),
                      Text('No recordings yet', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      Text('Tap the mic to start', style: TextStyle(color: AppColors.bgSurface, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final file = _recordings[index];
                    final isPlaying = _playingPath == file.path;
                    return RecordingCard(
                      file: file as File,
                      isPlaying: isPlaying,
                      onPlay: () => _playRecording(file.path),
                      onDelete: () => _deleteRecording(file.path),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

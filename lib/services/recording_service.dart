import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

enum RecordingFormat { wav, mp3 }

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;
  DateTime? _startTime;
  final _uuid = const Uuid();

  bool get isRecording => _isRecording;
  String? get currentPath => _currentPath;
  Duration get elapsed => _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> startRecording({RecordingFormat format = RecordingFormat.wav}) async {
    if (_isRecording) return _currentPath!;

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) await recordingsDir.create(recursive: true);

    final ext = format == RecordingFormat.wav ? 'wav' : 'm4a';
    final encoder = format == RecordingFormat.wav ? AudioEncoder.wav : AudioEncoder.aacLc;
    final filename = 'recording_${_uuid.v4().substring(0, 8)}.$ext';
    _currentPath = '${recordingsDir.path}/$filename';

    await _recorder.start(
      RecordConfig(encoder: encoder, sampleRate: 44100, bitRate: 128000),
      path: _currentPath!,
    );
    _isRecording = true;
    _startTime = DateTime.now();
    return _currentPath!;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    _startTime = null;
    return path;
  }

  Future<void> pauseRecording() async {
    if (_isRecording) await _recorder.pause();
  }

  Future<void> resumeRecording() async {
    if (_isRecording) await _recorder.resume();
  }

  Future<List<FileSystemEntity>> getRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) return [];
    return recordingsDir.listSync()..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  }

  void dispose() {
    _recorder.dispose();
  }
}

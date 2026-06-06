import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuphonicService {
  static const _baseUrl = 'https://auphonic.com/api';
  static const defaultToken = 'MBxX4YegpbqGPO8uM0vdnEIBKqKJHZ58';
  final String _apiToken;

  AuphonicService(this._apiToken);

  Future<Map<String, dynamic>> _createProduction({
    String title = 'RiCherChasAI Recording',
    String outputFormat = 'wav',
  }) async {
    final uri = Uri.parse('$_baseUrl/productions.json');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'metadata': {'title': title},
        'output_files': [
          {
            'format': outputFormat == 'mp3' ? 'mp3' : 'wav',
            'bitrate': '320',
          }
        ],
        'algorithms': {
          'denoise': true,
          'hipfilter': true,
          'leveler': true,
          'loudnesstarget': -16.0,
          'normloudness': true,
        },
      }),
    );
    debugPrint('Auphonic create production: ${response.statusCode}');
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _uploadFile(String uuid, String filePath) async {
    final uri = Uri.parse('$_baseUrl/production/$uuid/upload.json');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiToken'
      ..files.add(await http.MultipartFile.fromPath('input_file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    debugPrint('Auphonic upload: ${response.statusCode}');
    return json.decode(body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _startProduction(String uuid) async {
    final uri = Uri.parse('$_baseUrl/production/$uuid/start.json');
    final response = await http.post(uri, headers: {'Authorization': 'Bearer $_apiToken'});
    debugPrint('Auphonic start: ${response.statusCode}');
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _getStatus(String uuid) async {
    final uri = Uri.parse('$_baseUrl/production/$uuid.json');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiToken'});
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<File> _downloadResult(String url, String savePath) async {
    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $_apiToken'});
    final file = File(savePath);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<Map<String, dynamic>> enhanceRecording({
    required String filePath,
    required String savePath,
    String outputFormat = 'wav',
    Function(String status, double progress)? onProgress,
  }) async {
    onProgress?.call('Creating production...', 0.05);

    final production = await _createProduction(outputFormat: outputFormat);
    final uuid = production['data']?['uuid'] as String?;
    if (uuid == null) {
      throw Exception('Failed to create production: ${production['error_message'] ?? json.encode(production)}');
    }
    debugPrint('Production created: $uuid');

    onProgress?.call('Uploading audio...', 0.1);
    final uploadResult = await _uploadFile(uuid, filePath);
    if (uploadResult['status_code'] != 200) {
      throw Exception('Upload failed: ${uploadResult['error_message'] ?? json.encode(uploadResult)}');
    }

    onProgress?.call('Starting processing...', 0.25);
    await _startProduction(uuid);

    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final status = await _getStatus(uuid);
      final statusCode = status['data']?['status'] as int? ?? 0;
      final statusString = status['data']?['status_string'] as String? ?? 'Processing';

      final progress = 0.25 + (i / 120) * 0.6;
      onProgress?.call(statusString, progress);
      debugPrint('Auphonic status: $statusCode - $statusString');

      // 3 = Done
      if (statusCode == 3) {
        final outputFiles = status['data']?['output_files'] as List?;
        if (outputFiles == null || outputFiles.isEmpty) {
          throw Exception('No output files in completed production');
        }
        final outputUrl = outputFiles[0]['download_url'] as String?;
        if (outputUrl == null) throw Exception('No download URL');

        onProgress?.call('Downloading enhanced audio...', 0.9);
        final result = await _downloadResult(outputUrl, savePath);
        onProgress?.call('Complete!', 1.0);
        return {'file': result, 'status': status['data']};
      }

      // >= 10 = Error states
      if (statusCode >= 10) {
        throw Exception('Processing failed: $statusString (code: $statusCode)');
      }
    }

    throw Exception('Processing timed out after 6 minutes');
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuphonicService {
  static const _gatewayUrl = 'https://api.richerchasai.com';

  final String _jwtToken;

  AuphonicService(this._jwtToken);

  static Future<String> getOrCreateToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('gateway_token');
    if (token != null && token.isNotEmpty) return token;

    final deviceId = prefs.getString('device_id') ?? DateTime.now().millisecondsSinceEpoch.toString();
    prefs.setString('device_id', deviceId);

    final response = await http.post(
      Uri.parse('$_gatewayUrl/api/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': deviceId, 'isPro': true}),
    );
    if (response.statusCode == 200) {
      token = json.decode(response.body)['token'] as String;
      await prefs.setString('gateway_token', token);
      return token;
    }
    throw Exception('Failed to get auth token');
  }

  Future<Map<String, dynamic>> enhanceRecording({
    required String filePath,
    required String savePath,
    String outputFormat = 'wav',
    Function(String status, double progress)? onProgress,
  }) async {
    onProgress?.call('Uploading to cloud...', 0.1);

    final request = http.MultipartRequest('POST', Uri.parse('$_gatewayUrl/api/enhance'))
      ..headers['Authorization'] = 'Bearer $_jwtToken'
      ..fields['format'] = outputFormat
      ..files.add(await http.MultipartFile.fromPath('audio', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Enhancement failed');
    }

    final productionId = data['production_id'] as String;
    debugPrint('Production started: $productionId');

    onProgress?.call('Processing with AI...', 0.3);

    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 3));

      final statusRes = await http.get(
        Uri.parse('$_gatewayUrl/api/enhance/$productionId/status'),
        headers: {'Authorization': 'Bearer $_jwtToken'},
      );
      final statusData = json.decode(statusRes.body) as Map<String, dynamic>;
      final statusString = statusData['status_string'] as String? ?? 'Processing';
      final complete = statusData['complete'] as bool? ?? false;

      final progress = 0.3 + (i / 120) * 0.5;
      onProgress?.call(statusString, progress);

      if (complete) {
        onProgress?.call('Downloading enhanced audio...', 0.9);

        final downloadRes = await http.get(
          Uri.parse('$_gatewayUrl/api/enhance/$productionId/download'),
          headers: {'Authorization': 'Bearer $_jwtToken'},
        );

        if (downloadRes.statusCode == 200) {
          final file = File(savePath);
          await file.writeAsBytes(downloadRes.bodyBytes);
          onProgress?.call('Complete!', 1.0);
          return {'file': file};
        }
        throw Exception('Download failed');
      }

      if (statusData['error'] != null) {
        throw Exception('Processing failed: ${statusData['error']}');
      }
    }

    throw Exception('Processing timed out');
  }
}

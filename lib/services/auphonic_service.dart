import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuphonicService {
  static const _baseUrl = 'https://auphonic.com/api';
  static const defaultToken = 'MBxX4YegpbqGPO8uM0vdnEIBKqKJHZ58';
  final String _apiToken;

  AuphonicService(this._apiToken);

  Future<Map<String, dynamic>> createProduction({
    required String filePath,
    String title = 'RiCherChasAI Recording',
    String outputFormat = 'wav',
    bool denoise = true,
    bool levelAdjust = true,
    double targetLoudness = -16.0,
  }) async {
    final uri = Uri.parse('$_baseUrl/productions.json');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiToken'
      ..fields['metadata[title]'] = title
      ..fields['output_files[0][format]'] = outputFormat == 'mp3' ? 'mp3' : 'wav'
      ..fields['output_files[0][bitrate]'] = '320'
      ..fields['algorithms[denoise]'] = denoise ? 'true' : 'false'
      ..fields['algorithms[hipfilter]'] = 'true'
      ..fields['algorithms[leveler]'] = levelAdjust ? 'true' : 'false'
      ..fields['algorithms[loudnesstarget]'] = targetLoudness.toString()
      ..fields['algorithms[normloudness]'] = 'true'
      ..files.add(await http.MultipartFile.fromPath('input_file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return json.decode(body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startProduction(String uuid) async {
    final uri = Uri.parse('$_baseUrl/production/$uuid/start.json');
    final response = await http.post(uri, headers: {'Authorization': 'Bearer $_apiToken'});
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductionStatus(String uuid) async {
    final uri = Uri.parse('$_baseUrl/production/$uuid.json');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiToken'});
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<File> downloadResult(String url, String savePath) async {
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
    onProgress?.call('Uploading...', 0.1);

    final production = await createProduction(
      filePath: filePath,
      outputFormat: outputFormat,
    );

    final uuid = production['data']?['uuid'] as String?;
    if (uuid == null) throw Exception('Failed to create production: ${production['error_message'] ?? 'Unknown error'}');

    onProgress?.call('Processing...', 0.3);

    await startProduction(uuid);

    // Poll for completion
    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final status = await getProductionStatus(uuid);
      final statusCode = status['data']?['status'] as int? ?? 0;
      final statusString = status['data']?['status_string'] as String? ?? '';

      final progress = 0.3 + (i / 120) * 0.5;
      onProgress?.call(statusString, progress);

      if (statusCode == 3) {
        // Done
        final outputUrl = status['data']?['output_files']?[0]?['download_url'] as String?;
        if (outputUrl == null) throw Exception('No output file URL');

        onProgress?.call('Downloading...', 0.9);
        final result = await downloadResult(outputUrl, savePath);
        onProgress?.call('Complete', 1.0);
        return {'file': result, 'status': status['data']};
      }

      if (statusCode >= 10) {
        throw Exception('Processing failed: $statusString');
      }
    }

    throw Exception('Processing timed out');
  }
}

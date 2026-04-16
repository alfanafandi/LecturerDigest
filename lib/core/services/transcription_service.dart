import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranscriptionService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';

  Future<String> transcribe(String filePath) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) throw Exception('GROQ_API_KEY not found in .env');

    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-large-v3-turbo'
      ..fields['response_format'] = 'json'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['text'] ?? '';
    } else {
      throw Exception('Failed to transcribe: $responseBody');
    }
  }
}

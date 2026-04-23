import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  Future<String> generateSummary(String rawTranscript) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://lecturedigest.app',
        'X-Title': 'LectureDigest',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "max_tokens": 1000,
        "messages": [
          {
            "role": "system",
            "content": "You are a highly analytical academic synthesis tool. Extract the core essence (1 sentence), 3-5 key takeaways, and 1 exam tip from the provided lecture transcript. Format the response in Indonesian. Format the response ONLY in valid JSON."
          },
          {
            "role": "user",
            "content": "Transcript: $rawTranscript\n\nReturn JSON strictly matching this schema: { \"core_essence\": \"String\", \"key_takeaways\": [{\"title\": \"String\", \"description\": \"String\"}], \"exam_tip\": \"String\" }"
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate summary: ${response.body}');
    }
  }

  Future<String> generateFlashcards(String summaryJson) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "max_tokens": 1000,
        "messages": [
          {
            "role": "system",
            "content": "You are a flashcard creator. Generate exactly 5 flashcards based on the lecture summary. Format the response in Indonesian. Format ONLY in valid JSON array."
          },
          {
            "role": "user",
            "content": "Summary data: $summaryJson\n\nReturn strictly a JSON array matching: [{\"front_concept\": \"String\", \"back_detail\": \"String\"}]"
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate flashcards: ${response.body}');
    }
  }

  Future<String> askAIChat(String transcript, String question, List<Map<String, String>> history) async {
    // Map internal roles to OpenAI roles and limit history to last 10 messages
    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    
    final List<Map<String, String>> messages = [
      {
        "role": "system",
        "content": "You are DigestBot, an academic assistant. Answer questions based ONLY on the provided lecture transcript. Answer in Indonesian. If the answer is not in the transcript, say you don't know but try to be helpful. Keep responses concise and academic."
      },
      {
        "role": "user",
        "content": "Transcript context: $transcript"
      },
      ...recentHistory.map((m) => {
        "role": m['role'] == 'bot' ? 'assistant' : 'user',
        "content": m['content'] ?? m['text'] ?? '',
      }).toList(),
      {
        "role": "user",
        "content": question
      }
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "max_tokens": 800,
        "messages": messages,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to chat: ${response.body}');
    }
  }

  Future<String> generateQuizzes(String summaryJson) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "max_tokens": 1500,
        "messages": [
          {
            "role": "system",
            "content": "You are a quiz creator. Generate exactly 5 multiple choice questions based on the lecture summary. Format the response in Indonesian. Return ONLY a valid JSON array."
          },
          {
            "role": "user",
            "content": "Summary data: $summaryJson\n\nReturn strictly a JSON array matching: [{\"question\": \"String\", \"options\": [\"Option A\", \"Option B\", \"Option C\", \"Option D\"], \"correct_answer\": \"String matching exactly one of the options\", \"explanation\": \"String\"}]"
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate quizzes: ${response.body}');
    }
  }
}

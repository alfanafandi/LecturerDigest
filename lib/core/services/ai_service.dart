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
    
    final isRemedial = transcript.contains("REMEDIAL LESSON GUIDANCE INSTRUCTION:");
    final systemPrompt = isRemedial
        ? "You are DigestBot, an academic assistant helping the user with a remedial lesson. "
          "You are provided with the remedial context, including their quiz performance and weaknesses, under 'REMEDIAL LESSON GUIDANCE INSTRUCTION'. "
          "Use the provided remedial instructions and the lecture transcript to explain the concepts they struggled with, clarify their mistakes, and guide them. "
          "Answer in Indonesian. Address the user directly using the pronoun 'Anda' (never 'siswa', 'mahasiswa', or third person). Keep responses encouraging, helpful, and clear."
        : "You are DigestBot, an academic assistant. Answer questions based ONLY on the provided lecture transcript. "
          "Answer in Indonesian. If the answer is not in the transcript, say you don't know but try to be helpful. Keep responses concise and academic.";

    final List<Map<String, String>> messages = [
      {
        "role": "system",
        "content": systemPrompt
      },
      {
        "role": "user",
        "content": "Transcript context: $transcript"
      },
      ...recentHistory.map((m) => {
        "role": m['role'] == 'bot' ? 'assistant' : 'user',
        "content": m['content'] ?? m['text'] ?? '',
      }),
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

  Future<String> generateQuizzes(String summaryJson, {int count = 5}) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "max_tokens": 2000,
        "messages": [
          {
            "role": "system",
            "content": "You are a quiz creator. Generate exactly $count multiple choice questions based on the lecture summary. Format the response in Indonesian. Return ONLY a valid JSON array."
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

  Future<String> generateDiagnostics(String lectureTitle, List<Map<String, dynamic>> detailedAnswers) async {
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
            "content": "You are an academic learning diagnostician. Analyze the student's quiz performance for a lecture. Provide a summary of their understanding, identify specific concepts or weaknesses they struggled with (if any), and provide actionable recommendations. Format the response in Indonesian. Address the user directly using the pronoun 'Anda' (e.g. 'Anda memiliki...', 'Anda masih kesulitan...'). Do NOT use third-person terms like 'Siswa ini', 'Mahasiswa', or 'Siswa tersebut' to refer to the user. Return ONLY a valid JSON object."
          },
          {
            "role": "user",
            "content": "Lecture: $lectureTitle\nQuiz Performance Details (Answers): ${jsonEncode(detailedAnswers)}\n\nReturn strictly a JSON object matching this schema: { \"summary\": \"Brief overview of understanding\", \"weaknesses\": [\"specific concept they got wrong, explain briefly\"], \"recommendations\": [\"specific action plan to study\"] }"
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate learning diagnostics: ${response.body}');
    }
  }
}


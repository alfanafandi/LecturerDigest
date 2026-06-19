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
        "model": "google/gemma-4-31b-it:free",
        "max_tokens": 2000,
        "messages": [
          {
            "role": "system",
            "content": "You are a highly analytical academic synthesis tool. Analyze the provided lecture transcript and extract a comprehensive, rich, and highly detailed academic summary in Indonesian. Provide multiple detailed points for each section (aim for 5 to 8 items per array for a long lecture transcript). Format the response in Indonesian. Format the response ONLY in valid JSON."
          },
          {
            "role": "user",
            "content": "Transcript: $rawTranscript\n\nReturn JSON strictly matching this schema:\n{\n  \"core_essence\": \"1-sentence summary of the main lecture objective\",\n  \"key_takeaways\": [\n    {\"title\": \"Takeaway Title 1\", \"description\": \"Detailed takeaway description 1\"},\n    {\"title\": \"Takeaway Title 2\", \"description\": \"Detailed takeaway description 2\"},\n    {\"title\": \"Takeaway Title 3\", \"description\": \"Detailed takeaway description 3\"},\n    {\"title\": \"Takeaway Title 4\", \"description\": \"Detailed takeaway description 4\"},\n    {\"title\": \"Takeaway Title 5\", \"description\": \"Detailed takeaway description 5\"}\n  ],\n  \"outline\": [\n    {\"section_title\": \"Section/Chapter Title 1\", \"section_summary\": \"Detailed summary of this section (2-3 sentences explaining the concepts in depth)\"},\n    {\"section_title\": \"Section/Chapter Title 2\", \"section_summary\": \"Detailed summary of this section (2-3 sentences explaining the concepts in depth)\"},\n    {\"section_title\": \"Section/Chapter Title 3\", \"section_summary\": \"Detailed summary of this section (2-3 sentences explaining the concepts in depth)\"},\n    {\"section_title\": \"Section/Chapter Title 4\", \"section_summary\": \"Detailed summary of this section (2-3 sentences explaining the concepts in depth)\"},\n    {\"section_title\": \"Section/Chapter Title 5\", \"section_summary\": \"Detailed summary of this section (2-3 sentences explaining the concepts in depth)\"}\n  ],\n  \"glossary\": [\n    {\"term\": \"Academic term 1\", \"definition\": \"Clear definition of the term based on the context\"},\n    {\"term\": \"Academic term 2\", \"definition\": \"Clear definition of the term based on the context\"},\n    {\"term\": \"Academic term 3\", \"definition\": \"Clear definition of the term based on the context\"},\n    {\"term\": \"Academic term 4\", \"definition\": \"Clear definition of the term based on the context\"},\n    {\"term\": \"Academic term 5\", \"definition\": \"Clear definition of the term based on the context\"}\n  ],\n  \"study_questions\": [\n    \"Review or critical-thinking question 1\",\n    \"Review or critical-thinking question 2\",\n    \"Review or critical-thinking question 3\",\n    \"Review or critical-thinking question 4\",\n    \"Review or critical-thinking question 5\"\n  ],\n  \"exam_tip\": \"Actionable exam tips related to this topic\"\n}\n\nIMPORTANT: For a long transcript, you MUST extract and write at least 5 to 8 detailed items for key_takeaways, outline, glossary, and study_questions so that the study material is comprehensive and rich. Do NOT generate only 1 or 2 items."
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
        "model": "google/gemma-4-31b-it:free",
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
        "model": "google/gemma-4-31b-it:free",
        "max_tokens": 1000,
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
        "model": "google/gemma-4-31b-it:free",
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
        "model": "google/gemma-4-31b-it:free",
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


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lecturer_digest/core/services/supabase_service.dart';
import 'package:lecturer_digest/core/services/ai_service.dart';
import 'package:lecturer_digest/core/services/audio_service.dart';
import 'package:lecturer_digest/core/services/transcription_service.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final AIService _ai = AIService();
  final AudioService _audio = AudioService();
  final TranscriptionService _transcriber = TranscriptionService();

  // State
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> lectures = [];
  Map<String, dynamic>? currentSummary;
  Map<String, dynamic>? currentLectureDetails;
  List<Map<String, dynamic>> dueFlashcards = [];
  List<Map<String, dynamic>> currentFlashcards = [];
  List<Map<String, dynamic>> currentQuizzes = [];
  Map<String, dynamic>? latestQuizAttempt;
  
  // Chat State
  List<Map<String, dynamic>> chatMessages = [];
  Map<String, dynamic>? chatLecture;
  
  // Stats State
  Map<String, double> courseStats = {};
  
  bool isLoading = false;
  String? error;
  
  // Recording State
  String? currentRecordingPath;
  bool isRecording = false;

  AppProvider() {
    // Initial fetch
    _initData();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> _initData() async {
    _setLoading(true);
    await fetchCourses();
    await fetchAllLectures();
    await fetchDueFlashcards();
    _setLoading(false);
  }

  // --- Courses ---
  Future<void> fetchCourses() async {
    try {
      courses = await _db.getCourses();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  Future<void> addCourse(String name, String schedule, String colorHex) async {
    _setLoading(true);
    try {
      await _db.addCourse(name, schedule, colorHex);
      await fetchCourses();
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> createDummyCourse() async {
    await addCourse('Informatics', 'Monday 10:00 AM', '#006b5c');
  }

  // --- Lectures ---
  Future<void> fetchLectures(String courseId) async {
    _setLoading(true);
    try {
      lectures = await _db.getLectures(courseId);
      await fetchAverageScoreForCourse(courseId);
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAllLectures() async {
    try {
      lectures = await _db.getAllLectures();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  Future<void> fetchSummary(String lectureId) async {
    _setLoading(true);
    try {
      currentSummary = await _db.getSummary(lectureId);
      currentLectureDetails = await _db.getLectureDetails(lectureId);
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchFlashcards(String lectureId) async {
    _setLoading(true);
    try {
      currentFlashcards = await _db.getFlashcards(lectureId);
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchQuizzes(String lectureId) async {
    _setLoading(true);
    try {
      currentQuizzes = await _db.getQuizzes(lectureId);
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAverageScoreForCourse(String courseId) async {
    try {
      final avg = await _db.getAverageQuizScoreForCourse(courseId);
      courseStats[courseId] = avg;
      notifyListeners();
    } catch (e) {
      print('DEBUG: AppProvider error fetching stats: $e');
    }
  }

  Future<void> submitQuizResult(String lectureId, int score, int total, List<Map<String, dynamic>> answers) async {
    try {
      await _db.saveQuizAttempt(lectureId, score, total, answers);
      
      // Ensure we have the course ID to update stats
      String? courseId = currentLectureDetails?['course_id'];
      
      if (courseId == null) {
        // Fallback: Fetch lecture details if they aren't in memory
        final details = await _db.getLectureDetails(lectureId);
        courseId = details['course_id'];
      }

      if (courseId != null) {
        await fetchAverageScoreForCourse(courseId);
      }
    } catch (e) {
      error = "Gagal menyimpan hasil kuis: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> fetchDueFlashcards() async {
    try {
      dueFlashcards = await _db.getFlashcardsDue();
    } catch (e) {
      error = e.toString();
    }
  }

  // --- AI Chat ---
  Future<void> setChatLecture(String lectureId) async {
    // Prevent duplicate context settings if it's already the same lecture
    if (chatLecture != null && chatLecture!['id'] == lectureId) return;

    _setLoading(true);
    chatMessages = []; // Reset on new lecture context
    try {
      chatLecture = await _db.getLectureDetails(lectureId);
      // Initial greeting from bot
      chatMessages.add({
        'role': 'bot',
        'text': "Halo! Saya adalah DigestBot. Ada yang ingin ditanyakan terkait materi perkuliahan ini?",
      });
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> fetchLatestQuizAttempt(String lectureId) async {
    _setLoading(true);
    try {
      latestQuizAttempt = await _db.getLatestQuizAttempt(lectureId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> sendChatMessage(String text) async {
    if (chatLecture == null) return;
    
    chatMessages.add({'role': 'user', 'text': text});
    notifyListeners();

    try {
      final transcript = chatLecture!['raw_transcript'] ?? '';
      final response = await _ai.askAIChat(transcript, text);
      chatMessages.add({'role': 'bot', 'text': response});
    } catch (e) {
      chatMessages.add({'role': 'bot', 'text': "Maaf, saya sedang mengalami kendala koneksi."});
    }
    notifyListeners();
  }

  // --- Recording Logic ---
  Future<void> startRecording() async {
    try {
      currentRecordingPath = await _audio.getTempPath();
      await _audio.startRecording(currentRecordingPath!);
      isRecording = true;
      notifyListeners();
    } catch (e) {
      error = "Gagal memulai rekaman: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audio.stopRecording();
      isRecording = false;
      notifyListeners();
      return path;
    } catch (e) {
      error = "Gagal menghentikan rekaman: ${e.toString()}";
      notifyListeners();
      return null;
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _audio.pauseRecording();
      notifyListeners();
    } catch (e) {
      error = "Gagal menjeda rekaman: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _audio.resumeRecording();
      notifyListeners();
    } catch (e) {
      error = "Gagal melanjutkan rekaman: ${e.toString()}";
      notifyListeners();
    }
  }

  // --- AI Synthesis Workflow ---
  Future<void> processLectureRecording(String courseId, String title, String audioPath, int durationMinutes) async {
    _setLoading(true);
    error = null;
    try {
      // 1. Transcribe real audio first
      final transcript = await _transcriber.transcribe(audioPath);
      if (transcript.isEmpty) throw Exception("Transkrip kosong. Pastikan suara terdengar jelas.");

      // 2. Save Lecture (with audio path for playback)
      final lectureId = await _db.saveLecture(courseId, title, durationMinutes, transcript, audioPath: audioPath);

      // 3. Generate Summary via AI
      final summaryRaw = await _ai.generateSummary(transcript);
      final summaryData = jsonDecode(summaryRaw);

      // 4. Save Summary
      await _db.saveSummary(
        lectureId,
        summaryData['core_essence'],
        {'takeaways': summaryData['key_takeaways']},
        summaryData['exam_tip'],
      );

      // 5. Generate Flashcards via AI
      final flashcardsRaw = await _ai.generateFlashcards(summaryRaw);
      final List<dynamic> flashcardsData = jsonDecode(flashcardsRaw);

      // 6. Save Flashcards
      await _db.saveFlashcards(
        lectureId,
        flashcardsData.map((f) => {
          'front_concept': f['front_concept'],
          'back_detail': f['back_detail'],
        }).toList().cast<Map<String, dynamic>>(),
      );

      // Finish
      await fetchCourses(); 
      await fetchDueFlashcards();
    } catch (e) {
      error = "Gagal memproses AI: ${e.toString()}";
      print(error);
    }
    _setLoading(false);
  }

  // --- Quiz Generation Logic (Manual Trigger) ---
  Future<void> generateQuizForLecture(String lectureId) async {
    _setLoading(true);
    error = null;
    try {
      // 1. Get Summary context (cheaper/faster than regenerating)
      final summaryData = await _db.getSummary(lectureId);
      String contextText = "";
      
      if (summaryData != null) {
        contextText = jsonEncode(summaryData);
      } else {
        final lecture = await _db.getLectureDetails(lectureId);
        contextText = lecture['raw_transcript'] ?? '';
      }
      
      if (contextText.isEmpty) throw Exception("Tidak ada materi untuk membuat kuis.");

      // 2. Generate via AI
      final quizRaw = await _ai.generateQuizzes(contextText);
      final List<dynamic> quizData = jsonDecode(quizRaw);

      // 2. Save to DB
      await _db.saveQuizzes(
        lectureId,
        quizData.map((q) => {
          'question': q['question'],
          'options': q['options'],
          'correct_answer': q['correct_answer'],
          'explanation': q['explanation'],
        }).toList().cast<Map<String, dynamic>>(),
      );

      // 3. Refresh
      await fetchQuizzes(lectureId);
    } catch (e) {
      error = "Gagal membuat kuis AI: ${e.toString()}";
      print(error);
    }
    _setLoading(false);
  }
}

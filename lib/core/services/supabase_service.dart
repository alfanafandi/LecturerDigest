import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Courses ---
  Future<List<Map<String, dynamic>>> getCourses() async {
    return await _client.from('courses').select().order('created_at');
  }

  Future<void> addCourse(String name, String schedule, String colorHex) async {
    await _client.from('courses').insert({
      'name': name,
      'schedule': schedule,
      'color_hex': colorHex,
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<List<Map<String, dynamic>>> getLectures(String courseId) async {
    return await _client.from('lectures').select().eq('course_id', courseId).order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAllLectures() async {
    return await _client.from('lectures').select().order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> getLectureDetails(String lectureId) async {
    return await _client.from('lectures').select('*, courses(name)').eq('id', lectureId).single();
  }

  Future<String> saveLecture(String courseId, String title, int duration, String transcript, {String? audioPath}) async {
    final response = await _client.from('lectures').insert({
      'course_id': courseId,
      'title': title,
      'lecture_date': DateTime.now().toIso8601String().split('T')[0],
      'duration_minutes': duration,
      'raw_transcript': transcript,
      'status': 'Summarized',
      'user_id': _client.auth.currentUser?.id,
      if (audioPath != null) 'audio_url': audioPath,
    }).select('id').single();
    
    return response['id'];
  }

  // --- Summaries ---
  Future<void> saveSummary(String lectureId, String coreEssence, Map<String, dynamic> keyTakeaways, String examTips) async {
    await _client.from('summaries').insert({
      'lecture_id': lectureId,
      'core_essence': coreEssence,
      'key_takeaways': keyTakeaways,
      'exam_tips': examTips,
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<Map<String, dynamic>?> getSummary(String lectureId) async {
    return await _client.from('summaries').select().eq('lecture_id', lectureId).maybeSingle();
  }

  // --- Flashcards ---
  Future<void> saveFlashcards(String lectureId, List<Map<String, dynamic>> flashcards) async {
    final inserts = flashcards.map((f) => {
      'lecture_id': lectureId,
      'front_concept': f['front_concept'],
      'back_detail': f['back_detail'],
      'user_id': _client.auth.currentUser?.id,
    }).toList();
    
    await _client.from('flashcards').insert(inserts);
  }

  Future<List<Map<String, dynamic>>> getFlashcards(String lectureId) async {
    return await _client.from('flashcards').select().eq('lecture_id', lectureId);
  }

  Future<List<Map<String, dynamic>>> getFlashcardsDue() async {
    // For MVP, just get all learning flashcards
    return await _client.from('flashcards').select().eq('status', 'Learning');
  }

  Future<void> saveQuizzes(String lectureId, List<Map<String, dynamic>> quizzes) async {
    final inserts = quizzes.map((q) => {
      'lecture_id': lectureId,
      'question': q['question'],
      'options': q['options'],
      'correct_answer': q['correct_answer'],
      'explanation': q['explanation'],
      'user_id': _client.auth.currentUser?.id,
    }).toList();
    
    await _client.from('quizzes').insert(inserts);
  }

  Future<List<Map<String, dynamic>>> getQuizzes(String lectureId) async {
    return await _client.from('quizzes').select().eq('lecture_id', lectureId);
  }

  // --- Quiz Attempts & Stats ---
  Future<void> saveQuizAttempt(String lectureId, int score, int totalQuestions, List<Map<String, dynamic>> detailedAnswers) async {
    try {
      print('DEBUG: Mencoba menyimpan percobaan kuis. LectureID: $lectureId, Score: $score');
      await _client.from('quiz_attempts').insert({
        'lecture_id': lectureId,
        'score': score,
        'total_questions': totalQuestions,
        'detailed_answers': detailedAnswers,
        'user_id': _client.auth.currentUser?.id,
      });
      print('DEBUG: Berhasil menyimpan percobaan kuis.');
    } catch (e) {
      print('DEBUG: ERROR saat menyimpan kuis: $e');
    }
  }

  Future<double> getAverageQuizScoreForCourse(String courseId) async {
    try {
      print('DEBUG: Mengambil skor rata-rata untuk CourseID: $courseId');
      
      // Step 1: Get all lecture IDs for this course
      final lecturesResponse = await _client
          .from('lectures')
          .select('id')
          .eq('course_id', courseId);
      
      final lectureIds = (lecturesResponse as List).map((l) => l['id'] as String).toList();
      print('DEBUG: Ditemukan ${lectureIds.length} materi untuk kursus ini.');
      
      if (lectureIds.isEmpty) return 0.0;

      // Step 2: Get all quiz attempts for ini
      print('DEBUG: Mencari percobaan kuis untuk ${lectureIds.length} materi...');
      final attemptsResponse = await _client
          .from('quiz_attempts')
          .select('lecture_id, score, total_questions, created_at')
          .filter('lecture_id', 'in', lectureIds)
          .order('created_at', ascending: false);
      
      final List results = attemptsResponse as List;
      print('DEBUG: Ditemukan total ${results.length} percobaan kuis.');
      
      if (results.isEmpty) return 0.0;

      // Step 3: Filter only the LATEST attempt for each unique lecture_id
      final Map<String, Map<String, dynamic>> latestAttempts = {};
      for (var attempt in results) {
        String lectureId = attempt['lecture_id'];
        // Since we ordered by created_at DESC, the first one we find is the latest
        if (!latestAttempts.containsKey(lectureId)) {
          latestAttempts[lectureId] = attempt;
        }
      }

      print('DEBUG: Menggunakan ${latestAttempts.length} nilai kuis terbaru.');

      double totalPercentage = 0;
      latestAttempts.forEach((id, attempt) {
        int score = attempt['score'] ?? 0;
        int total = attempt['total_questions'] ?? 1;
        totalPercentage += (score / total) * 100;
      });
      
      double finalAvg = totalPercentage / latestAttempts.length;
      print('DEBUG: Rata-rata akhir (hanya sesi terakhir): $finalAvg%');
      return finalAvg;
    } catch (e) {
      print('DEBUG: Error calculating avg score: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>?> getLatestQuizAttempt(String lectureId) async {
    try {
      final response = await _client
          .from('quiz_attempts')
          .select()
          .eq('lecture_id', lectureId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
      return response;
    } catch (e) {
      print('DEBUG: Error fetching latest quiz attempt: $e');
      return null;
    }
  }

  // --- Chat Messages ---
  Future<void> saveChatMessage(String lectureId, String role, String content) async {
    await _client.from('chat_messages').insert({
      'lecture_id': lectureId,
      'role': role,
      'content': content,
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String lectureId) async {
    return await _client
        .from('chat_messages')
        .select()
        .eq('lecture_id', lectureId)
        .order('created_at', ascending: true);
  }

  // --- Profile ---
  Future<Map<String, dynamic>> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final profile = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    
    if (profile == null) {
      // Create profile if it doesn't exist
      final newProfile = {
        'id': userId,
        'full_name': _client.auth.currentUser?.email?.split('@')[0] ?? 'User',
      };
      await _client.from('profiles').insert(newProfile);
      return newProfile;
    }
    
    return profile;
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl, Map<String, dynamic>? preferences}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    await _client.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (preferences != null) 'preferences': preferences,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}

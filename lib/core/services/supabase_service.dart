import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Courses ---
  Future<List<Map<String, dynamic>>> getCourses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return await _client.from('courses').select().eq('user_id', userId).order('created_at');
  }

  Future<void> addCourse(String name, String schedule, String colorHex) async {
    await _client.from('courses').insert({
      'name': name,
      'schedule': schedule,
      'color_hex': colorHex,
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<void> deleteCourse(String id) async {
    await _client.from('courses').delete().eq('id', id);
  }

  // --- Lectures ---
  Future<void> deleteLecture(String id) async {
    await _client.from('lectures').delete().eq('id', id);
  }

  Future<void> updateLectureTitle(String id, String newTitle) async {
    await _client.from('lectures').update({'title': newTitle}).eq('id', id);
  }

  Future<void> updateCourseName(String id, String newName) async {
    await _client.from('courses').update({'name': newName}).eq('id', id);
  }
  Future<List<Map<String, dynamic>>> getLectures(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return await _client.from('lectures').select().eq('course_id', courseId).eq('user_id', userId).order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAllLectures() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return await _client.from('lectures').select('*, courses(name)').eq('user_id', userId).order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>?> getLectureDetails(String id) async {
    return await _client.from('lectures').select('*, courses(name)').eq('id', id).maybeSingle();
  }

  Future<String> saveLecture(String courseId, String title, int duration, String transcript, {String? audioPath}) async {
    // Generate a unique share code immediately
    final shareCode = _generateUniqueCode(title);
    
    final response = await _client.from('lectures').insert({
      'course_id': courseId,
      'title': title,
      'lecture_date': DateTime.now().toIso8601String().split('T')[0],
      'duration_minutes': duration,
      'raw_transcript': transcript,
      'status': 'Summarized',
      'user_id': _client.auth.currentUser?.id,
      'share_code': shareCode,
      if (audioPath != null) 'audio_url': audioPath,
    }).select('id').single();
    
    return response['id'];
  }

  String _generateUniqueCode(String title) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 11);
    final prefix = title.length >= 2 ? title.substring(0, 2).toUpperCase() : 'LD';
    return 'LD-$timestamp$prefix';
  }

  Future<String?> getOrCreateShareCode(String lectureId) async {
    final res = await _client.from('lectures').select('share_code, title').eq('id', lectureId).single();
    if (res['share_code'] != null) return res['share_code'];

    // Generate and update if null (for old data)
    final code = _generateUniqueCode(res['title'] ?? 'Materi');
    await _client.from('lectures').update({'share_code': code}).eq('id', lectureId);
    return code;
  }

  // --- Summaries ---
  Future<void> saveSummary(String lectureId, String coreEssence, Map<String, dynamic> keyTakeaways, String examTips) async {
    await _client.from('summaries').upsert({
      'lecture_id': lectureId,
      'core_essence': coreEssence,
      'key_takeaways': keyTakeaways,
      'exam_tips': examTips,
    }, onConflict: 'lecture_id');
  }

  Future<Map<String, dynamic>?> getSummary(String lectureId) async {
    return await _client.from('summaries').select().eq('lecture_id', lectureId).maybeSingle();
  }

  // --- Flashcards ---
  Future<void> saveFlashcards(String lectureId, List<Map<String, dynamic>> flashcards) async {
    final data = flashcards.map((f) => {
      'lecture_id': lectureId,
      'front_concept': f['front_concept'] ?? f['concept'], // Support both for safety
      'back_detail': f['back_detail'] ?? f['detail'],
      'status': 'Learning',
    }).toList();
    await _client.from('flashcards').insert(data);
  }

  Future<List<Map<String, dynamic>>> getFlashcards(String lectureId) async {
    return await _client.from('flashcards').select().eq('lecture_id', lectureId);
  }

  Future<List<Map<String, dynamic>>> getFlashcardsDue() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final now = DateTime.now().toUtc().toIso8601String();
    return await _client
        .from('flashcards')
        .select()
        .eq('user_id', userId)
        .lte('next_review_at', now);
  }

  Future<void> updateFlashcardSRS(String id, int intervalDays, String status) async {
    final nextReview = DateTime.now().add(Duration(days: intervalDays)).toUtc().toIso8601String();
    await _client.from('flashcards').update({
      'status': status,
      'review_interval': intervalDays,
      'next_review_at': nextReview,
    }).eq('id', id);
  }

  // --- Quizzes ---
  Future<void> saveQuizzes(String lectureId, List<Map<String, dynamic>> quizzes) async {
    final data = quizzes.map((q) => {
      'lecture_id': lectureId,
      'question': q['question'],
      'options': q['options'],
      'correct_answer': q['correct_answer'],
      'explanation': q['explanation'],
    }).toList();
    await _client.from('quizzes').insert(data);
  }

  Future<List<Map<String, dynamic>>> getQuizzes(String lectureId) async {
    return await _client.from('quizzes').select().eq('lecture_id', lectureId);
  }

  // --- Sharing & Importing ---
  Future<Map<String, dynamic>?> getFullLectureByCode(String code) async {
    // Robust code matching: remove spaces, trim, and uppercase
    final cleanCode = code.replaceAll(' ', '').trim().toUpperCase();
    final lecture = await _client.from('lectures').select('*, courses(name)').eq('share_code', cleanCode).maybeSingle();
    if (lecture == null) return null;

    final lectureId = lecture['id'];
    final summary = await getSummary(lectureId);
    final flashcards = await getFlashcards(lectureId);
    final quizzes = await getQuizzes(lectureId);

    return {
      'lecture': lecture,
      'summary': summary,
      'flashcards': flashcards,
      'quizzes': quizzes,
    };
  }

  Future<void> importLecture(String targetCourseId, Map<String, dynamic> data) async {
    final lecture = data['lecture'];
    
    final newLectureId = await saveLecture(
      targetCourseId, 
      "[SHARED] ${lecture['title']}", 
      lecture['duration_minutes'] ?? 0, 
      lecture['raw_transcript'] ?? '',
      audioPath: lecture['audio_url'],
    );

    final summary = data['summary'];
    if (summary != null) {
      await saveSummary(newLectureId, summary['core_essence'], summary['key_takeaways'], summary['exam_tips']);
    }

    final List flashcards = data['flashcards'] ?? [];
    if (flashcards.isNotEmpty) {
      await saveFlashcards(newLectureId, List<Map<String, dynamic>>.from(flashcards));
    }

    final List quizzes = data['quizzes'] ?? [];
    if (quizzes.isNotEmpty) {
      await saveQuizzes(newLectureId, List<Map<String, dynamic>>.from(quizzes));
    }
  }

  // --- Quiz Attempts & Stats ---
  Future<void> saveQuizAttempt(String lectureId, int score, int totalQuestions, List<Map<String, dynamic>> detailedAnswers) async {
    try {
      await _client.from('quiz_attempts').insert({
        'lecture_id': lectureId,
        'user_id': _client.auth.currentUser?.id,
        'score': score,
        'total_questions': totalQuestions,
        'detailed_answers': detailedAnswers,
      });
    } catch (e) {
      print('Error saving quiz attempt: $e');
    }
  }

  Future<Map<String, dynamic>?> getLatestQuizAttempt(String lectureId) async {
    try {
      return await _client
          .from('quiz_attempts')
          .select()
          .eq('lecture_id', lectureId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      print('Error fetching latest quiz attempt: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllQuizAttempts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      return await _client
          .from('quiz_attempts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (e) {
      print('Error fetching all quiz attempts: $e');
      return [];
    }
  }


  Future<double> getAverageQuizScoreForCourse(String courseId) async {
    try {
      final lecturesRes = await _client.from('lectures').select('id').eq('course_id', courseId);
      final List<String> lectureIds = List<String>.from(lecturesRes.map((l) => l['id']));
      
      if (lectureIds.isEmpty) return 0.0;

      final attempts = await _client
          .from('quiz_attempts')
          .select('score')
          .inFilter('lecture_id', lectureIds);
      
      if (attempts.isEmpty) return 0.0;

      double total = 0;
      for (var a in attempts) {
        total += (a['score'] ?? 0).toDouble();
      }
      return total / attempts.length;
    } catch (e) {
      print('Error fetching quiz stats: $e');
      return 0.0;
    }
  }

  // --- Chat ---
  Future<List<Map<String, dynamic>>> getChatMessages(String contextId) async {
    return await _client.from('chat_messages').select().eq('lecture_id', contextId).order('created_at', ascending: true);
  }

  Future<void> saveChatMessage(String contextId, String role, String content) async {
    await _client.from('chat_messages').insert({
      'lecture_id': contextId,
      'role': role,
      'content': content,
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<List<Map<String, dynamic>>> getRecentChatSessions() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final res = await _client
          .from('chat_messages')
          .select('lecture_id, created_at, lectures(title, course_id, courses(name))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> sessions = [];
      final Set<String> seenLectures = {};

      for (var item in res) {
        final lectureId = item['lecture_id'] as String?;
        if (lectureId != null && !seenLectures.contains(lectureId)) {
          seenLectures.add(lectureId);
          final lectureData = item['lectures'] as Map<String, dynamic>?;
          if (lectureData != null) {
            final courseData = lectureData['courses'] as Map<String, dynamic>?;
            sessions.add({
              'lecture_id': lectureId,
              'title': lectureData['title'] ?? 'Tanpa Judul',
              'course_name': courseData != null ? courseData['name'] : 'Mata Kuliah',
              'last_active': item['created_at'],
            });
          }
        }
      }
      return sessions;
    } catch (e) {
      print('Error fetching recent chat sessions: $e');
      return [];
    }
  }

  // --- User Profile ---
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await _client.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl, Map<String, dynamic>? preferences}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').upsert({
      'id': user.id,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (preferences != null) 'preferences': preferences,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

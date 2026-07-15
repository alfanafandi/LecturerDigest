import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lecturer_digest/core/services/supabase_service.dart';
import 'package:lecturer_digest/core/services/auth_service.dart';
import 'package:lecturer_digest/core/services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lecturer_digest/core/services/audio_service.dart';
import 'package:lecturer_digest/core/services/transcription_service.dart';
import 'package:lecturer_digest/core/services/document_service.dart';
import 'package:lecturer_digest/core/services/pdf_service.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final AuthService _auth = AuthService();
  final AIService _ai = AIService();
  final AudioService _audio = AudioService();
  final TranscriptionService _transcriber = TranscriptionService();
  final DocumentService _docService = DocumentService();

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
  Map<String, dynamic>? chatCourse;
  List<Map<String, dynamic>> recentChatSessions = [];
  bool isRecentChatsLoading = false;
  
  // Stats State
  Map<String, double> courseStats = {};

  // Diagnostics State
  Map<String, Map<String, dynamic>> lectureDiagnostics = {};
  bool isDiagnosticsLoading = false;
  List<Map<String, dynamic>> allQuizAttempts = [];
  String? activeRemedialPrompt;
  
  bool isLoading = false;
  String? error;
  
  // Navigation State
  int currentTabIndex = 0;
  
  // Recording State
  String? currentRecordingPath;
  bool isRecording = false;

  // Theme & Profile State
  ThemeMode _themeMode = ThemeMode.light;
  Map<String, dynamic>? userProfile;
  
  ThemeMode get themeMode => _themeMode;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  AppProvider() {
    _loadTheme();
    // Listen for auth changes
    _auth.authStateChanges.listen((data) {
      if (data.session != null) {
        _initData();
      } else {
        _clearData();
      }
    });

    // Check initial session
    if (_auth.currentUser != null) {
      _initData();
    }
  }

  Future<void> _loadTheme() async {
    // We could use shared_preferences here, but for now we'll default to light
    // In a real app, you'd initialize SharedPreferences in main and pass it here
    // or use a service.
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    
    // Save to preferences in DB
    final prefs = Map<String, dynamic>.from(userProfile?['preferences'] ?? {});
    prefs['theme'] = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _db.updateProfile(preferences: prefs);
  }

  Future<void> fetchProfile() async {
    try {
      userProfile = await _db.getProfile();
      
      // Auto-sync Google/Social OAuth Profile if not initialized or has defaults
      final user = currentUser;
      if (user != null && user.userMetadata != null && user.userMetadata!.isNotEmpty) {
        final oauthName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
        final oauthAvatar = user.userMetadata?['avatar_url'];
        
        bool needsUpdate = false;
        String? updateName;
        String? updateAvatar;

        if (userProfile == null) {
          needsUpdate = true;
          updateName = oauthName;
          updateAvatar = oauthAvatar;
        } else {
          final currentName = userProfile!['full_name'];
          final currentAvatar = userProfile!['avatar_url'];
          
          if (currentName == null || currentName.isEmpty || currentName == 'Mahasiswa' || currentName == 'Mahasiswa Baru') {
            needsUpdate = true;
            updateName = oauthName;
          }
          if (currentAvatar == null || currentAvatar.isEmpty) {
            needsUpdate = true;
            updateAvatar = oauthAvatar;
          }
        }

        if (needsUpdate) {
          await _db.updateProfile(
            fullName: updateName,
            avatarUrl: updateAvatar,
          );
          // Fetch updated profile
          userProfile = await _db.getProfile();
        }
      }
      
      // Sync theme from profile preferences
      if (userProfile?['preferences'] != null) {
        final theme = userProfile!['preferences']['theme'];
        if (theme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (theme == 'light') {
          _themeMode = ThemeMode.light;
        }
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error fetching profile: $e');
    }
  }

  Future<void> updateUserProfile({String? name, String? avatarUrl}) async {
    _setLoading(true);
    try {
      await _db.updateProfile(fullName: name, avatarUrl: avatarUrl);
      await fetchProfile();
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentTabIndex = 0;
    _clearData();
  }

  Future<void> changePassword(String newPassword) async {
    _setLoading(true);
    try {
      await _auth.updatePassword(newPassword);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _clearData() {
    courses = [];
    lectures = [];
    currentSummary = null;
    dueFlashcards = [];
    userProfile = null;
    lectureDiagnostics = {};
    allQuizAttempts = [];
    activeRemedialPrompt = null;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> _initData() async {
    _setLoading(true);
    await fetchProfile();
    await fetchCourses();
    await fetchAllLectures();
    await fetchDueFlashcards();
    await fetchAllQuizAttempts();
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

  Future<void> deleteCourse(String courseId) async {
    _setLoading(true);
    try {
      await _db.deleteCourse(courseId);
      await fetchCourses();
      await fetchAllLectures();
      await fetchDueFlashcards();
      error = null;
    } catch (e) {
      error = "Gagal menghapus kelas: ${e.toString()}";
    }
    _setLoading(false);
  }

  Future<void> updateCourseName(String courseId, String newName) async {
    try {
      await _db.updateCourseName(courseId, newName);
      
      // Update local state directly
      int index = courses.indexWhere((c) => c['id'] == courseId);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(courses[index]);
        updated['name'] = newName;
        courses[index] = updated;
      }
      
      // Also update any lecture objects that might have courses(name) joined
      for (int i = 0; i < lectures.length; i++) {
        if (lectures[i]['course_id'] == courseId && lectures[i].containsKey('courses')) {
          final updatedLec = Map<String, dynamic>.from(lectures[i]);
          final updatedCourse = Map<String, dynamic>.from(updatedLec['courses']);
          updatedCourse['name'] = newName;
          updatedLec['courses'] = updatedCourse;
          lectures[i] = updatedLec;
        }
      }

      notifyListeners();
      error = null;
    } catch (e) {
      error = "Gagal memperbarui nama kelas: ${e.toString()}";
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signIn(email, password);
      error = null;
    } catch (e) {
      error = _mapAuthError(e);
    }
    _setLoading(false);
  }

  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      await _auth.signInWithGoogle();
      error = null;
    } catch (e) {
      error = _mapAuthError(e);
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    _setLoading(true);
    await _auth.signOut();
    _setLoading(false);
  }

  Future<void> signup(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signUp(email, password);
      error = null;
    } catch (e) {
      error = _mapAuthError(e);
    }
    _setLoading(false);
  }

  String _mapAuthError(dynamic e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid_credentials':
          return "Email atau kata sandi salah. Silakan cek kembali.";
        case 'validation_failed':
          return "Format email tidak valid.";
        case 'user_not_found':
          return "Akun tidak ditemukan. Silakan daftar terlebih dahulu.";
        case 'email_not_confirmed':
          return "Email belum dikonfirmasi. Silakan cek inbox Anda.";
        case 'too_many_requests':
          return "Terlalu banyak percobaan. Tunggu sebentar dan coba lagi.";
        case 'network_error':
          return "Koneksi internet bermasalah. Periksa koneksi Anda.";
        default:
          if (e.message.contains('invalid email')) return "Format email tidak valid.";
          return "Terjadi kesalahan: ${e.message}";
      }
    }
    return "Terjadi kendala teknis. Silakan coba lagi nanti.";
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

  Future<List<Map<String, dynamic>>> getLecturesForCourse(String courseId) async {
    try {
      return await _db.getLectures(courseId);
    } catch (e) {
      print('DEBUG: Error getting lectures: $e');
      return [];
    }
  }

  Future<void> fetchAllLectures() async {
    try {
      lectures = await _db.getAllLectures();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    _setLoading(true);
    try {
      await _db.deleteLecture(lectureId);
      await fetchAllLectures();
      await fetchDueFlashcards();
      error = null;
    } catch (e) {
      error = "Gagal menghapus materi: ${e.toString()}";
    }
    _setLoading(false);
  }

  Future<void> updateLectureTitle(String lectureId, String newTitle) async {
    try {
      await _db.updateLectureTitle(lectureId, newTitle);
      
      // Update local state directly
      int index = lectures.indexWhere((l) => l['id'] == lectureId);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(lectures[index]);
        updated['title'] = newTitle;
        lectures[index] = updated;
      }
      
      notifyListeners();
      error = null;
    } catch (e) {
      error = "Gagal memperbarui judul materi: ${e.toString()}";
    }
  }

  Future<void> fetchSummary(String lectureId) async {
    _setLoading(true);
    try {
      final summary = await _db.getSummary(lectureId);
      currentSummary = _sanitizeSummaryData(summary);
      currentLectureDetails = await _db.getLectureDetails(lectureId);
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Map<String, dynamic>? _sanitizeSummaryData(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    // Deep copy/clone to prevent modifying read-only database structures
    final sanitized = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    
    if (sanitized['core_essence'] is String) {
      sanitized['core_essence'] = _sanitizeText(sanitized['core_essence'] as String);
    }
    if (sanitized['exam_tips'] is String) {
      sanitized['exam_tips'] = _sanitizeText(sanitized['exam_tips'] as String);
    }
    
    final keyTakeawaysObj = sanitized['key_takeaways'] ?? {};
    if (keyTakeawaysObj['takeaways'] is List) {
      for (var item in keyTakeawaysObj['takeaways']) {
        if (item is Map) {
          if (item['title'] is String) item['title'] = _sanitizeText(item['title'] as String);
          if (item['description'] is String) item['description'] = _sanitizeText(item['description'] as String);
        }
      }
    }
    if (keyTakeawaysObj['outline'] is List) {
      for (var item in keyTakeawaysObj['outline']) {
        if (item is Map) {
          if (item['section_title'] is String) item['section_title'] = _sanitizeText(item['section_title'] as String);
          if (item['section_summary'] is String) item['section_summary'] = _sanitizeText(item['section_summary'] as String);
        }
      }
    }
    if (keyTakeawaysObj['glossary'] is List) {
      for (var item in keyTakeawaysObj['glossary']) {
        if (item is Map) {
          if (item['term'] is String) item['term'] = _sanitizeText(item['term'] as String);
          if (item['definition'] is String) item['definition'] = _sanitizeText(item['definition'] as String);
        }
      }
    }
    if (keyTakeawaysObj['study_questions'] is List) {
      final list = keyTakeawaysObj['study_questions'] as List;
      for (int i = 0; i < list.length; i++) {
        if (list[i] is String) {
          list[i] = _sanitizeText(list[i] as String);
        }
      }
    }
    
    return sanitized;
  }

  String _sanitizeText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'\$\s*\\\s*rightarrow\s*\$', caseSensitive: false), '→')
        .replaceAll(RegExp(r'\\\s*rightarrow', caseSensitive: false), '→')
        .replaceAll(RegExp(r'\$\s*[\r\n]\s*ightarrow\s*\$', caseSensitive: false), '→')
        .replaceAll(RegExp(r'[\r\n]\s*ightarrow', caseSensitive: false), '→')
        .replaceAll(r'$→$', '→')
        .replaceAll(r'→$', '→')
        .replaceAll(r'$→', '→');
  }

  Future<void> regenerateSummary(String lectureId) async {
    _setLoading(true);
    error = null;
    try {
      final details = await _db.getLectureDetails(lectureId);
      final transcript = details?['raw_transcript'];
      if (transcript == null || transcript.isEmpty) {
        throw Exception("Transkrip tidak ditemukan. Tidak dapat meregenerasi ringkasan.");
      }

      final cleanedTranscript = _cleanFillerWords(transcript);
      final summaryRaw = await _ai.generateSummary(cleanedTranscript);
      final summaryData = jsonDecode(_cleanJson(summaryRaw));

      await _db.saveSummary(
        lectureId,
        summaryData['core_essence'] ?? '',
        {
          'takeaways': summaryData['key_takeaways'] ?? [],
          'outline': summaryData['outline'] ?? [],
          'glossary': summaryData['glossary'] ?? [],
          'study_questions': summaryData['study_questions'] ?? [],
        },
        summaryData['exam_tip'] ?? '',
      );

      await fetchSummary(lectureId);
    } catch (e) {
      error = "Gagal memperbarui ringkasan: ${_mapAIError(e)}";
      print(error);
    } finally {
      _setLoading(false);
    }
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

  Future<void> getOrGenerateFlashcards(String lectureId) async {
    _setLoading(true);
    error = null;
    try {
      currentFlashcards = await _db.getFlashcards(lectureId);
      if (currentFlashcards.isEmpty) {
        final summary = await _db.getSummary(lectureId);
        String summaryText = "";
        if (summary != null) {
          summaryText = jsonEncode(summary);
        } else {
          final lecture = await _db.getLectureDetails(lectureId);
          summaryText = lecture?['raw_transcript'] ?? '';
        }
        
        if (summaryText.isNotEmpty) {
          final flashcardsRaw = await _ai.generateFlashcards(summaryText);
          final List<dynamic> flashcardsData = jsonDecode(_cleanJson(flashcardsRaw));
          
          await _db.saveFlashcards(
            lectureId,
            flashcardsData.map((f) => {
              'front_concept': f['front_concept'],
              'back_detail': f['back_detail'],
            }).toList().cast<Map<String, dynamic>>(),
          );
          
          currentFlashcards = await _db.getFlashcards(lectureId);
        }
      }
      notifyListeners();
    } catch (e) {
      error = "Gagal memuat kartu AI: ${_mapAIError(e)}";
      print(error);
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

  String _mapGeneralError(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') || str.contains('failed host lookup') || str.contains('clientexception')) {
      return "Koneksi internet bermasalah. Periksa koneksi internet Anda dan coba lagi.";
    }
    return e.toString();
  }

  Future<void> submitQuizResult(String lectureId, int score, int total, List<Map<String, dynamic>> answers) async {
    error = null; // Reset error sebelum submit untuk menghindari error lama (misal dari rekaman audio) muncul
    try {
      await _db.saveQuizAttempt(lectureId, score, total, answers);
      await fetchAllQuizAttempts();
      
      // Ensure we have the course ID to update stats
      String? courseId = currentLectureDetails?['course_id'];
      
      if (courseId == null) {
        // Fallback: Fetch lecture details if they aren't in memory
        final details = await _db.getLectureDetails(lectureId);
        courseId = details?['course_id'];
      }

      if (courseId != null) {
        await fetchAverageScoreForCourse(courseId);
      }
    } catch (e) {
      error = "Gagal menyimpan hasil kuis: ${_mapGeneralError(e)}";
      notifyListeners();
    }
  }

  Future<void> fetchAllQuizAttempts() async {
    try {
      allQuizAttempts = await _db.getAllQuizAttempts();
      notifyListeners();
    } catch (e) {
      print('DEBUG: AppProvider error fetching all quiz attempts: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchOrGenerateDiagnostics(
    String lectureId, 
    String lectureTitle, 
    List<Map<String, dynamic>> detailedAnswers
  ) async {
    if (lectureDiagnostics.containsKey(lectureId)) {
      return lectureDiagnostics[lectureId];
    }

    isDiagnosticsLoading = true;
    error = null;
    notifyListeners();

    try {
      final rawResponse = await _ai.generateDiagnostics(lectureTitle, detailedAnswers);
      String cleaned = rawResponse.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```(json)?'), '').replaceAll(RegExp(r'```$'), '').trim();
      }
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      lectureDiagnostics[lectureId] = parsed;
      isDiagnosticsLoading = false;
      notifyListeners();
      return parsed;
    } catch (e) {
      error = "Gagal memproses diagnosis AI: ${_mapGeneralError(e)}";
      isDiagnosticsLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> exportLectureSummary() async {
    if (currentSummary == null || currentLectureDetails == null) return null;
    
    _setLoading(true);
    try {
      final keyTakeawaysObj = currentSummary!['key_takeaways'] ?? {};
      final takeaways = keyTakeawaysObj['takeaways'] is List ? keyTakeawaysObj['takeaways'] as List<dynamic> : [];
      final outline = keyTakeawaysObj['outline'] is List ? keyTakeawaysObj['outline'] as List<dynamic> : [];
      final glossary = keyTakeawaysObj['glossary'] is List ? keyTakeawaysObj['glossary'] as List<dynamic> : [];
      final studyQuestions = keyTakeawaysObj['study_questions'] is List ? keyTakeawaysObj['study_questions'] as List<dynamic> : [];

      final path = await PdfService.generateLectureSummaryPdf(
        title: currentLectureDetails!['title'] ?? 'Untitled',
        date: currentLectureDetails!['lecture_date'] ?? '-',
        coreEssence: currentSummary!['core_essence'] ?? '-',
        takeaways: takeaways,
        examTips: currentSummary!['exam_tips'] ?? '-',
        outline: outline,
        glossary: glossary,
        studyQuestions: studyQuestions,
      );
      
      _setLoading(false);
      return path;
    } catch (e) {
      error = "Gagal memproses PDF: ${e.toString()}";
      _setLoading(false);
      return null;
    }
  }

  Future<void> fetchDueFlashcards() async {
    try {
      dueFlashcards = await _db.getFlashcardsDue();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  Future<void> updateFlashcardStatus(String cardId, String status, {int intervalDays = 0}) async {
    try {
      await _db.updateFlashcardSRS(cardId, intervalDays, status);
      await fetchDueFlashcards(); // Refresh list
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  // --- AI Chat ---
  Future<void> setChatLecture(String lectureId, {String? remedialPrompt}) async {
    // Prevent duplicate context settings if it's already the same lecture and no remedialPrompt is provided
    if (remedialPrompt == null && chatLecture != null && chatLecture!['id'] == lectureId && chatMessages.isNotEmpty) return;

    _setLoading(true);
    chatMessages = []; 
    chatCourse = null; // Clear course mode
    activeRemedialPrompt = remedialPrompt;
    try {
      chatLecture = await _db.getLectureDetails(lectureId);
      
      if (remedialPrompt != null) {
        // Initial greeting custom to remedial mode
        final diagnostic = lectureDiagnostics[lectureId];
        final weaknesses = diagnostic != null && diagnostic['weaknesses'] != null
            ? List<String>.from(diagnostic['weaknesses'])
            : <String>[];

        String greetingText = "Halo! Saya DigestBot. Saya melihat Anda butuh ulasan remedial untuk materi '${chatLecture!['title']}'.";
        if (weaknesses.isNotEmpty) {
          greetingText += "\n\nBerdasarkan hasil kuis Anda, ada beberapa konsep yang perlu diperbaiki:\n"
              "${weaknesses.map((w) => "• $w").join("\n")}"
              "\n\nMari kita bahas konsep yang masih kurang Anda pahami. Apa yang ingin Anda tanyakan terlebih dahulu?";
        } else {
          greetingText += " Mari kita bahas konsep yang masih kurang Anda pahami. Apa yang ingin Anda tanyakan terlebih dahulu?";
        }

        chatMessages.add({
          'role': 'bot',
          'text': greetingText,
        });
      } else {
        // Load history from database
        final history = await _db.getChatMessages(lectureId);
        if (history.isEmpty) {
          // Initial greeting only if brand new chat
          chatMessages.add({
            'role': 'bot',
            'text': "Halo! Saya adalah DigestBot. Ada yang ingin ditanyakan terkait materi '${chatLecture!['title']}' ini?",
          });
        } else {
          chatMessages = history.map((m) => {
            'role': m['role'],
            'text': m['content'],
          }).toList();
        }
      }
      await fetchRecentChatSessions();
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> setChatCourse(String courseId) async {
    _setLoading(true);
    chatMessages = [];
    chatLecture = null;
    try {
      final courseList = courses.where((c) => c['id'] == courseId).toList();
      if (courseList.isNotEmpty) {
        chatCourse = courseList.first;
        chatMessages.add({
          'role': 'bot',
          'text': "Halo! Saya DigestBot. Saya sekarang memahami seluruh konteks mata kuliah '${chatCourse!['name']}'. Silakan tanya apa saja!",
        });
      }
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  void clearChatContext() {
    chatLecture = null;
    chatCourse = null;
    chatMessages = [];
    notifyListeners();
  }

  Future<void> fetchRecentChatSessions() async {
    isRecentChatsLoading = true;
    notifyListeners();
    try {
      recentChatSessions = await _db.getRecentChatSessions();
    } catch (e) {
      error = e.toString();
    }
    isRecentChatsLoading = false;
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

  Future<String?> getShareCode(String lectureId) async {
    try {
      return await _db.getOrCreateShareCode(lectureId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> importSharedLecture(String code, String targetCourseId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _db.getFullLectureByCode(code);
      if (data == null) {
        error = "Kode tidak ditemukan atau salah.";
        isLoading = false;
        notifyListeners();
        return false;
      }

      await _db.importLecture(targetCourseId, data);
      await fetchAllLectures();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendChatMessage(String text, {String? fileContext, String? fileName}) async {
    if (chatLecture == null && chatCourse == null) return;
    
    final displayUserText = fileName != null ? "[File: $fileName] $text" : text;
    
    // 1. Add to local UI
    chatMessages.add({'role': 'user', 'text': displayUserText});
    notifyListeners();
    
    try {
      String contextId = '';
      String contextTranscript = '';

      if (chatLecture != null) {
        contextId = chatLecture!['id'];
        
        // Coba gunakan Ringkasan Kuliah untuk menghemat token
        final summaryData = await _db.getSummary(contextId);
        if (summaryData != null) {
          contextTranscript = "Ringkasan Kuliah:\n"
              "Intisari Utama: ${summaryData['core_essence'] ?? ''}\n"
              "Poin Penting: ${jsonEncode(summaryData['key_takeaways'] ?? {})}\n"
              "Exam Tips: ${summaryData['exam_tips'] ?? ''}\n";
        } else {
          // Fallback ke transkrip mentah (dibersihkan dari filler words)
          final rawText = chatLecture!['raw_transcript'] ?? '';
          contextTranscript = "Transkrip Kuliah:\n${_cleanFillerWords(rawText)}";
        }

        if (activeRemedialPrompt != null) {
          contextTranscript = "REMEDIAL LESSON GUIDANCE INSTRUCTION: $activeRemedialPrompt\n\n$contextTranscript";
        }
        if (fileContext != null) {
          contextTranscript = "ATTACHED DOCUMENT CONTEXT (FileName: $fileName):\n$fileContext\n\n$contextTranscript";
        }
        await _db.saveChatMessage(contextId, 'user', displayUserText);
      } else if (chatCourse != null) {
        contextId = chatCourse!['id'];
        // Course Mode: Aggregating context from all lectures
        final courseLectures = await _db.getLectures(contextId);
        contextTranscript = "Konteks Mata Kuliah: ${chatCourse!['name']}\n\n";
        for (var l in courseLectures) {
          contextTranscript += "Materi: ${l['title']}\nTranskrip: ${_cleanFillerWords(l['raw_transcript'] ?? 'No transcript available.')}\n\n";
        }
        if (fileContext != null) {
          contextTranscript = "ATTACHED DOCUMENT CONTEXT (FileName: $fileName):\n$fileContext\n\n$contextTranscript";
        }
        // Trim if too long for token limits (approx 15k chars for safe GPT-3.5 context)
        if (contextTranscript.length > 20000) {
          contextTranscript = contextTranscript.substring(0, 20000) + "... [Konteks dipotong untuk efisiensi]";
        }
      }

      // 2. Prepare history for AI
      final List<Map<String, String>> history = chatMessages.map((m) => {
        'role': m['role'].toString(),
        'content': m['text'].toString(),
      }).toList();
      
      if (history.isNotEmpty) history.removeLast();

      // 3. Get AI Response
      final response = await _ai.askAIChat(contextTranscript, text, history);
      
      // 4. Save Bot Response (only if in specific lecture mode for persistent history)
      chatMessages.add({'role': 'bot', 'text': response});
      if (chatLecture != null) {
        await _db.saveChatMessage(contextId, 'bot', response);
        await fetchRecentChatSessions();
      }
      
    } catch (e) {
      print("Chat Error: $e");
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
  Future<String?> processLectureRecording(String courseId, String title, String audioPath, int durationMinutes) async {
    _setLoading(true);
    error = null;
    try {
      // 1. Transcribe real audio first
      final transcript = await _transcriber.transcribe(audioPath);
      if (transcript.isEmpty) throw Exception("Transkrip kosong. Pastikan suara terdengar jelas.");

      final cleanedTranscript = _cleanFillerWords(transcript);

      // Batasi transkrip maksimal 5000 kata untuk proteksi token input
      final List<String> words = cleanedTranscript.split(RegExp(r'\s+'));
      final finalTranscript = words.length > 5000 
          ? '${words.sublist(0, 5000).join(' ')}... [Transkrip dipotong otomatis karena melebihi batas 5.000 kata]' 
          : cleanedTranscript;

      // 2. Save Lecture (with audio path for playback)
      final lectureId = await _db.saveLecture(courseId, title, durationMinutes, finalTranscript, audioPath: audioPath);

      // 3. Generate Summary via AI
      final summaryRaw = await _ai.generateSummary(finalTranscript);
      final summaryData = jsonDecode(_cleanJson(summaryRaw));

      // 4. Save Summary
      await _db.saveSummary(
        lectureId,
        summaryData['core_essence'] ?? '',
        {
          'takeaways': summaryData['key_takeaways'] ?? [],
          'outline': summaryData['outline'] ?? [],
          'glossary': summaryData['glossary'] ?? [],
          'study_questions': summaryData['study_questions'] ?? [],
        },
        summaryData['exam_tip'] ?? '',
      );

      // Finish
      await fetchCourses(); 
      await fetchDueFlashcards();
      _setLoading(false);
      return lectureId;
    } catch (e) {
      error = "Gagal memproses AI: ${_mapAIError(e)}";
      print(error);
    }
    _setLoading(false);
    return null;
  }

  // --- Quiz Generation Logic (Manual Trigger) ---
  Future<void> generateQuizForLecture(String lectureId, {int count = 5}) async {
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
        contextText = lecture?['raw_transcript'] ?? '';
      }
      
      if (contextText.isEmpty) throw Exception("Tidak ada materi untuk membuat kuis.");

      // 2. Generate via AI
      final quizRaw = await _ai.generateQuizzes(contextText, count: count);
      final List<dynamic> quizData = jsonDecode(_cleanJson(quizRaw));

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
      error = "Gagal membuat kuis AI: ${_mapAIError(e)}";
      print(error);
    }
    _setLoading(false);
  }

  // --- Document Upload Workflow ---
  Future<String?> processDocument(String courseId, String title, PickedDocument file) async {
    _setLoading(true);
    error = null;
    try {
      // 1. Extract text from PDF
      final transcript = await _docService.extractTextFromPDF(file);
      
      // Batasi transkrip maksimal 5000 kata untuk proteksi token input
      final List<String> words = transcript.split(RegExp(r'\s+'));
      final finalTranscript = words.length > 5000 
          ? '${words.sublist(0, 5000).join(' ')}... [Transkrip dipotong otomatis karena melebihi batas 5.000 kata]' 
          : transcript;

      // 2. Save Lecture (Mock duration for documents as 5 mins)
      final lectureId = await _db.saveLecture(courseId, title, 5, finalTranscript, audioPath: null);

      // 3. Generate Summary via AI
      final summaryRaw = await _ai.generateSummary(finalTranscript);
      final summaryData = jsonDecode(_cleanJson(summaryRaw));

      // 4. Save Summary
      await _db.saveSummary(
        lectureId,
        summaryData['core_essence'] ?? '',
        {
          'takeaways': summaryData['key_takeaways'] ?? [],
          'outline': summaryData['outline'] ?? [],
          'glossary': summaryData['glossary'] ?? [],
          'study_questions': summaryData['study_questions'] ?? [],
        },
        summaryData['exam_tip'] ?? '',
      );

      // Finish
      await fetchCourses(); 
      await fetchDueFlashcards();
      _setLoading(false);
      return lectureId;
    } catch (e) {
      error = "Gagal memproses dokumen: ${_mapAIError(e)}";
      print(error);
    }
    _setLoading(false);
    return null;
  }

  String _cleanJson(String input) {
    String cleaned = input.trim();
    
    // Strip markdown formatting if it wraps everything
    cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*```$'), '');
    cleaned = cleaned.trim();

    int startIdx = -1;
    int braceCount = 0;
    int bracketCount = 0;
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < cleaned.length; i++) {
      int char = cleaned.codeUnitAt(i);
      
      if (escape) {
        escape = false;
        continue;
      }
      
      if (char == 92) { // backslash \
        escape = true;
        continue;
      }
      
      if (char == 34) { // double quote "
        inString = !inString;
        continue;
      }
      
      if (!inString) {
        if (char == 123) { // open brace {
          if (braceCount == 0 && bracketCount == 0) {
            startIdx = i;
          }
          braceCount++;
        } else if (char == 125) { // close brace }
          braceCount--;
          if (braceCount == 0 && bracketCount == 0 && startIdx != -1) {
            cleaned = cleaned.substring(startIdx, i + 1);
            break;
          }
        } else if (char == 91) { // open bracket [
          if (braceCount == 0 && bracketCount == 0) {
            startIdx = i;
          }
          bracketCount++;
        } else if (char == 93) { // close bracket ]
          bracketCount--;
          if (braceCount == 0 && bracketCount == 0 && startIdx != -1) {
            cleaned = cleaned.substring(startIdx, i + 1);
            break;
          }
        }
      }
    }
    
    // Remove trailing commas before closing braces/brackets (common LLM error)
    cleaned = cleaned.replaceAllMapped(RegExp(r',\s*([\]}])'), (match) => match.group(1)!);
    return cleaned;
  }

  String _mapAIError(dynamic e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('timeout') || 
        errStr.contains('time out') || 
        errStr.contains('504') || 
        errStr.contains('502') || 
        errStr.contains('deadline')) {
      return "Koneksi ke AI terputus atau batas waktu habis (Timeout). Silakan klik/coba kembali, biasanya akan berhasil pada percobaan berikutnya.";
    }
    if (errStr.contains('rate limit') || 
        errStr.contains('429') || 
        errStr.contains('too many requests')) {
      return "Server AI sedang sibuk menerima banyak permintaan (Rate Limit). Mohon tunggu beberapa detik sebelum mencoba lagi.";
    }
    if (errStr.contains('google') || 
        errStr.contains('openrouter') || 
        errStr.contains('api')) {
      return "Terjadi kendala koneksi ke server AI. Silakan coba lagi beberapa saat lagi.";
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  String _cleanFillerWords(String text) {
    if (text.isEmpty) return text;
    final List<String> fillerWords = [
      // Bunyi vokal pengisi / interjeksi suara
      'aaa', 'eee', 'ooo', 'hmmm', 'hmm', 'uhhh', 'uh', 'ummm', 'umm', 'um',
      'eh', 'ehm', 'ah', 'oh', 'hah', 'heeh', 'lah', 'lha', 'kok', 'sih', 
      'lho', 'dong', 'deh', 'well', 'like', 'so',
      
      // Kata pengisi / jeda bahasa Indonesia
      'anu', 'kayak', 'kayaknya', 'kek', 'ya kan', 'kan ya', 
      'apa namanya', 'apa tuh', 'apa sih', 'apa ya',
      'gitu kan', 'gitu lho', 'gitu ya', 'gitu sih',
      'gimana ya', 'gimana sih', 'macam kayak', 'semacam',
      
      // Kata pengisi bahasa Inggris (yang sering diucapkan saat berbicara)
      'basically', 'literally', 'actually', 'you know'
    ];
    String cleaned = text;
    for (final word in fillerWords) {
      final regExp = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      cleaned = cleaned.replaceAll(regExp, '');
    }
    
    // Hapus kata yang berulang akibat gagap/stuttering (contoh: "saya saya" -> "saya")
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false), 
      (match) => match.group(1)!
    );
    
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';

class LearningDiagnosticsScreen extends StatefulWidget {
  const LearningDiagnosticsScreen({super.key});

  @override
  State<LearningDiagnosticsScreen> createState() => _LearningDiagnosticsScreenState();
}

class _LearningDiagnosticsScreenState extends State<LearningDiagnosticsScreen> {
  String? _selectedLectureId;
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.fetchAllQuizAttempts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: isDesktop ? 80 : 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: isDesktop 
            ? Row(
                children: [
                  const BrandLogo(size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'LectureDigest',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.onBackground,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              )
            : const Text('Pusat Diagnosis AI', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: !isDesktop,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Process unique latest attempts per lecture
                final latestAttemptsMap = <String, Map<String, dynamic>>{};
                for (var attempt in provider.allQuizAttempts) {
                  final lectureId = attempt['lecture_id'] as String;
                  if (!latestAttemptsMap.containsKey(lectureId)) {
                    latestAttemptsMap[lectureId] = attempt;
                  }
                }

                // Calculate statistics per course
                final courseStatsMap = <String, List<double>>{};
                for (var attempt in latestAttemptsMap.values) {
                  final lectureId = attempt['lecture_id'];
                  final lecture = provider.lectures.firstWhere(
                    (l) => l['id'] == lectureId,
                    orElse: () => <String, dynamic>{},
                  );
                  final courseId = lecture['course_id'] as String?;
                  if (courseId != null) {
                    final scorePercent = (attempt['score'] as int) / (attempt['total_questions'] as int);
                    courseStatsMap.putIfAbsent(courseId, () => []).add(scorePercent);
                  }
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(context),
                      const SizedBox(height: 24),
                      _buildFilterSection(provider),
                      const SizedBox(height: 32),
                      _buildCoursesSummaryGrid(provider, courseStatsMap, isDesktop),
                      const SizedBox(height: 48),
                      _buildLowScoresListSection(provider, latestAttemptsMap, isDesktop),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIAGNOSIS PEMBELAJARAN',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.5,
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Deteksi Dini Kesulitan Belajar',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI memantau hasil kuis Anda untuk mendeteksi materi yang membutuhkan ulasan tambahan serta memberikan rencana aksi perbaikan terarah.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildCoursesSummaryGrid(
    AppProvider provider,
    Map<String, List<double>> courseStatsMap,
    bool isDesktop,
  ) {
    final filteredCourses = _selectedCourseId == null
        ? provider.courses
        : provider.courses.where((c) => c['id'] == _selectedCourseId).toList();

    if (filteredCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tingkat Pemahaman Kelas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 16,
            mainAxisExtent: 110,
          ),
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            final course = filteredCourses[index];
            final courseId = course['id'] as String;
            final rates = courseStatsMap[courseId] ?? [];
            
            double average = 0.0;
            if (rates.isNotEmpty) {
              average = rates.reduce((a, b) => a + b) / rates.length;
            } else {
              // Fallback to average score from DB stats if available
              average = (provider.courseStats[courseId] ?? 0.0) / 100.0;
            }

            final hasAttempts = rates.isNotEmpty || (provider.courseStats[courseId] ?? 0.0) > 0.0;
            final isNeedAttention = average < 0.7;

            final accentColor = !hasAttempts 
                ? AppTheme.onSurfaceVariant.withOpacity(0.6)
                : (isNeedAttention ? const Color(0xFF842029) : const Color(0xFF0F5132));
            final cardColor = !hasAttempts 
                ? AppTheme.surfaceContainerLow
                : (isNeedAttention ? const Color(0xFFFDF4F5) : const Color(0xFFF3FAF6));
            final borderColor = !hasAttempts 
                ? AppTheme.outlineVariant.withOpacity(0.1)
                : (isNeedAttention ? const Color(0xFFF5C2C7) : const Color(0xFFD1E7DD));
            final statusText = !hasAttempts
                ? 'Belum Ada Data'
                : (isNeedAttention ? 'Perlu Ulasan' : 'Sangat Baik');

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasAttempts && !isNeedAttention ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          course['name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            if (hasAttempts)
                              Text(
                                '${(average * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLowScoresListSection(
    AppProvider provider,
    Map<String, Map<String, dynamic>> latestAttemptsMap,
    bool isDesktop,
  ) {
    final lowScoreAttempts = latestAttemptsMap.values.where((attempt) {
      final score = attempt['score'] as int;
      final total = attempt['total_questions'] as int;
      final isLow = total > 0 && (score / total) < 0.7;
      if (!isLow) return false;

      if (_selectedCourseId != null) {
        final lectureId = attempt['lecture_id'];
        final lecture = provider.lectures.firstWhere(
          (l) => l['id'] == lectureId,
          orElse: () => <String, dynamic>{},
        );
        return lecture['course_id'] == _selectedCourseId;
      }
      return true;
    }).toList();

    if (lowScoreAttempts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAF6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD1E7DD)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF0F5132), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Performa Belajar Luar Biasa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F5132)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Belum ada materi kuliah yang terdeteksi membutuhkan perbaikan. Pemahaman Anda berada di atas target minimum.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF0F5132), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materi yang Perlu Perbaikan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
        ),
        const SizedBox(height: 16),
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildMateriList(provider, lowScoreAttempts),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 1,
                    child: _buildDiagnosticsDetailPanel(provider),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildMateriList(provider, lowScoreAttempts),
                  if (_selectedLectureId != null) ...[
                    const SizedBox(height: 24),
                    _buildDiagnosticsDetailPanel(provider),
                  ],
                ],
              ),
      ],
    );
  }

  Widget _buildMateriList(AppProvider provider, List<Map<String, dynamic>> attempts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        final lectureId = attempt['lecture_id'] as String;
        final lecture = provider.lectures.firstWhere(
          (l) => l['id'] == lectureId,
          orElse: () => <String, dynamic>{},
        );
        
        final isSelected = _selectedLectureId == lectureId;
        final score = attempt['score'] as int;
        final total = attempt['total_questions'] as int;
        final percent = (score / total) * 100;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.12),
              width: isSelected ? 2 : 1,
            ),
          ),
          color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainerLowest,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(
              lecture['title'] ?? 'Tanpa Judul',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Text(
                    'Skor Kuis: ${percent.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF842029)),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.outlineVariant, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(
                    lecture['lecture_date'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              setState(() {
                _selectedLectureId = lectureId;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticsDetailPanel(AppProvider provider) {
    if (_selectedLectureId == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.12)),
        ),
        child: const Center(
          child: Text(
            'Pilih materi di sebelah kiri untuk melihat hasil diagnosis kesulitan belajar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final lectureId = _selectedLectureId!;
    final lecture = provider.lectures.firstWhere((l) => l['id'] == lectureId, orElse: () => <String, dynamic>{});
    final diagnostic = provider.lectureDiagnostics[lectureId];
    
    // Find attempt answers
    final attempt = provider.allQuizAttempts.firstWhere((a) => a['lecture_id'] == lectureId, orElse: () => <String, dynamic>{});
    final List<Map<String, dynamic>> detailedAnswers = List<Map<String, dynamic>>.from(attempt['detailed_answers'] ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lecture['title'] ?? 'Tanpa Judul',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Analisis & Tindakan Perbaikan AI',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.0),
          ),
          const Divider(height: 32),
          if (provider.isDiagnosticsLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'AI sedang mendiagnosis kesalahan Anda...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menganalisis riwayat jawaban kuis Anda.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (diagnostic == null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    const Icon(Icons.psychology_outlined, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Diagnosis Belum Dilakukan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Minta AI menganalisis detail jawaban kuis Anda untuk mendeteksi kelemahan secara rinci.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.fetchOrGenerateDiagnostics(
                          lectureId,
                          lecture['title'] ?? 'Materi',
                          detailedAnswers,
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Mulai Diagnosis AI', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildDiagnosticReport(context, provider, lectureId, lecture['title'] ?? 'Materi', diagnostic),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticReport(
    BuildContext context, 
    AppProvider provider, 
    String lectureId, 
    String title, 
    Map<String, dynamic> data
  ) {
    final summary = data['summary'] as String? ?? '';
    final weaknesses = List<String>.from(data['weaknesses'] ?? []);
    final recommendations = List<String>.from(data['recommendations'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rangkuman
        const Text(
          'Hasil Evaluasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          summary,
          style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),

        // Kelemahan
        const Text(
          'Konsep yang Kurang Dipahami',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF842029)),
        ),
        const SizedBox(height: 10),
        ...weaknesses.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6.0, right: 8.0),
                    child: Icon(Icons.circle, size: 6, color: Color(0xFF842029)),
                  ),
                  Expanded(
                    child: Text(
                      w,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.onSurface),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),

        // Rekomendasi
        const Text(
          'Rencana Aksi Perbaikan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F5132)),
        ),
        const SizedBox(height: 10),
        ...recommendations.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6.0, right: 8.0),
                    child: Icon(Icons.check_rounded, size: 14, color: Color(0xFF0F5132)),
                  ),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.onSurface),
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 48),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // Generate remedial prompt for DigestBot
              final prompt = 
                "Saya sedang melakukan sesi bimbingan belajar remedial untuk materi '$title'.\n"
                "AI mendeteksi saya memiliki kelemahan pada konsep-konsep berikut:\n"
                "${weaknesses.map((w) => '- $w').join('\n')}\n\n"
                "Tolong bantu jelaskan konsep-konsep tersebut secara sederhana, ramah, dan interaktif. Berikan saya pertanyaan latihan singkat di akhir penjelasan Anda.";

              // Initialize and navigate
              provider.setChatLecture(lectureId, remedialPrompt: prompt);
              provider.setTabIndex(2); // AskAiChat tab index is 2
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Mulai Sesi Remedial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppTheme.primary.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(AppProvider provider) {
    if (provider.courses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "Semua Kelas" Chip
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: const Text('Semua Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              selected: _selectedCourseId == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCourseId = null;
                    _selectedLectureId = null; // Reset selection detail
                  });
                }
              },
              selectedColor: AppTheme.primary.withOpacity(0.15),
              checkmarkColor: AppTheme.primary,
              backgroundColor: AppTheme.surfaceContainerLow,
              labelStyle: TextStyle(
                color: _selectedCourseId == null ? AppTheme.primary : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          // Course Chips
          ...provider.courses.map((course) {
            final courseId = course['id'] as String;
            final isSelected = _selectedCourseId == courseId;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(course['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCourseId = selected ? courseId : null;
                    _selectedLectureId = null; // Reset selection detail
                  });
                },
                selectedColor: AppTheme.primary.withOpacity(0.15),
                checkmarkColor: AppTheme.primary,
                backgroundColor: AppTheme.surfaceContainerLow,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

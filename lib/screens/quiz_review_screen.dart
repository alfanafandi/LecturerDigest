import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';

class QuizReviewScreen extends StatefulWidget {
  final String lectureId;
  const QuizReviewScreen({super.key, required this.lectureId});

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchLatestQuizAttempt(widget.lectureId);
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
        title: isDesktop ? Row(
          children: [
            const BrandLogo(size: 28),
            const SizedBox(width: 8),
            Text('LectureDigest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ) : Text('Bahas Soal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: !isDesktop,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final attempt = provider.latestQuizAttempt;
              if (attempt == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppTheme.outlineVariant),
                      const SizedBox(height: 16),
                      const Text('Belum ada data pengerjaan kuis.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')),
                    ],
                  ),
                );
              }

              final List<dynamic> answers = attempt['detailed_answers'] ?? [];
              final int score = attempt['score'] ?? 0;
              final int total = attempt['total_questions'] ?? 0;
              final double percentage = (score / total) * 100;

              return Column(
                children: [
                  _buildScoreHeader(score, total, percentage, isDesktop),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(isDesktop ? 32 : 24),
                      itemCount: answers.length,
                      itemBuilder: (context, index) {
                        final item = answers[index];
                        return _buildReviewCard(index + 1, item, isDesktop);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeader(int score, int total, double percentage, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: isDesktop ? 48 : 32),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PERFORMA TERAKHIR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary)),
              const SizedBox(height: 8),
              Text('$score dari $total jawaban benar', style: TextStyle(fontSize: isDesktop ? 20 : 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(int number, Map<String, dynamic> data, bool isDesktop) {
    final bool isCorrect = data['is_correct'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                      child: Text('#$number', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        data['question'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 20 : 16, height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildAnswerRow(
                  label: 'JAWABAN ANDA',
                  value: data['selected_option'] ?? '-',
                  isSelected: true,
                  isCorrect: isCorrect,
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 16),
                  _buildAnswerRow(
                    label: 'JAWABAN BENAR',
                    value: data['correct_answer'] ?? '-',
                    isSelected: false,
                    isCorrect: true,
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.secondary),
                    const SizedBox(width: 12),
                    const Text('PENJELASAN AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data['explanation'] ?? 'Tidak ada penjelasan tersedia.',
                  style: TextStyle(fontSize: isDesktop ? 16 : 14, height: 1.6, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow({required String label, required String value, required bool isSelected, required bool isCorrect}) {
    Color color = isCorrect ? Colors.green : (isSelected ? Colors.red : AppTheme.onSurface);
    IconData icon = isCorrect ? Icons.check_circle_rounded : (isSelected ? Icons.cancel_rounded : Icons.radio_button_off_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Bahas Soal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final attempt = provider.latestQuizAttempt;
          if (attempt == null) {
            return const Center(child: Text('Belum ada data pengerjaan kuis.'));
          }

          final List<dynamic> answers = attempt['detailed_answers'] ?? [];
          final int score = attempt['score'] ?? 0;
          final int total = attempt['total_questions'] ?? 0;
          final double percentage = (score / total) * 100;

          return Column(
            children: [
              _buildScoreHeader(score, total, percentage),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: answers.length,
                  itemBuilder: (context, index) {
                    final item = answers[index];
                    return _buildReviewCard(index + 1, item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreHeader(int score, int total, double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HASIL TERAKHIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Text('$score dari $total jawaban benar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(int number, Map<String, dynamic> data) {
    final bool isCorrect = data['is_correct'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#$number', style: TextStyle(color: AppTheme.primary.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['question'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAnswerRow(
                  label: 'Jawaban Anda',
                  value: data['selected_option'] ?? '-',
                  isSelected: true,
                  isCorrect: isCorrect,
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 12),
                  _buildAnswerRow(
                    label: 'Jawaban Benar',
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.secondary),
                    SizedBox(width: 8),
                    Text('PENJELASAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data['explanation'] ?? 'Tidak ada penjelasan tersedia.',
                  style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.onSurfaceVariant),
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
    IconData icon = isCorrect ? Icons.check_circle_outline : (isSelected ? Icons.cancel_outlined : Icons.radio_button_unchecked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

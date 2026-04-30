import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/quiz_review_screen.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';

class QuizScreen extends StatefulWidget {
  final String lectureId;
  const QuizScreen({super.key, required this.lectureId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedOption;
  bool _isAnswered = false;
  bool _isFinished = false;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchQuizzes(widget.lectureId);
    });
  }

  void _handleAnswer(String option) {
    if (_isAnswered) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final currentQuiz = provider.currentQuizzes[_currentIndex];
    
    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      
      final isCorrect = option == currentQuiz['correct_answer'];
      if (isCorrect) {
        _score++;
      }

      // Store detailed answer for "Review" feature
      _userAnswers.add({
        'question': currentQuiz['question'],
        'selected_option': option,
        'correct_answer': currentQuiz['correct_answer'],
        'is_correct': isCorrect,
        'explanation': currentQuiz['explanation'],
      });
    });
  }

  Future<void> _submitResults() async {
    setState(() => _isSubmitting = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    await provider.submitQuizResult(
      widget.lectureId, 
      _score, 
      provider.currentQuizzes.length, 
      _userAnswers
    );
    
    if (mounted) {
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${provider.error}'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hasil kuis berhasil disimpan!'), backgroundColor: Colors.green),
        );
      }
      
      setState(() {
        _isSubmitting = false;
        _isFinished = true;
      });
    }
  }

  void _nextQuestion() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (_currentIndex < provider.currentQuizzes.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    } else {
      _submitResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isSubmitting) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('Menyimpan hasil kuis Anda...', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('AI sedang memperbarui statistik belajar Anda.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }

        if (provider.currentQuizzes.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kuis AI')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: AppTheme.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('Belum ada kuis untuk materi ini.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')),
                ],
              ),
            ),
          );
        }

        if (_isFinished) {
          return _buildResultView(provider.currentQuizzes.length, isDesktop);
        }

        final quiz = provider.currentQuizzes[_currentIndex];
        final progress = (_currentIndex + 1) / provider.currentQuizzes.length;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: isDesktop ? 80 : 56,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: isDesktop ? Row(
              children: [
                const BrandLogo(size: 28),
                const SizedBox(width: 8),
                Text('LectureDigest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ) : Text('Kuis Materi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            centerTitle: !isDesktop,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.surfaceContainerHighest,
                        color: AppTheme.primary,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PERTANYAAN ${_currentIndex + 1} DARI ${provider.currentQuizzes.length}',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                        ),
                        if (isDesktop) Text(
                          'Skor: $_score',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      quiz['question'] ?? '',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900, 
                        height: 1.4,
                        fontSize: isDesktop ? 32 : 24,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Expanded(
                      child: isDesktop 
                        ? GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              mainAxisExtent: 100,
                            ),
                            itemCount: (quiz['options'] as List).length,
                            itemBuilder: (context, index) {
                              final option = quiz['options'][index];
                              return _buildOptionCard(option, quiz['correct_answer']);
                            },
                          )
                        : ListView.builder(
                            itemCount: (quiz['options'] as List).length,
                            itemBuilder: (context, index) {
                              final option = quiz['options'][index];
                              return _buildOptionCard(option, quiz['correct_answer']);
                            },
                          ),
                    ),
                    if (_isAnswered) ...[
                      _buildFeedbackArea(quiz['explanation'] ?? '', isDesktop),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _nextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppTheme.primary.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            _currentIndex < provider.currentQuizzes.length - 1 ? 'Pertanyaan Selanjutnya' : 'Selesaikan Kuis',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(String option, String correctAnswer) {
    bool isSelected = _selectedOption == option;
    bool isCorrect = option == correctAnswer;
    
    Color borderColor = Colors.transparent;
    Color bgColor = AppTheme.surfaceContainerLowest;
    IconData? icon;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        icon = Icons.check_circle;
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      borderColor = AppTheme.primary;
      bgColor = AppTheme.primary.withOpacity(0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _handleAnswer(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected || (_isAnswered && isCorrect) ? FontWeight.bold : FontWeight.w500,
                    color: _isAnswered && isCorrect ? Colors.green.shade700 : (_isAnswered && isSelected ? Colors.red.shade700 : AppTheme.onSurface),
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: icon == Icons.check_circle ? Colors.green : Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackArea(String explanation, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.secondary),
              const SizedBox(width: 12),
              Text('PENJELASAN AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation, 
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14, 
              height: 1.6, 
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(int totalQuestions, bool isDesktop) {
    double percentage = (_score / totalQuestions) * 100;
    String message = percentage >= 80 ? 'Luar Biasa!' : (percentage >= 60 ? 'Bagus!' : 'Terus Belajar!');
    IconData icon = percentage >= 60 ? Icons.emoji_events : Icons.school;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 100, color: AppTheme.primary),
                ),
                const SizedBox(height: 48),
                Text(message, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary)),
                const SizedBox(height: 16),
                Text(
                  'Anda menjawab $_score dari $totalQuestions soal dengan benar.', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 18, height: 1.5, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 64),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => QuizReviewScreen(lectureId: widget.lectureId))
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          child: const Text('Bahas Soal', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _score = 0;
                      _isAnswered = false;
                      _isFinished = false;
                      _selectedOption = null;
                      _userAnswers.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Ulangi Kuis Sekarang', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';

class FlashcardsReview extends StatefulWidget {
  final String? lectureId;
  const FlashcardsReview({super.key, this.lectureId});

  @override
  State<FlashcardsReview> createState() => _FlashcardsReviewState();
}

class _FlashcardsReviewState extends State<FlashcardsReview> {
  bool isFlipped = false;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.lectureId != null) {
        provider.fetchFlashcards(widget.lectureId!);
      } else {
        provider.fetchDueFlashcards();
      }
    });
  }

  Future<void> _handleReview(String cardId, int intervalDays, int total) async {
    if (!mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Persist to DB
    await provider.updateFlashcardStatus(cardId, 'Learning', intervalDays: intervalDays);

    if (!mounted) return;

    if (currentIndex < total - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi belajar selesai! Bagus!'),
          backgroundColor: Colors.green,
        ),
      );
      // Small delay to ensure snackbar shows and avoid _dependents.isEmpty error
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final cards = widget.lectureId != null ? provider.currentFlashcards : provider.dueFlashcards;
        
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (cards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kartu Hafalan')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style_outlined, size: 64, color: AppTheme.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('Tidak ada kartu untuk dipelajari.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          );
        }

        final currentCard = cards[currentIndex];

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.background.withOpacity(0.9),
            elevation: 0,
            leadingWidth: isDesktop ? 80 : 56,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const BrandLogo(size: 28),
                const SizedBox(width: 8),
                Text('LectureDigest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('REVIEW AKADEMIK', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              Text('Kartu Hafalan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: isDesktop ? 40 : 28)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest, 
                            borderRadius: BorderRadius.circular(20), 
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))]
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppTheme.tertiary, size: 20),
                              const SizedBox(width: 12),
                              Text('${currentIndex + 1} dari ${cards.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isFlipped = !isFlipped;
                        });
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final rotate = Tween(begin: 3.14 / 2, end: 0.0).animate(animation);
                          return AnimatedBuilder(
                            animation: rotate,
                            child: child,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.rotationY(rotate.value),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                          );
                        },
                        child: isFlipped 
                            ? _buildBackSide(currentCard['back_detail'] ?? '', isDesktop) 
                            : _buildFrontSide(currentCard['front_concept'] ?? '', isDesktop),
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (!isFlipped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, size: 16, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text(
                              'Ketuk kartu untuk melihat jawaban',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          const Text(
                            'SEBERAPA MUDAH KAMU MENGINGAT INI?',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.outlineVariant, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildReviewButton(
                                  context, 
                                  'SULIT', 
                                  'Besok',
                                  AppTheme.tertiary, 
                                  () => _handleReview(currentCard['id'], 1, cards.length)
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildReviewButton(
                                  context, 
                                  'SEDANG', 
                                  '3 Hari',
                                  AppTheme.secondary, 
                                  () => _handleReview(currentCard['id'], 3, cards.length)
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildReviewButton(
                                  context, 
                                  'MUDAH', 
                                  '7 Hari',
                                  AppTheme.primary, 
                                  () => _handleReview(currentCard['id'], 7, cards.length)
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontSide(String concept, bool isDesktop) {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: isDesktop ? 450 : 380,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.help_outline_rounded, color: AppTheme.primary),
          ),
          const SizedBox(height: 32),
          Text(concept, textAlign: TextAlign.center, style: TextStyle(fontSize: isDesktop ? 36 : 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 48),
          const Text('KETUK UNTUK JAWABAN', style: TextStyle(color: AppTheme.outlineVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        ],
      ),
    );
  }

  Widget _buildBackSide(String detail, bool isDesktop) {
    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: isDesktop ? 450 : 380,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary),
          ),
          const SizedBox(height: 32),
          Text(detail, textAlign: TextAlign.center, style: TextStyle(fontSize: isDesktop ? 24 : 18, fontWeight: FontWeight.w600, height: 1.6)),
          const SizedBox(height: 48),
          const Text('KETUK UNTUK KEMBALI', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        ],
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context, String label, String subtitle, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

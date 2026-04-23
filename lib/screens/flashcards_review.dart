import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';

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

  void _nextCard(int total) {
    if (currentIndex < total - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi belajar selesai! Bagus!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final cards = widget.lectureId != null ? provider.currentFlashcards : provider.dueFlashcards;
        
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (cards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flashcards')),
            body: const Center(child: Text('Tidak ada kartu untuk dipelajari.')),
          );
        }

        final currentCard = cards[currentIndex];

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.background.withOpacity(0.9),
            elevation: 0,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACADEMIC REVIEW', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('Flashcards', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16)]),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: AppTheme.tertiary, size: 24),
                          const SizedBox(width: 8),
                          Text('${currentIndex + 1}/${cards.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isFlipped = !isFlipped;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: isFlipped 
                        ? _buildBackSide(currentCard['back_detail'] ?? '') 
                        : _buildFrontSide(currentCard['front_concept'] ?? ''),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _nextCard(cards.length),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Still Learning'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(cards.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Got It!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontSide(String concept) {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: 380,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(concept, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          const Text('TAP TO REVEAL', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildBackSide(String detail) {
    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: 380,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(detail, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.5)),
          const SizedBox(height: 48),
          const Text('TAP TO FLIP BACK', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

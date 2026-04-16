import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/flashcards_review.dart';
import 'package:lecturer_digest/screens/new_lecture_recording.dart';
import 'package:lecturer_digest/screens/lecture_summary_view.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_stories, color: AppTheme.primary),
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
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryContainer, width: 2),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAbP6Oxc6OIqiBQIXVdbxYw18jCF3kZHgBtMA__sqbmfPm4L8GrM91jl7bZfsCG4z_agCQiiIk91l7HBEyZN2UU6tzlIxbzAIlnLczfK_CYgyN8tYLY8orE7hvA9IO-ivk-2XZUXBNz9hIKAlDbANol0585gmHKz7vXb3wXt6l9auZEQ4r6MyLbJ_BNeTwEnWYrUYjeNgSbX4u8G5mqSmPrGKIntrstaGqYrVA_EWGJUlFnyzCHgCsL7RHIr9qDjJhjWCPlCmBgqz10'
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Greeting Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELAMAT DATANG',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.0,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Halo, Budi!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    final todayStr = DateTime.now().toIso8601String().split('T')[0];
                    final todayCount = provider.lectures.where((l) => l['lecture_date'] == todayStr).length;
                    final dueCount = provider.dueFlashcards.length;

                    return Row(
                      children: [
                        Expanded(child: _buildStatChip(context, Icons.event_note, '$todayCount Materi Hari Ini', AppTheme.secondary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatChip(context, Icons.quiz, '$dueCount Kartu Hafalan', AppTheme.tertiary)),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Recent Summaries Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Terbaru',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Lanjutkan belajarmu',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Text(
                      'Lihat Semua',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Summaries List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    if (provider.lectures.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada rangkuman materi. Mulailah merekam kuliah!',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.lectures.length > 5 ? 5 : provider.lectures.length,
                      itemBuilder: (context, index) {
                        final lecture = provider.lectures[index];
                        final date = lecture['created_at'] != null 
                          ? DateTime.parse(lecture['created_at']).toLocal() 
                          : DateTime.now();
                        
                        final status = lecture['status'] == 'Summarized' ? 'Selesai' : 'Proses';

                        return _buildSummaryCard(
                          context,
                          lecture['id'] ?? '',
                          'Materi',
                          '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          lecture['title'] ?? 'Tanpa Judul',
                          lecture['raw_transcript'] ?? 'Tidak ada transkrip',
                          status,
                          AppTheme.primary.withOpacity(0.1),
                          AppTheme.primary,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Upcoming Lectures Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Kuliah Mendatang',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Jangan lewatkan sesi berikutnya',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Upcoming Lectures List
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 48, color: AppTheme.outlineVariant.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'Jadwal kuliah belum diatur.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label, Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (label.contains('Flashcard')) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardsReview()));
        } else if (label.contains('Materi')) {
          // Navigate to all lectures or history if needed
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String lectureId,
    String tag,
    String time,
    String title,
    String desc,
    String duration,
    Color tagBg,
    Color tagText,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LectureSummaryView(lectureId: lectureId),
        ));
      },
      child: Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag.toUpperCase(),
                  style: TextStyle(
                    color: tagText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.schedule, color: AppTheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                duration,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildUpcomingLectureItem(
    BuildContext context,
    String month,
    String day,
    String title,
    String subtitle,
    bool isJoinActive,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewLectureRecording()));
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    child: const Text('Record', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isJoinActive ? () {} : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoinActive ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                      foregroundColor: isJoinActive ? Colors.white : AppTheme.onSurfaceVariant,
                      elevation: isJoinActive ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    child: Text('Join', style: TextStyle(fontWeight: FontWeight.w700, color: isJoinActive ? Colors.white : Colors.grey)),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

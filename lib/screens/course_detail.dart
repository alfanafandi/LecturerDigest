import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/lecture_summary_view.dart';

class CourseDetail extends StatefulWidget {
  final String courseId;
  final String title;
  final Color color;

  const CourseDetail({super.key, required this.courseId, required this.title, required this.color});

  @override
  State<CourseDetail> createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchLectures(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.surface,
              surfaceTintColor: AppTheme.surface,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Row(
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
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 0),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  // Basic dynamic calculation
                  final summarizedCount = provider.lectures.where((l) => l['status'] == 'Summarized').length;
                  final totalSavedMinutes = summarizedCount * 25; // Estimate 25 mins saved per 1hr lecture
                  final hoursSaved = (totalSavedMinutes / 60).toStringAsFixed(1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 12))
                              ],
                            ),
                            child: Column(
                              children: [
                                Text('${hoursSaved}j', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('Waktu Hemat', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 12))
                              ],
                            ),
                            child: Column(
                              children: [
                                Text('${(provider.courseStats[widget.courseId] ?? 0).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('Skor Kuis', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Menunggu AI'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sudah Diringkas'),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverToBoxAdapter(
                child: Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (provider.lectures.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("Belum ada sesi rekaman.", style: TextStyle(color: AppTheme.outlineVariant)),
                        ),
                      );
                    }
                    final allLectures = provider.lectures;
                    final filteredLectures = allLectures.where((l) {
                      if (_selectedFilter == 'Semua') return true;
                      if (_selectedFilter == 'Sudah Diringkas') return l['status'] == 'Summarized';
                      if (_selectedFilter == 'Menunggu AI') return l['status'] != 'Summarized';
                      return true;
                    }).toList();

                    if (filteredLectures.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("Tidak ada sesi yang sesuai filter.", style: TextStyle(color: AppTheme.outlineVariant)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredLectures.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final lecture = filteredLectures[index];
                        final duration = lecture['duration_minutes'] ?? 0;
                        String dur = (duration > 0) ? "$duration menit" : "Baru";
                        String status = lecture['status'] ?? 'Unknown';
                        Color statusColor = status == 'Summarized' ? AppTheme.primary : AppTheme.tertiary;
                        bool pulseBg = status == 'Summarized';
                        
                        return _buildLectureItem(
                          context,
                          'Lecture',
                          lecture['lecture_date'] ?? 'No Date',
                          lecture['title'] ?? 'Untitled',
                          dur,
                          status,
                          statusColor,
                          pulseBg,
                          lecture['id'],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLectureItem(BuildContext context, String week, String date, String title, String dur, String status, Color statusColor, bool pulseBg, String lectureId) {
    return GestureDetector(
      onTap: () {
        if (status == 'Summarized') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => LectureSummaryView(lectureId: lectureId)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: pulseBg ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]) : null,
              color: pulseBg ? null : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.play_arrow, color: pulseBg ? Colors.white : AppTheme.onSurfaceVariant, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(week.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.outlineVariant, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(date, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(dur, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                      child: Row(
                        children: [
                          Icon(pulseBg ? Icons.auto_awesome : Icons.pending, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(status == 'Summarized' ? 'Diringkas' : status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )); // Container and GestureDetector
  }
}

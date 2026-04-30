import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
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
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppTheme.surface,
                  surfaceTintColor: AppTheme.surface,
                  pinned: true,
                  elevation: 0,
                  leadingWidth: isDesktop ? 80 : 56,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Row(
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
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATA KULIAH',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: isDesktop ? 48 : 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ringkasan dan materi kuliah untuk ${widget.title}.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: isDesktop ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      final summarizedCount = provider.lectures.where((l) => l['status'] == 'Summarized').length;
                      final totalSavedMinutes = summarizedCount * 25;
                      final hoursSaved = (totalSavedMinutes / 60).toStringAsFixed(1);

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                '${hoursSaved}j',
                                'Waktu Hemat',
                                AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                '${(provider.courseStats[widget.courseId] ?? 0).toStringAsFixed(0)}%',
                                'Skor Kuis',
                                AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua'),
                          const SizedBox(width: 12),
                          _buildFilterChip('Menunggu AI'),
                          const SizedBox(width: 12),
                          _buildFilterChip('Sudah Diringkas'),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                  sliver: Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const SliverToBoxAdapter(
                          child: Center(child: Padding(
                            padding: EdgeInsets.all(64.0),
                            child: CircularProgressIndicator(),
                          )),
                        );
                      }
                      
                      final filteredLectures = provider.lectures.where((l) {
                        if (_selectedFilter == 'Semua') return true;
                        if (_selectedFilter == 'Sudah Diringkas') return l['status'] == 'Summarized';
                        if (_selectedFilter == 'Menunggu AI') return l['status'] != 'Summarized';
                        return true;
                      }).toList();

                      if (filteredLectures.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(64.0),
                              child: Text("Belum ada materi kuliah.", style: TextStyle(color: AppTheme.outlineVariant)),
                            ),
                          ),
                        );
                      }

                      if (isDesktop) {
                        return SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 32,
                            mainAxisSpacing: 32,
                            mainAxisExtent: 140,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildLectureItemWrapper(context, filteredLectures[index]),
                            childCount: filteredLectures.length,
                          ),
                        );
                      } else {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildLectureItemWrapper(context, filteredLectures[index]),
                            ),
                            childCount: filteredLectures.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildLectureItemWrapper(BuildContext context, Map<String, dynamic> lecture) {
    final duration = lecture['duration_minutes'] ?? 0;
    String dur = "${duration}m";
    String status = lecture['status'] ?? 'Unknown';
    Color statusColor = status == 'Summarized' ? AppTheme.primary : AppTheme.tertiary;
    bool pulseBg = status == 'Summarized';

    return _buildLectureItem(
      context,
      'Materi',
      lecture['lecture_date'] ?? 'No Date',
      lecture['title'] ?? 'Untitled',
      dur,
      status,
      statusColor,
      pulseBg,
      lecture['id'],
    );
  }

  void _showDeleteConfirmation(BuildContext context, String lectureId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Materi?'),
        content: Text('Apakah kamu yakin ingin menghapus "$title"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              Navigator.pop(context);
              await provider.deleteLecture(lectureId);
              if (provider.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!), backgroundColor: Colors.red));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materi berhasil dihapus'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRenameLectureDialog(BuildContext context, String lectureId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Judul Materi'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan judul baru',
            filled: true,
            fillColor: AppTheme.surfaceContainerHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final provider = Provider.of<AppProvider>(context, listen: false);
                await provider.updateLectureTitle(lectureId, controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showLectureOptions(BuildContext context, String lectureId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
              ),
              title: const Text('Edit Judul Materi', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showRenameLectureDialog(context, lectureId, title);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.share_rounded, color: AppTheme.primary),
              ),
              title: const Text('Bagikan Kode Akses', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Berikan kode ke teman untuk impor materi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LectureSummaryView(lectureId: lectureId),
                ));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: const Text('Hapus Materi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              subtitle: const Text('Hapus permanen rangkuman, kuis, & kartu'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, lectureId, title);
              },
            ),
            const SizedBox(height: 16),
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
      onLongPress: () {
        _showLectureOptions(context, lectureId, title);
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

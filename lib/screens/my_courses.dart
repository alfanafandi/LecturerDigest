import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/course_detail.dart';
import 'package:lecturer_digest/screens/profile_screen.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';

class MyCourses extends StatelessWidget {
  const MyCourses({super.key});

  void _showAddCourseDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String selectedDay = 'Senin';
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Tambah Mata Kuliah Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Mata Kuliah',
                    hintText: 'misal: Pemrograman C++',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Hari Perkuliahan',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: days.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedDay = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Provider.of<AppProvider>(context, listen: false).addCourse(
                      nameController.text,
                      selectedDay,
                      '#006b5c', // Default color
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                    Consumer<AppProvider>(
                      builder: (context, provider, child) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.5), width: 2),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                            child: provider.userProfile?['avatar_url'] != null
                                ? ClipOval(
                                    child: Image.asset(
                                      provider.userProfile!['avatar_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded, 
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RUANG AKADEMIK',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.0,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelas',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelola kurikulum dan ringkasan kuliah berbasis AI Anda.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Search & Add
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari mata kuliah...',
                                prefixIcon: Icon(Icons.search, color: AppTheme.outlineVariant),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showAddCourseDialog(context),
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryContainer],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Course Grids
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
                    if (provider.courses.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            const Icon(Icons.school_outlined, size: 48, color: AppTheme.outlineVariant),
                            const SizedBox(height: 16),
                            const Text('Mata kuliah tidak ditemukan', style: TextStyle(color: AppTheme.outlineVariant)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddCourseDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Kelas Pertama Anda'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.courses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildDynamicCourseCard(context, provider.courses[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCourseCard(BuildContext context, Map<String, dynamic> course) {
    Color cardColor = AppTheme.primary;
    if (course['color_hex'] != null) {
      try {
        cardColor = Color(int.parse(course['color_hex'].replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback
      }
    }

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Find lectures for this course
        final courseLectures = provider.lectures.where((l) => l['course_id'] == course['id']).toList();
        final lectureCount = courseLectures.length;
        
        // Find last activity
        String lastActivity = 'Belum ada';
        if (courseLectures.isNotEmpty) {
          // Sort by date (descending)
          courseLectures.sort((a, b) => (b['lecture_date'] ?? '').compareTo(a['lecture_date'] ?? ''));
          lastActivity = courseLectures.first['lecture_date'] ?? 'Baru saja';
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CourseDetail(
                    courseId: course['id'],
                    title: course['name'],
                    color: cardColor)));
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(32),
              border:
                  Border.all(color: AppTheme.outlineVariant.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.psychology, color: cardColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mic, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text('AI Aktif',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(course['name'] ?? 'Tanpa Nama',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(course['schedule'] ?? 'Tidak ada jadwal',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rekaman',
                              style: TextStyle(
                                  color: AppTheme.outlineVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$lectureCount Rekaman',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Aktivitas Terakhir',
                              style: TextStyle(
                                  color: AppTheme.outlineVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(lastActivity,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.onSurfaceVariant)),
                        ],
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

  Widget _buildCompactCourseCard(BuildContext context, String title, String desc, String stat1, String stat2, IconData icon, Color iconColor, Color bgIconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          const Divider(thickness: 1, color: AppTheme.surfaceContainerHighest),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(stat1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              Expanded(child: Text(stat2, style: TextStyle(color: AppTheme.outlineVariant, fontSize: 11), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListCourseCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sistem Operasi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Text('SESI AKTIF', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Concurrency, scheduling, and file system management.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.description, size: 16, color: AppTheme.outlineVariant),
                        SizedBox(width: 6),
                        Text('10 Rekaman', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: const [
                        Icon(Icons.schedule, size: 16, color: AppTheme.outlineVariant),
                        SizedBox(width: 6),
                        Text('Kemarin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5))),
            child: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/course_detail.dart';
import 'package:lecturer_digest/screens/profile_screen.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';

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

  void _showDeleteConfirmation(BuildContext context, String courseId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Kelas?'),
        content: Text('Apakah kamu yakin ingin menghapus "$title"? Semua materi, kuis, dan kartu di dalam kelas ini juga akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              Navigator.pop(context);
              await provider.deleteCourse(courseId);
              if (provider.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!), backgroundColor: Colors.red));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas berhasil dihapus'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRenameCourseDialog(BuildContext context, String courseId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ubah Nama Kelas'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan nama kelas baru',
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
                await provider.updateCourseName(courseId, controller.text);
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

  void _showCourseOptions(BuildContext context, String courseId, String title) {
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
                child: const Icon(Icons.edit_rounded, color: AppTheme.primary),
              ),
              title: const Text('Ubah Nama Kelas', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showRenameCourseDialog(context, courseId, title);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: const Text('Hapus Kelas', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              subtitle: const Text('Hapus permanen seluruh materi di kelas ini'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, courseId, title);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: CustomScrollView(
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 16),
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
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                                child: provider.userProfile?['avatar_url'] != null
                                    ? ClipOval(
                                        child: provider.userProfile!['avatar_url'].startsWith('http')
                                            ? Image.network(
                                                provider.userProfile!['avatar_url'],
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
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
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelas',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: isDesktop ? 48 : 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search & Add
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHighest.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Cari mata kuliah...',
                                    prefixIcon: Icon(Icons.search, color: AppTheme.outlineVariant),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _showAddCourseDialog(context),
                              child: Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
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
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                  sliver: Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const SliverToBoxAdapter(
                          child: Center(child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          )),
                        );
                      }
                      if (provider.courses.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 64),
                                const Icon(Icons.school_outlined, size: 64, color: AppTheme.outlineVariant),
                                const SizedBox(height: 16),
                                const Text('Mata kuliah tidak ditemukan', style: TextStyle(color: AppTheme.outlineVariant)),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddCourseDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Kelas Pertama Anda'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (isDesktop) {
                        return SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 90,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildDynamicCourseCard(context, provider.courses[index]),
                            childCount: provider.courses.length,
                          ),
                        );
                      } else {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDynamicCourseCard(context, provider.courses[index]),
                            ),
                            childCount: provider.courses.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
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

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CourseDetail(
                    courseId: course['id'],
                    title: course['name'],
                    color: cardColor)));
          },
          onLongPress: () {
            _showCourseOptions(context, course['id'], course['name'] ?? 'Tanpa Nama');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.school_outlined, color: cardColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        course['name'] ?? 'Tanpa Nama',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course['schedule'] ?? 'Tidak ada jadwal'} • $lectureCount Rekaman',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 12, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        'AI Aktif',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.outlineVariant),
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

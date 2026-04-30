import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/flashcards_review.dart';
import 'package:lecturer_digest/screens/search_screen.dart';
import 'package:lecturer_digest/screens/lecture_summary_view.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/screens/profile_screen.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.fetchAllLectures();
      provider.fetchCourses();
      provider.fetchDueFlashcards();
    });
  }

  void _showCoursePicker(BuildContext context, String? currentId, Function(String) onSelected) {
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
            const Text('Pilih Mata Kuliah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.courses.length,
                    itemBuilder: (context, index) {
                      final course = provider.courses[index];
                      final isSelected = course['id'] == currentId;
                      return ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        title: Text(course['name'] ?? '', style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primary : AppTheme.onBackground,
                        )),
                        onTap: () {
                          onSelected(course['id'] as String);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportBottomSheet(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    String? selectedCourseId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 32,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Impor Materi Teman', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Masukkan kode materi yang dibagikan temanmu untuk menyalin rangkuman, kuis, dan flashcard mereka.', 
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                const Text('KODE AKSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: LD-123XYZ',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerHigh,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                ),
                const SizedBox(height: 24),
                const Text('PILIH MATA KULIAH TUJUAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 8),
                
                // CUSTOM PICKER (More stable than Dropdown with keyboard)
                Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    final selectedCourse = provider.courses.cast<Map<String, dynamic>?>().firstWhere(
                      (c) => c?['id'] == selectedCourseId, 
                      orElse: () => null
                    );
                    
                    return GestureDetector(
                      onTap: () {
                        // Dismiss keyboard before showing picker
                        FocusScope.of(context).unfocus();
                        _showCoursePicker(context, selectedCourseId, (val) {
                          setModalState(() {
                            selectedCourseId = val;
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedCourse?['name'] ?? 'Pilih mata kuliah',
                              style: TextStyle(
                                color: selectedCourse != null ? AppTheme.onBackground : Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        onPressed: provider.isLoading ? null : () async {
                          if (codeController.text.isEmpty || selectedCourseId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi kode dan pilih mata kuliah')));
                            return;
                          }
                          
                          final success = await provider.importSharedLecture(codeController.text, selectedCourseId!);
                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materi berhasil diimpor!'), backgroundColor: Colors.green));
                          } else if (provider.error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!), backgroundColor: Colors.red));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: provider.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Impor Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
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

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: _buildMobileLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
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
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
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
            
            // Greeting Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    final user = provider.currentUser;
                    final profile = provider.userProfile;
                    
                    String displayName = 'Mahasiswa';
                    if (profile != null && profile['full_name'] != null && profile['full_name'].toString().isNotEmpty) {
                      displayName = profile['full_name'];
                    } else if (user?.email != null) {
                      final emailPrefix = user!.email!.split('@')[0];
                      displayName = emailPrefix[0].toUpperCase() + emailPrefix.substring(1);
                    }

                    return Column(
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
                          'Halo, $displayName!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppTheme.primary.withOpacity(0.5)),
                        const SizedBox(width: 12),
                        const Text(
                          'Cari materi atau topik...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mata Kuliah',
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
                    GestureDetector(
                      onTap: () => _showImportBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.download_rounded, size: 16, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              'Impor Materi',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

            // AI Study Radar Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radar_rounded, color: AppTheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'AI Study Radar',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Materi yang perlu kamu review hari ini',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // AI Study Radar Content
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                // Logic to find lectures needing review
                final dueLectureIds = provider.dueFlashcards.map((f) => f['lecture_id'] as String).toSet();
                final priorityLectures = provider.lectures.where((l) => dueLectureIds.contains(l['id'])).toList();

                if (priorityLectures.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green),
                            const SizedBox(height: 16),
                            const Text(
                              'Semua Terkejar!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Belum ada materi yang perlu direview mendesak. Kerja bagus!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final lecture = priorityLectures[index];
                      final dueCount = provider.dueFlashcards.where((f) => f['lecture_id'] == lecture['id']).length;
                      
                      // Find course name
                      final course = provider.courses.firstWhere(
                        (c) => c['id'] == lecture['course_id'], 
                        orElse: () => {'name': 'Umum'}
                      );

                      return _buildRadarCard(
                        context,
                        lecture['id'],
                        course['name'],
                        lecture['title'],
                        '$dueCount Kartu Hafalan perlu diulas',
                        AppTheme.primary,
                      );
                    },
                    childCount: priorityLectures.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desktop Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
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
                  Text(
                    'DASHBOARD OVERVIEW',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      final user = provider.currentUser;
                      final profile = provider.userProfile;
                      String displayName = profile?['full_name'] ?? user?.email?.split('@')[0] ?? 'Mahasiswa';
                      return Text(
                        'Selamat datang kembali, $displayName!',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda telah menyintesis 12 jam kuliah informatika minggu ini. Siap untuk Sistem Basis Data hari ini?',
                    style: TextStyle(fontSize: 18, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                        label: const Text('Mulai Rekam', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          side: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
                        ),
                        child: const Text('Lihat Analitik', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Main Content Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Stats & Summaries
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildDesktopStatCard(
                              context,
                              Icons.menu_book_rounded,
                              'Materi Hari Ini',
                              '3 Sesi',
                              AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDesktopStatCard(
                              context,
                              Icons.quiz_rounded,
                              'Kartu Hafalan',
                              '42 Pending',
                              AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Recent Summaries Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rangkuman Terbaru',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bento Grid Style for Summaries
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          if (provider.lectures.isEmpty) {
                            return const Center(child: Text('Belum ada materi.'));
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              mainAxisExtent: 250,
                            ),
                            itemCount: provider.lectures.length > 4 ? 4 : provider.lectures.length,
                            itemBuilder: (context, index) {
                              final lecture = provider.lectures[index];
                              return _buildSummaryCard(
                                context,
                                lecture['id'],
                                'Informatika',
                                '2 jam yang lalu',
                                lecture['title'],
                                lecture['raw_transcript'] ?? '',
                                'Selesai',
                                AppTheme.primary.withOpacity(0.1),
                                AppTheme.primary,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),

                // Right Column: Schedule & AI Pulse
                Expanded(
                  child: Column(
                    children: [
                      // Schedule Panel
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('Jadwal Hari Ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                                SizedBox(width: 8),
                                Text('24 Okt, 2023', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildScheduleItem('09:00 - 10:30', 'Rekayasa Perangkat Lunak', 'Gedung B • R.402', AppTheme.primary),
                            _buildScheduleItem('11:00 - 12:30', 'Jaringan Komputer', 'Lab Digital • Zoom', AppTheme.secondary),
                            _buildScheduleItem('14:00 - 15:30', 'Interaksi Manusia & Komputer', 'Aula Seminar', Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // AI Pulse Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.onPrimaryContainer, AppTheme.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 32),
                            const SizedBox(height: 16),
                            const Text(
                              'Saran AI',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Anda sudah belajar "Sistem Terdistribusi" selama 4 jam. Ambil istirahat 15 menit untuk daya ingat lebih baik.',
                              style: TextStyle(color: Colors.white70, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.15),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Set Timer Pomodoro'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 24),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String title, String loc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(loc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label, Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (label.contains('Kartu')) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardsReview()));
        } else if (label.contains('Materi')) {
          final today = DateTime.now().toIso8601String().split('T')[0];
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: today)));
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
      onLongPress: () {
        _showLectureOptions(context, lectureId, title);
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

  Widget _buildRadarCard(
    BuildContext context,
    String lectureId,
    String courseName,
    String title,
    String reason,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.psychology_outlined, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.notification_important_rounded, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FlashcardsReview(lectureId: lectureId),
              ));
            },
            onLongPress: () {
              _showLectureOptions(context, lectureId, title);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

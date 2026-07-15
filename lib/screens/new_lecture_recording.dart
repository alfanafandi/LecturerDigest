import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/core/services/document_service.dart';
import 'package:lecturer_digest/screens/lecture_summary_view.dart';

class NewLectureRecording extends StatefulWidget {
  const NewLectureRecording({super.key});

  @override
  State<NewLectureRecording> createState() => _NewLectureRecordingState();
}

class _NewLectureRecordingState extends State<NewLectureRecording> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedCourseId;
  final TextEditingController _titleController = TextEditingController();
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isPaused = false;
  bool _isMuted = false;
  bool _hasStartedAction = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = "Sesi Kuliah ${DateTime.now().day}/${DateTime.now().month}";
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    
    // Auto-selection removed to allow user choice.
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _startRecording() {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _hasStartedAction = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.startRecording().then((_) {
      _runTimer();
    });
  }

  void _handleAutoStopRecording() async {
    _timer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas maksimal durasi 45 menit tercapai. Rekaman dihentikan otomatis untuk diproses AI. Silakan buat sesi baru untuk melanjutkan.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
    await _handleStopRecording();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        bool thresholdReached = false;
        setState(() {
          _secondsElapsed++;
          if (_secondsElapsed >= 2700) { // 45 minutes
            thresholdReached = true;
          }
        });
        if (thresholdReached) {
          _handleAutoStopRecording();
        }
      }
    });
  }

  void _togglePause() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pulseController.stop();
        provider.pauseRecording();
      } else {
        _pulseController.repeat();
        provider.resumeRecording();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Visual only for now, can be extended if provider supports audio gain control
  }

  String _formatDuration(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}:00"; // Mocking ms
  }

  Future<void> _handleStopRecording() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // 1. Stop Recording first
    _timer?.cancel();
    final audioPath = await provider.stopRecording();

    // UX Guard: If recording is too short (less than 5 seconds), cancel it
    if (_secondsElapsed < 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rekaman terlalu pendek kurang dari 5 detik dan telah dibatalkan.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _hasStartedAction = false;
          _secondsElapsed = 0;
          _isPaused = false;
        });
      }
      return;
    }
    
    if (audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil file rekaman')));
      return;
    }

    // 2. Show Loading Overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI sedang merangkum materi...', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Ini mungkin memakan waktu 10-20 detik.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    // 3. Process with real audio path and duration
    final durationMinutes = (_secondsElapsed / 60).ceil();
    final lectureId = await provider.processLectureRecording(
      _selectedCourseId!,
      _titleController.text,
      audioPath,
      durationMinutes,
    );

    // Close Loading Dialog
    if (mounted) Navigator.pop(context);

    if (provider.error != null || lectureId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Terjadi kesalahan saat memproses AI.'), backgroundColor: Colors.red),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi berhasil disimpan & dirangkum oleh AI!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LectureSummaryView(lectureId: lectureId),
          ),
        );
      }
    }
  }

  Future<void> _handleUploadMaterial() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final docService = DocumentService();

    // 1. Pick PDF
    final file = await docService.pickPDF();
    if (file == null) return; // User cancelled

    // 2. Show Loading Overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI sedang membaca dokumen...', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Ini mungkin memakan waktu 10-20 detik.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    // 3. Process Document
    final lectureId = await provider.processDocument(
      _selectedCourseId!,
      _titleController.text,
      file,
    );

    // Close Loading Dialog
    if (mounted) Navigator.pop(context);

    if (provider.error != null || lectureId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Terjadi kesalahan saat memproses dokumen.'), 
            backgroundColor: (provider.error != null && provider.error!.contains('halaman')) ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokumen berhasil diunggah & dirangkum oleh AI!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LectureSummaryView(lectureId: lectureId),
          ),
        );
      }
    }
  }

  // Intercept back navigation saat sedang merekam
  Future<bool> _onWillPop() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.isRecording && !_hasStartedAction) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.mic_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sedang Merekam',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Keluar sekarang akan membatalkan rekaman. Lanjutkan?',
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tetap', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLeave == true) {
      // Stop recorder tanpa menyimpan sebelum keluar
      _timer?.cancel();
      await provider.stopRecording();
      provider.clearError();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) navigator.pop();
      },
      child: Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.background.withOpacity(0.9),
        elevation: 0,
        leadingWidth: isDesktop ? 80 : 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) navigator.pop();
          },
        ),
        title: Row(
          children: [
            const BrandLogo(size: 28),
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SESI REKAMAN', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text('Mulai Sesi Baru', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: isDesktop ? 48 : 36)),
                const SizedBox(height: 16),
                
                // UX Guard: No courses warning
                Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    if (provider.courses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1), 
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)), 
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA000), size: 32), 
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Anda belum memiliki mata kuliah.',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF795548), fontSize: 16), 
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Buat mata kuliah pertama Anda untuk mulai menyimpan rekaman kuliah atau rangkuman AI.',
                              style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63), height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  provider.setTabIndex(1);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA000), 
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Tambah Mata Kuliah Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                const SizedBox(height: 32),
                const Text('JUDUL KULIAH', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                    hintText: 'Masukkan judul kuliah...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 32),
                const Text('PILIH MATA KULIAH', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCourseId,
                          hint: const Text('Pilih mata kuliah untuk sesi ini'),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 16),
                          items: provider.courses.map((course) {
                            return DropdownMenuItem<String>(
                              value: course['id'], 
                              child: Text(course['name'] ?? 'Mata Kuliah')
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() { _selectedCourseId = val; });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),
                
                if (!_hasStartedAction) ...[
                  const Text('PILIH METODE INPUT', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.mic_rounded,
                          title: 'Rekam Live',
                          description: 'Rekam suara dosen langsung.',
                          color: AppTheme.primary,
                          onTap: _startRecording,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.cloud_upload_rounded,
                          title: 'Upload PDF',
                          description: 'Rangkum dari dokumen PDF.',
                          color: AppTheme.secondary,
                          onTap: _handleUploadMaterial,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // RECORDING UI
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_secondsElapsed), 
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900, 
                            letterSpacing: -2,
                            color: AppTheme.onSurface,
                          )
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10, 
                              height: 10, 
                              decoration: BoxDecoration(
                                color: _isPaused ? AppTheme.outlineVariant : Colors.red, 
                                shape: BoxShape.circle
                              )
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isPaused ? 'REKAMAN DIJEDA' : 'SEDANG MEREKAM...', 
                              style: TextStyle(
                                color: _isPaused ? AppTheme.outlineVariant : Colors.red, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 12, 
                                letterSpacing: 1.5
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 64),
                        SizedBox(
                          height: 240,
                          width: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!_isPaused) AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 160 + (_pulseController.value * 80),
                                    height: 160 + (_pulseController.value * 80),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.primary.withOpacity(0.2 * (1 - _pulseController.value)), width: 4),
                                    ),
                                  );
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  final provider = Provider.of<AppProvider>(context, listen: false);
                                  if (provider.courses.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error: Tidak ada mata kuliah terpilih!'))
                                    );
                                  } else {
                                    _handleStopRecording();
                                  }
                                },
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFff5252), Color(0xFFd32f2f)]
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 32, offset: const Offset(0, 12))
                                    ],
                                  ),
                                  child: const Icon(Icons.stop_rounded, color: Colors.white, size: 56),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 64),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCircleButton(
                              onTap: _togglePause,
                              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              label: _isPaused ? 'LANJUT' : 'JEDA',
                              isActive: _isPaused,
                            ),
                            const SizedBox(width: 48),
                            _buildCircleButton(
                              onTap: _toggleMute,
                              icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              label: _isMuted ? 'UNMUTE' : 'MUTE',
                              isActive: _isMuted,
                              isDanger: _isMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('STATUS PROSES AI', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 12, letterSpacing: 1.0)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
                        child: const Text('AKTIF', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900))
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      String message = 'Siap untuk memproses materi.';
                      if (provider.isRecording) message = 'AI sedang mendengarkan dan menyiapkan transkrip...';
                      else if (provider.isLoading) message = 'AI sedang menganalisis materi dan membuat rangkuman...';
                      
                      return Text(
                        message,
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.tertiary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.tertiary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Catatan: Batas maksimal durasi rekaman kuliah adalah 45 menit agar proses AI tetap cepat dan hemat token. Silakan buat sesi baru jika ingin melanjutkan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required VoidCallback onTap, required IconData icon, required String label, bool isActive = false, bool isDanger = false}) {
    Color baseColor = isDanger ? Colors.red : AppTheme.primary;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isActive ? baseColor.withOpacity(0.15) : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: isActive ? Border.all(color: baseColor.withOpacity(0.5), width: 2) : null,
            ),
            child: Icon(icon, color: isActive ? baseColor : AppTheme.onSurface, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? baseColor : AppTheme.outlineVariant, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String description, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1), width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

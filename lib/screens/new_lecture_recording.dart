import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/services/document_service.dart';
import 'dart:io';

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

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _secondsElapsed++;
        });
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
    await provider.processLectureRecording(
      _selectedCourseId!,
      _titleController.text,
      audioPath,
      durationMinutes,
    );

    // Close Loading Dialog
    if (mounted) Navigator.pop(context);

    if (provider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi berhasil disimpan & dirangkum oleh AI!')),
        );
        Navigator.pop(context); // Return to Dashboard
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
    await provider.processDocument(
      _selectedCourseId!,
      _titleController.text,
      file,
    );

    // Close Loading Dialog
    if (mounted) Navigator.pop(context);

    if (provider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!), 
            backgroundColor: provider.error!.contains('halaman') ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokumen berhasil diunggah & dirangkum oleh AI!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SESI REKAMAN', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text('Mulai Rekam Kuliah', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            
            // UX Guard: No courses warning
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                if (provider.courses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)), 
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA000)), 
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Anda belum memiliki mata kuliah.',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF795548)), 
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Buat mata kuliah pertama Anda untuk mulai menyimpan rekaman kuliah.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            provider.setTabIndex(1); // Go to Classes tab
                            Navigator.pop(context); // Go back to wrapper
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Silakan klik ikon + untuk menambah mata kuliah baru.'))
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA000), 
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Tambah Mata Kuliah'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            const SizedBox(height: 24),
            const Text('JUDUL KULIAH', style: TextStyle(color: AppTheme.outlineVariant, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('PILIH MATA KULIAH', style: TextStyle(color: AppTheme.outlineVariant, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCourseId,
                      hint: const Text('Pilih mata kuliah'),
                      icon: const Icon(Icons.expand_more, color: AppTheme.primary),
                      items: provider.courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'], 
                          child: Text(course['name'] ?? 'Mata Kuliah', style: const TextStyle(fontWeight: FontWeight.w500))
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
            const SizedBox(height: 24),
            
            if (!_hasStartedAction) ...[
              // THE SELECTION SCREEN
              const Text('PILIH SUMBER MATERI', style: TextStyle(color: AppTheme.outlineVariant, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.mic,
                      title: 'Rekam Live',
                      description: 'Rekam suara dosen langsung dari kelas.',
                      color: AppTheme.primary,
                      onTap: _startRecording,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.upload_file,
                      title: 'Upload PDF',
                      description: 'AI akan merangkum dari file dokumen.',
                      color: AppTheme.secondary,
                      onTap: _handleUploadMaterial,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Isi data di atas dan pilih sumber materi untuk memulai.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ] else ...[
              // THE RECORDING UI
              Center(
                child: Column(
                  children: [
                    Text(_formatDuration(_secondsElapsed), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text('SEDANG MEREKAM', style: TextStyle(color: AppTheme.outlineVariant, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 150 + (_pulseController.value * 50),
                                height: 150 + (_pulseController.value * 50),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.3 * (1 - _pulseController.value)), width: 4),
                                ),
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              final provider = Provider.of<AppProvider>(context, listen: false);
                              if (provider.courses.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Peringatan: Tidak bisa menyimpan tanpa mata kuliah!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                _handleStopRecording();
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: Provider.of<AppProvider>(context).courses.isEmpty 
                                    ? [Colors.grey, Colors.blueGrey] 
                                    : [const Color(0xFFff5252), const Color(0xFFd32f2f)]
                                ),
                                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20)],
                              ),
                              child: const Icon(Icons.stop, color: Colors.white, size: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _togglePause,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: _isPaused ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceContainerHigh, 
                                    borderRadius: BorderRadius.circular(16),
                                    border: _isPaused ? Border.all(color: AppTheme.primary) : null,
                                ),
                                child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: _isPaused ? AppTheme.primary : AppTheme.onSurface),
                              ),
                              const SizedBox(height: 8),
                              Text(_isPaused ? 'LANJUT' : 'JEDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isPaused ? AppTheme.primary : AppTheme.outlineVariant)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: _toggleMute,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: _isMuted ? Colors.red.withOpacity(0.1) : AppTheme.surfaceContainerHigh, 
                                    borderRadius: BorderRadius.circular(16),
                                    border: _isMuted ? Border.all(color: Colors.red.withOpacity(0.5)) : null,
                                ),
                                child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : AppTheme.onSurface),
                              ),
                              const SizedBox(height: 8),
                              Text('MUTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isMuted ? Colors.red : AppTheme.outlineVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TRANSKRIP REAL-TIME', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('AI AKTIF', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.isRecording) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sedang menangkap audio...', style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('AI sedang mendengarkan materi kuliah Anda. Transkrip lengkap akan diproses secara otomatis segera setelah Anda menekan tombol merah.', style: TextStyle(color: AppTheme.onSurface.withOpacity(0.6))),
                      ],
                    );
                  } else if (provider.isLoading) {
                    return const Text('Sedang mengolah transkrip dan rangkuman...', style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.secondary));
                  } else {
                    return const Text('Siap untuk merekam sesi baru.', style: TextStyle(color: Colors.grey));
                  }
                },
              ),
            ],
          ],
        ),
      ),
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

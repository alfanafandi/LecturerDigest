import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController.text = "Lecture Session ${DateTime.now().day}/${DateTime.now().month}";
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    
    // Auto-select first course if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final courses = provider.courses;
      if (courses.isNotEmpty) {
        setState(() {
          _selectedCourseId = courses.first['id'];
        });
      }
      
      // Start recording immediately if courses exist
      if (courses.isNotEmpty) {
        _startRecording();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _startRecording() {
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

    // 3. Process with real audio path
    await provider.processLectureRecording(
      _selectedCourseId!,
      _titleController.text,
      audioPath,
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Anda belum memiliki mata kuliah.',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Buat mata kuliah pertama Anda untuk mulai menyimpan rekaman kuliah.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to My Courses or show Add Dialog (for simplicity, we'll suggest going back)
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Buka menu "Kelas Saya" untuk menambah mata kuliah baru.'))
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
            const SizedBox(height: 48),
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
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement file picker
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file, color: AppTheme.primary),
                          SizedBox(width: 12),
                          Text('Upload PPT / PDF Material', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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
        ),
      ),
    );
  }
}

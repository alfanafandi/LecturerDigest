import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/flashcards_review.dart';
import 'package:lecturer_digest/screens/ask_ai_chat.dart';
import 'package:lecturer_digest/screens/quiz_screen.dart';
import 'package:lecturer_digest/screens/quiz_review_screen.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/services/pdf_service.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';

class LectureSummaryView extends StatefulWidget {
  final String lectureId;
  const LectureSummaryView({super.key, required this.lectureId});

  @override
  State<LectureSummaryView> createState() => _LectureSummaryViewState();
}

class _LectureSummaryViewState extends State<LectureSummaryView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _tabScrollController = ScrollController();
  bool _isPlayerReady = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _activeTab = 'Poin Penting';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.fetchSummary(widget.lectureId);
      await provider.fetchQuizzes(widget.lectureId);
      await provider.fetchLatestQuizAttempt(widget.lectureId);

      // Micro-animation to hint horizontal scrollability of tabs
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_tabScrollController.hasClients) {
          _tabScrollController.animateTo(
            40.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          ).then((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_tabScrollController.hasClients) {
                _tabScrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              }
            });
          });
        }
      });

      // Load audio if path exists in lecture details
      String? audioPath = provider.currentLectureDetails?['audio_url'];
      print('DEBUG: Mencoba memuat audio dari path: $audioPath');
      
      if (audioPath != null) {
        String cleanPath = audioPath.startsWith('file://') 
            ? audioPath.replaceFirst('file://', '') 
            : audioPath;
            
        if (cleanPath.startsWith('file:')) {
          cleanPath = cleanPath.replaceFirst('file:', '');
        }

        if (File(cleanPath).existsSync()) {
          try {
            print('DEBUG: File ditemukan, menyiapkan player...');
            await _audioPlayer.setFilePath(cleanPath);
            
            if (mounted) {
              setState(() {
                _isPlayerReady = true;
                _duration = _audioPlayer.duration ?? Duration.zero;
              });
            }

            _audioPlayer.durationStream.listen((d) {
              if (mounted) setState(() => _duration = d ?? Duration.zero);
            });

            _audioPlayer.positionStream.listen((p) {
              if (mounted) setState(() => _position = p);
            });

            _audioPlayer.playerStateStream.listen((state) {
              if (mounted) setState(() => _isPlaying = state.playing);
            });
          } catch (e) {
            print('DEBUG: Error saat setFilePath: $e');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showShareDialog(BuildContext context, AppProvider provider, String lectureId) async {
    final code = await provider.getShareCode(lectureId);
    if (code == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: AppTheme.primary),
            SizedBox(width: 12),
            Text('Bagikan Materi', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan kode ini kepada temanmu agar mereka bisa mengimpor materi ini ke akun mereka.', 
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Kode ini berlaku selamanya.', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode berhasil disalin ke clipboard!')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salin Kode'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final summary = provider.currentSummary;
        final lectureDetails = provider.currentLectureDetails;

        if (provider.isLoading || summary == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final keyTakeawaysObj = summary['key_takeaways'] ?? {};
        final takeaways = keyTakeawaysObj['takeaways'] is List ? keyTakeawaysObj['takeaways'] as List<dynamic> : [];
        final outline = keyTakeawaysObj['outline'] is List ? keyTakeawaysObj['outline'] as List<dynamic> : [];
        final glossary = keyTakeawaysObj['glossary'] is List ? keyTakeawaysObj['glossary'] as List<dynamic> : [];
        final studyQuestions = keyTakeawaysObj['study_questions'] is List ? keyTakeawaysObj['study_questions'] as List<dynamic> : [];

        final List<Widget> activeButtons = [
          _buildActionButton(
            context,
            onPressed: () async {
              if (provider.currentQuizzes.isEmpty) {
                _showQuizConfigSheet(context, provider);
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizScreen(
                        lectureId: widget.lectureId)));
              }
            },
            icon: provider.currentQuizzes.isEmpty
                ? Icons.psychology_outlined
                : Icons.quiz_outlined,
            label: provider.currentQuizzes.isEmpty
                ? 'Buat Kuis'
                : 'Kuis AI',
            color: provider.currentQuizzes.isEmpty
                ? AppTheme.tertiary
                : AppTheme.primary,
            isLoading: provider.isLoading,
          ),
          _buildActionButton(
            context,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FlashcardsReview(
                      lectureId: widget.lectureId)));
            },
            icon: Icons.style_outlined,
            label: 'Kartu',
            color: AppTheme.secondary,
          ),
          _buildActionButton(
            context,
            onPressed: () {
              provider.setChatLecture(widget.lectureId);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AskAiChat()));
            },
            icon: Icons.auto_awesome_outlined,
            label: 'Chat AI',
            color: AppTheme.primary,
          ),
          if (provider.latestQuizAttempt != null)
            _buildActionButton(
              context,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuizReviewScreen(
                        lectureId: widget.lectureId)));
              },
              icon: Icons.history_edu_outlined,
              label: 'Hasil',
              color: AppTheme.secondary,
            ),
          _buildActionButton(
            context,
            onPressed: () async {
              final path = await provider.exportLectureSummary();
              if (path != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('PDF Berhasil disimpan!'),
                      action: SnackBarAction(
                        label: 'BUKA',
                        onPressed: () => PdfService.openFile(path),
                      ),
                    ),
                  );
                }
              } else if (provider.error != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error!))
                  );
                }
              }
            },
            icon: Icons.picture_as_pdf_outlined,
            label: 'Simpan PDF',
            color: AppTheme.tertiary,
            isLoading: provider.isLoading,
          ),
        ];

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
                Text('LectureDigest',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.share_rounded, color: AppTheme.primary),
                  onPressed: () => _showShareDialog(context, provider, widget.lectureId)),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.isDesktop(context) ? MediaQuery.of(context).size.width * 0.15 : 24,
                  vertical: 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('RINGKASAN AKADEMIK',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(lectureDetails?['title'] ?? 'Lecture Summary',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.onSurface,
                                letterSpacing: -1)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: AppTheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text(lectureDetails?['lecture_date'] ?? '-',
                            style: const TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(child: activeButtons[0]),
                              const SizedBox(width: 12),
                              Expanded(child: activeButtons[1]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: activeButtons[2]),
                              const SizedBox(width: 12),
                              Expanded(child: activeButtons[3]),
                            ],
                          ),
                          if (activeButtons.length > 4) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: activeButtons[4]),
                                const SizedBox(width: 12),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Essence Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppTheme.primary,
                          AppTheme.primaryContainer
                        ]),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('INTISARI UTAMA',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('"${summary['core_essence'] ?? ''}"',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Peningkatan Materi Belajar (Tabbed/Segmented Control)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            )
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MATERI BELAJAR',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          _buildTabChips(),
                          const SizedBox(height: 24),
                          // Content switcher
                          if (_activeTab == 'Poin Penting')
                            _buildTakeawaysTab(takeaways)
                          else if (_activeTab == 'Rangkuman Detail')
                            _buildOutlineTab(outline, context, provider)
                          else if (_activeTab == 'Glosarium Istilah')
                            _buildGlossaryTab(glossary, context, provider)
                          else if (_activeTab == 'Latihan Mandiri')
                            _buildStudyQuestionsTab(studyQuestions, context, provider),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Exam Tip Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: AppTheme.tertiary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                              color: AppTheme.tertiary.withOpacity(0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology, color: AppTheme.tertiary),
                              SizedBox(width: 8),
                              Text('Tips Ujian',
                                  style: TextStyle(
                                      color: AppTheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                              summary['exam_tips'] ??
                                  'Tidak ada tips ujian khusus untuk sesi ini.',
                              style: TextStyle(
                                  color: AppTheme.tertiary.withOpacity(0.8),
                                  height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),

              // Floating Audio Player
              if (_isPlayerReady)
                Positioned(
                  bottom: 32,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 48,
                            offset: const Offset(0, 24))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (_isPlaying) {
                                  await _audioPlayer.pause();
                                } else {
                                  await _audioPlayer.play();
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16)),
                                child: Icon(
                                    _isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: AppTheme.onPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Text('Memutar Rekaman...',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      Text(
                                          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                          style: const TextStyle(
                                              color: AppTheme.outlineVariant,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTapUp: (details) {
                                      final box = context.findRenderObject()
                                          as RenderBox;
                                      final dx = details.localPosition.dx /
                                          box.size.width;
                                      final seekTo = _duration * dx;
                                      _audioPlayer.seek(seekTo);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _duration.inMilliseconds > 0
                                            ? _position.inMilliseconds /
                                                _duration.inMilliseconds
                                            : 0.0,
                                        backgroundColor:
                                            AppTheme.surfaceContainerHighest,
                                        color: AppTheme.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _audioPlayer
                                  .seek(_position - const Duration(seconds: 10)),
                              child: const Icon(Icons.replay_10,
                                  color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _audioPlayer
                                  .seek(_position + const Duration(seconds: 10)),
                              child: const Icon(Icons.forward_10,
                                  color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 32,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.outlineVariant, size: 16),
                        SizedBox(width: 8),
                        Text('File rekaman tidak tersedia di perangkat ini.',
                            style: TextStyle(
                                color: AppTheme.outlineVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTakeawayItem(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.2),
              shape: BoxShape.circle),
          child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(desc,
                  style: TextStyle(
                      color: AppTheme.onSurfaceVariant, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabChips() {
    final List<String> tabs = ['Poin Penting', 'Rangkuman Detail', 'Glosarium Istilah', 'Latihan Mandiri'];
    return Container(
      height: 70,
      child: Scrollbar(
        controller: _tabScrollController,
        thumbVisibility: true,
        thickness: 2.5,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: _tabScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(
            children: tabs.map((tabName) {
              final isSelected = _activeTab == tabName;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(tabName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _activeTab = tabName;
                      });
                    }
                  },
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceContainerLow,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTakeawaysTab(List<dynamic> takeaways) {
    if (takeaways.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('Tidak ada poin penting tersedia.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: takeaways.asMap().entries.map((entry) {
        final index = entry.key;
        final val = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildTakeawayItem('${index + 1}', val['title'] ?? '', val['description'] ?? ''),
        );
      }).toList(),
    );
  }

  Widget _buildOutlineTab(List<dynamic> outline, BuildContext context, AppProvider provider) {
    if (outline.isEmpty) {
      return _buildLegacyBanner(context, provider);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: outline.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_border, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['section_title'] ?? 'Bagian Tanpa Judul',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['section_summary'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlossaryTab(List<dynamic> glossary, BuildContext context, AppProvider provider) {
    if (glossary.isEmpty) {
      return _buildLegacyBanner(context, provider);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: glossary.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['term'] ?? 'Istilah',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['definition'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudyQuestionsTab(List<dynamic> questions, BuildContext context, AppProvider provider) {
    if (questions.isEmpty) {
      return _buildLegacyBanner(context, provider);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final qText = entry.value.toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.tertiary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.tertiary.withOpacity(0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  qText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegacyBanner(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.secondary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Materi Lengkap Belum Tersedia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Materi detail (Outline, Glosarium, & Pertanyaan Latihan) belum digenerasi untuk kuliah ini. Anda bisa memperbarui materi lengkap ini menggunakan AI secara gratis.',
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isLoading ? null : () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Sedang menyusun materi lengkap dengan AI...'),
                      ],
                    ),
                    duration: Duration(seconds: 15),
                  ),
                );
                await provider.regenerateSummary(widget.lectureId);
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (provider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Materi lengkap berhasil dibuat!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              icon: provider.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh, size: 16),
              label: Text(provider.isLoading ? 'Memproses...' : 'Lengkapi Ringkasan Cerdas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required VoidCallback onPressed,
      required IconData icon,
      required String label,
      required Color color,
      bool isLoading = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
      ),
    );
  }

  void _showQuizConfigSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Jumlah Soal Kuis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesuaikan jumlah pertanyaan kuis dengan kebutuhan belajar Anda.',
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _buildQuizOptionTile(context, provider, 5, 'Kilas Balik Cepat', '5 Pertanyaan'),
            const SizedBox(height: 12),
            _buildQuizOptionTile(context, provider, 10, 'Pemahaman Standar', '10 Pertanyaan'),
            const SizedBox(height: 12),
            _buildQuizOptionTile(context, provider, 15, 'Simulasi Ujian', '15 Pertanyaan'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizOptionTile(
    BuildContext context, 
    AppProvider provider, 
    int count, 
    String modeName, 
    String description
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              lectureId: widget.lectureId,
              generateCount: count,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

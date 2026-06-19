import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:flutter/services.dart';
import 'package:lecturer_digest/core/services/document_service.dart';

class AskAiChat extends StatefulWidget {
  final bool isTab;
  const AskAiChat({super.key, this.isTab = false});

  @override
  State<AskAiChat> createState() => _AskAiChatState();
}

class _AskAiChatState extends State<AskAiChat> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showScrollDownButton = false;
  int _lastMessageCount = 0;
  bool _lastIsLoading = false;

  PickedDocument? _attachedFile;
  String? _attachedFileName;
  String? _attachedFileText;
  bool _isExtractingFile = false;

  Future<void> _handleAttachFile() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final lecture = provider.chatLecture;
    final course = provider.chatCourse;
    if (lecture == null && course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih konteks materi atau kelas terlebih dahulu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final docService = DocumentService();
    try {
      final file = await docService.pickPDF();
      if (file == null) return; // User cancelled

      setState(() {
        _isExtractingFile = true;
        _attachedFile = file;
        _attachedFileName = file.name; // gunakan .name langsung, cross-platform
        _attachedFileText = null;
      });

      final text = await docService.extractTextFromPDF(file);
      setState(() {
        _attachedFileText = text;
        _isExtractingFile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen "$_attachedFileName" berhasil dilampirkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _attachedFile = null;
        _attachedFileName = null;
        _attachedFileText = null;
        _isExtractingFile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDetachFile() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
      _attachedFileText = null;
      _isExtractingFile = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.fetchRecentChatSessions();
      _scrollToBottom();
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final isNearBottom =
          _scrollController.position.maxScrollExtent -
              _scrollController.offset <
          100;
      if (isNearBottom && _showScrollDownButton) {
        setState(() {
          _showScrollDownButton = false;
        });
      } else if (!isNearBottom && !_showScrollDownButton) {
        setState(() {
          _showScrollDownButton = true;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final lecture = provider.chatLecture;
        final course = provider.chatCourse;
        final hasContext = lecture != null || course != null;
        final messages = provider.chatMessages;
        final isLoading = provider.isLoading;

        // Scroll to bottom only when messages length or loading state changes
        if (messages.length != _lastMessageCount ||
            isLoading != _lastIsLoading) {
          _lastMessageCount = messages.length;
          _lastIsLoading = isLoading;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.background.withOpacity(0.9),
            elevation: 0,
            leading: widget.isTab
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DigestBot',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  hasContext
                      ? (lecture != null
                            ? 'MATERI: ${lecture['title'].toString().toUpperCase()}'
                            : 'KELAS: ${course!['name'].toString().toUpperCase()}')
                      : 'PILIH KONTEKS',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_comment_rounded,
                  color: AppTheme.primary,
                ),
                onPressed: () {
                  provider.clearChatContext();
                  _handleDetachFile();
                },
                tooltip: 'Obrolan Baru',
              ),
              IconButton(
                icon: const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primary,
                ),
                onPressed: () => _showHistoryBottomSheet(context, provider),
                tooltip: 'Riwayat Obrolan',
              ),
              if (hasContext)
                IconButton(
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppTheme.primary,
                  ),
                  onPressed: () => _showContextPicker(context, provider),
                  tooltip: 'Ganti Konteks',
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.isDesktop(context) ? 900 : double.infinity,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: !hasContext
                        ? _buildEmptyState(context, provider)
                        : Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.isDesktop(context)
                                      ? 48
                                      : 24,
                                  vertical: 32,
                                ),
                                children: [
                                  _buildSleekContextBadge(
                                    context,
                                    provider,
                                    lecture,
                                    course,
                                  ),
                                  const SizedBox(height: 24),
                                  const Divider(height: 1, thickness: 1),
                                  const SizedBox(height: 32),
                                  ...messages.map((m) {
                                    if (m['role'] == 'bot') {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 36.0,
                                        ),
                                        child: _buildAIMessage(
                                          context,
                                          m['text'],
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 36.0,
                                        ),
                                        child: _buildUserMessage(
                                          context,
                                          m['text'],
                                        ),
                                      );
                                    }
                                  }),
                                  if (provider.isLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        bottom: 36.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withOpacity(0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const BrandLogo(size: 20),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'DigestBot',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 13,
                                                    color: AppTheme.primary,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(AppTheme.primary),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'DigestBot sedang berpikir...',
                                                      style: TextStyle(
                                                        color: AppTheme.primary
                                                            .withOpacity(0.6),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                              if (_showScrollDownButton)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: GestureDetector(
                                    onTap: _scrollToBottom,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerLowest,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.outlineVariant
                                              .withOpacity(0.12),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      bottom: View.of(context).viewInsets.bottom > 0
                          ? 16
                          : (Responsive.isDesktop(context)
                                ? 24
                                : (widget.isTab
                                      ? 20 +
                                            MediaQuery.of(
                                              context,
                                            ).padding.bottom
                                      : 16 +
                                            MediaQuery.of(
                                              context,
                                            ).padding.bottom)),
                      left: Responsive.isDesktop(context) ? 48 : 24,
                      right: Responsive.isDesktop(context) ? 48 : 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.outlineVariant.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: provider.activeRemedialPrompt != null
                                ? [
                                    _buildSuggestionChip(
                                      'Jelaskan materi yang saya salah',
                                      () => provider.sendChatMessage(
                                        'Berdasarkan hasil kuis kemarin, tolong jelaskan bagian konsep yang masih saya salah.',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSuggestionChip(
                                      'Berikan latihan soal sederhana',
                                      () => provider.sendChatMessage(
                                        'Tolong berikan saya 1 contoh soal latihan sederhana untuk melatih pemahaman konsep tersebut.',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSuggestionChip(
                                      'Bagaimana cara memperbaikinya?',
                                      () => provider.sendChatMessage(
                                        'Apa langkah atau metode belajar terbaik agar saya paham konsep ini?',
                                      ),
                                    ),
                                  ]
                                : [
                                    _buildSuggestionChip(
                                      'Apa poin utamanya?',
                                      () => provider.sendChatMessage(
                                        'Apa poin utama dari materi ini?',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSuggestionChip(
                                      'Ringkaskan bagian penting.',
                                      () => provider.sendChatMessage(
                                        'Tolong ringkaskan bagian penting dari materi ini.',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSuggestionChip(
                                      'Ada tips ujian?',
                                      () => provider.sendChatMessage(
                                        'Apakah ada tips khusus untuk ujian terkait materi ini?',
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_attachedFile != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.outlineVariant.withOpacity(
                                  0.12,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isExtractingFile
                                        ? Icons.sync
                                        : Icons.picture_as_pdf_rounded,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _attachedFileName ?? 'Dokumen PDF',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isExtractingFile
                                            ? 'Mengekstrak teks dokumen...'
                                            : 'PDF siap dikirim sebagai konteks diskusi.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _isExtractingFile
                                              ? AppTheme.primary
                                              : AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isExtractingFile)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                    onPressed: _handleDetachFile,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _handleAttachFile,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _isExtractingFile
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.primary,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.attach_file,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _focusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Tanya tentang materi ini...',
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) {
                                    if (_messageController.text.isNotEmpty) {
                                      provider.sendChatMessage(
                                        _messageController.text,
                                        fileContext: _attachedFileText,
                                        fileName: _attachedFileName,
                                      );
                                      _messageController.clear();
                                      _handleDetachFile();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                if (_messageController.text.isNotEmpty) {
                                  provider.sendChatMessage(
                                    _messageController.text,
                                    fileContext: _attachedFileText,
                                    fileName: _attachedFileName,
                                  );
                                  _messageController.clear();
                                  _handleDetachFile();
                                }
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primaryContainer,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleekContextBadge(
    BuildContext context,
    AppProvider provider,
    Map<String, dynamic>? lecture,
    Map<String, dynamic>? course,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    lecture != null
                        ? Icons.description_outlined
                        : Icons.school_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lecture != null
                            ? 'DISKUSI MATERI AKTIF'
                            : 'DISKUSI KELAS AKTIF',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lecture != null
                            ? lecture['title']
                            : (course?['name'] ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showContextPicker(context, provider),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text(
              'Ganti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              foregroundColor: AppTheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseMarkdown(String text, TextStyle baseStyle) {
    // 1. Process bullet points
    String processed = text;
    if (processed.startsWith('* ')) {
      processed = '• ' + processed.substring(2);
    }
    processed = processed.replaceAll('\n* ', '\n• ');
    processed = processed.replaceAll('\n  * ', '\n  • ');

    final List<InlineSpan> spans = [];
    int i = 0;
    final int len = processed.length;

    bool isBold = false;
    bool isItalic = false;

    StringBuffer currentText = StringBuffer();

    void flushCurrentText() {
      if (currentText.isNotEmpty) {
        TextStyle style = baseStyle;
        if (isBold) {
          style = style.copyWith(fontWeight: FontWeight.bold);
        }
        if (isItalic) {
          style = style.copyWith(fontStyle: FontStyle.italic);
        }
        spans.add(TextSpan(text: currentText.toString(), style: style));
        currentText.clear();
      }
    }

    while (i < len) {
      // Check for double asterisk (bold)
      if (i + 1 < len && processed[i] == '*' && processed[i + 1] == '*') {
        flushCurrentText();
        isBold = !isBold;
        i += 2;
      }
      // Check for single asterisk (italic)
      else if (processed[i] == '*') {
        flushCurrentText();
        isItalic = !isItalic;
        i += 1;
      }
      // Normal character
      else {
        currentText.write(processed[i]);
        i += 1;
      }
    }

    flushCurrentText();
    return spans;
  }

  Widget _buildAIMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const BrandLogo(size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DigestBot',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: _parseMarkdown(
                    text,
                    const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAIMessageActionBar(context, text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIMessageActionBar(BuildContext context, String text) {
    return Row(
      children: [
        _buildActionIconButton(
          icon: Icons.content_copy_rounded,
          tooltip: 'Salin Jawaban',
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Jawaban disalin ke clipboard!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 15,
              color: AppTheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 64),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.onSurface,
                height: 1.5,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    final isDesktop = Responsive.isDesktop(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tanyakan apa saja kepada DigestBot',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulailah berdiskusi cerdas dengan asisten AI Anda. Pilih materi perkuliahan atau mata kuliah terlebih dahulu untuk memulai konteks pembelajaran.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showContextPicker(context, provider),
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text(
                'Pilih Konteks Belajar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
            if (provider.recentChatSessions.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OBROLAN TERAKHIR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (provider.recentChatSessions.length > 3)
                    TextButton(
                      onPressed: () =>
                          _showHistoryBottomSheet(context, provider),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...provider.recentChatSessions.take(3).map((session) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppTheme.outlineVariant.withOpacity(0.12),
                    ),
                  ),
                  color: AppTheme.surfaceContainerLow,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      session['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      session['course_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                    ),
                    onTap: () {
                      provider.setChatLecture(session['lecture_id']);
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: 48),

            // Suggestion Prompt Cards (ChatGPT style!)
            Text(
              'CONTOH PERTANYAAN AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary.withOpacity(0.8),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            isDesktop
                ? GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.8,
                    children: [
                      _buildPromptCard(
                        Icons.psychology_outlined,
                        'Jelaskan Konsep Dasar',
                        'Uraikan teori utama dan rumusan inti dari materi ini secara sederhana.',
                        () => _sendSuggestionPrompt(
                          provider,
                          'Uraikan teori utama dan rumusan inti dari materi ini secara sederhana.',
                        ),
                      ),
                      _buildPromptCard(
                        Icons.lightbulb_outline_rounded,
                        'Buat Ringkasan Eksekutif',
                        'Tolong buatkan ringkasan singkat tapi padat dalam 5 poin penting.',
                        () => _sendSuggestionPrompt(
                          provider,
                          'Tolong buatkan ringkasan singkat tapi padat dalam 5 poin penting.',
                        ),
                      ),
                      _buildPromptCard(
                        Icons.quiz_outlined,
                        'Latihan Soal & Jawaban',
                        'Berikan 3 pertanyaan kritis beserta jawabannya untuk latihan ujian.',
                        () => _sendSuggestionPrompt(
                          provider,
                          'Berikan 3 pertanyaan kritis beserta jawabannya untuk latihan ujian.',
                        ),
                      ),
                      _buildPromptCard(
                        Icons.history_edu_rounded,
                        'Hubungan dengan Praktek',
                        'Bagaimana materi teori ini diaplikasikan pada dunia kerja riil?',
                        () => _sendSuggestionPrompt(
                          provider,
                          'Bagaimana materi teori ini diaplikasikan pada dunia kerja riil?',
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildPromptCard(
                        Icons.psychology_outlined,
                        'Jelaskan Konsep Dasar',
                        'Uraikan teori utama dari materi ini secara sederhana.',
                        () => _sendSuggestionPrompt(
                          provider,
                          'Uraikan teori utama dari materi ini secara sederhana.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPromptCard(
                        Icons.lightbulb_outline_rounded,
                        'Buat Ringkasan Eksekutif',
                        'Tolong buatkan ringkasan singkat dalam 5 poin penting.',
                        () => _sendSuggestionPrompt(
                          provider,
                          'Tolong buatkan ringkasan singkat dalam 5 poin penting.',
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard(
    IconData icon,
    String title,
    String body,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendSuggestionPrompt(AppProvider provider, String prompt) {
    final lecture = provider.chatLecture;
    final course = provider.chatCourse;
    if (lecture == null && course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih konteks materi/kelas terlebih dahulu di tombol atas.',
          ),
        ),
      );
    } else {
      provider.sendChatMessage(prompt);
    }
  }

  void _showContextPicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Konteks Diskusi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.courses.length,
                itemBuilder: (context, index) {
                  final course = provider.courses[index];
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: provider.getLecturesForCourse(course['id']),
                    builder: (context, snapshot) {
                      final lcs = snapshot.data ?? [];
                      return Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            course['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${lcs.length} Materi',
                            style: const TextStyle(fontSize: 11),
                          ),
                          children: [
                            ListTile(
                              leading: const SizedBox(
                                width: 40,
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                              ),
                              title: const Text(
                                'Diskusi Seluruh Materi Kelas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              onTap: () {
                                provider.setChatCourse(course['id']);
                                Navigator.pop(context);
                              },
                            ),
                            ...lcs.map(
                              (l) => ListTile(
                                dense: true,
                                leading: const SizedBox(
                                  width: 40,
                                  child: Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  l['title'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                onTap: () {
                                  provider.setChatLecture(l['id']);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Obrolan AI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: provider.recentChatSessions.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada riwayat percakapan.',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.recentChatSessions.length,
                      itemBuilder: (context, index) {
                        final session = provider.recentChatSessions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppTheme.outlineVariant.withOpacity(0.12),
                            ),
                          ),
                          color: AppTheme.surfaceContainerLow,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              session['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              session['course_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                            ),
                            onTap: () {
                              provider.setChatLecture(session['lecture_id']);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

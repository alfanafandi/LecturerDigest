import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';

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
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
        
        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.background.withOpacity(0.9),
            elevation: 0,
            leading: widget.isTab ? null : IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DigestBot', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text(
                  hasContext 
                    ? (lecture != null ? 'MATERI: ${lecture['title'].toString().toUpperCase()}' : 'KELAS: ${course!['name'].toString().toUpperCase()}')
                    : 'PILIH KONTEKS', 
                  style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                ),
              ],
            ),
            actions: [
              if (hasContext)
                IconButton(
                  icon: const Icon(Icons.history_edu_rounded, color: AppTheme.primary),
                  onPressed: () => _showContextPicker(context, provider),
                  tooltip: 'Ganti Konteks',
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 900 : double.infinity),
              child: Column(
                children: [
                  Expanded(
                    child: !hasContext 
                    ? _buildEmptyState(context, provider)
                    : ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isDesktop(context) ? 48 : 24, 
                        vertical: 32
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 24)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DISKUSI AKTIF', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              Text(
                                lecture != null ? lecture['title'] : course!['name'], 
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(course != null ? Icons.school_rounded : Icons.auto_awesome, color: AppTheme.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      course != null ? 'Mode Seluruh Kelas Aktif' : 'Asisten AI Siap membantu', 
                                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...messages.map((m) {
                            if (m['role'] == 'bot') {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: _buildAIMessage(context, m['text']),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: _buildUserMessage(context, m['text'], provider.userProfile?['avatar_url']),
                              );
                            }
                          }).toList(),
                        if (provider.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 48), 
                                const Icon(Icons.more_horiz, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text('DigestBot sedang berpikir...', style: TextStyle(color: AppTheme.primary.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      top: 16, 
                      bottom: View.of(context).viewInsets.bottom > 0 
                          ? 16 
                          : (widget.isTab ? 120 : 32), 
                      left: Responsive.isDesktop(context) ? 48 : 24, 
                      right: Responsive.isDesktop(context) ? 48 : 24
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(top: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.1))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSuggestionChip('Apa poin utamanya?', () => provider.sendChatMessage('Apa poin utama dari materi ini?')),
                              const SizedBox(width: 8),
                              _buildSuggestionChip('Ringkaskan bagian penting.', () => provider.sendChatMessage('Tolong ringkaskan bagian penting dari materi ini.')),
                              const SizedBox(width: 8),
                              _buildSuggestionChip('Ada tips ujian?', () => provider.sendChatMessage('Apakah ada tips khusus untuk ujian terkait materi ini?')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.attach_file, color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh, 
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
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
                                      provider.sendChatMessage(_messageController.text);
                                      _messageController.clear();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                if (_messageController.text.isNotEmpty) {
                                  provider.sendChatMessage(_messageController.text);
                                  _messageController.clear();
                                }
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: const Icon(Icons.send, color: Colors.white),
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

  Widget _buildAIMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const BrandLogo(size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Text(text, style: const TextStyle(height: 1.5)),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildUserMessage(BuildContext context, String text, String? avatarUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24)),
            ),
            child: Text(text, style: const TextStyle(color: AppTheme.onPrimaryContainer, height: 1.5, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          backgroundImage: avatarUrl != null ? AssetImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person, size: 16, color: AppTheme.primary) : null,
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
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Text(text, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_outlined, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum ada obrolan aktif',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Silakan pilih materi atau kelas untuk mulai berdiskusi dengan DigestBot.',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showContextPicker(context, provider),
                icon: const Icon(Icons.add_comment_rounded),
                label: const Text('Pilih Konteks Materi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextPicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pilih Konteks Diskusi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
                  // Use existing fetchLectures method
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: provider.getLecturesForCourse(course['id']),
                    builder: (context, snapshot) {
                      final lcs = snapshot.data ?? [];
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.school, color: AppTheme.primary, size: 18),
                          ),
                          title: Text(course['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${lcs.length} Materi', style: const TextStyle(fontSize: 11)),
                          children: [
                            // Option to chat with whole course
                            ListTile(
                              leading: const SizedBox(width: 40, child: Icon(Icons.auto_awesome, size: 18, color: AppTheme.primary)),
                              title: const Text('Diskusi Seluruh Materi Kelas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              onTap: () {
                                provider.setChatCourse(course['id']);
                                Navigator.pop(context);
                              },
                            ),
                            ...lcs.map((l) => ListTile(
                              dense: true,
                              leading: const SizedBox(width: 40, child: Icon(Icons.description_outlined, size: 16)),
                              title: Text(l['title'], style: const TextStyle(fontSize: 13)),
                              onTap: () {
                                provider.setChatLecture(l['id']);
                                Navigator.pop(context);
                              },
                            )).toList(),
                          ],
                        ),
                      );
                    }
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

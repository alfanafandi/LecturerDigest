import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';

class AskAiChat extends StatefulWidget {
  final bool isTab;
  const AskAiChat({super.key, this.isTab = false});

  @override
  State<AskAiChat> createState() => _AskAiChatState();
}

class _AskAiChatState extends State<AskAiChat> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.chatLecture == null && provider.courses.isNotEmpty) {
        provider.fetchLectures(provider.courses.first['id']).then((_) {
          if (provider.lectures.isNotEmpty) {
            provider.setChatLecture(provider.lectures.first['id']);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final lecture = provider.chatLecture;
        final messages = provider.chatMessages;

        return Scaffold(
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
                  lecture != null ? 'AI CONTEXT: ${lecture['courses']['name'].toString().toUpperCase()}' : 'SELECT CONTEXT', 
                  style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          const Text('CURRENT LECTURE', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text(lecture != null ? lecture['title'] : 'No lecture selected', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 16),
                                const SizedBox(width: 8),
                                Text(lecture != null ? 'AI Assistant Ready' : 'Choose a lecture to start', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (lecture == null) 
                      const Center(child: Text('Tolong pilih perkuliahan di menu Courses untuk bertanya.'))
                    else 
                      ...messages.map((m) {
                        if (m['role'] == 'bot') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: _buildAIMessage(context, m['text']),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: _buildUserMessage(context, m['text'], 'https://avatar.iran.liara.run/public/boy'),
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
                            Text('DigestBot is thinking', style: TextStyle(color: AppTheme.primary.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                  bottom: widget.isTab ? 120 : 32, 
                  left: 24, 
                  right: 24
                ),
                decoration: BoxDecoration(color: AppTheme.background.withOpacity(0.9)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSuggestionChip('What was the main point?'),
                          const SizedBox(width: 8),
                          _buildSuggestionChip('Summarize the key part.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.attach_file, color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 48,
                            decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Ask about the lecture...',
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
                            width: 48,
                            height: 48,
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
        );
      },
    );
  }

  Widget _buildAIMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_stories, color: Colors.white, size: 16),
        ),
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

  Widget _buildUserMessage(BuildContext context, String text, String avatarUrl) {
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
          backgroundImage: NetworkImage(avatarUrl),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Text(text, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

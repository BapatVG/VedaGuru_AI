import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/localization_service.dart';
import '../utils/voice_helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isListening = false;
  int? _speakingIndex;
  String _preListeningText = '';

  final List<String> _quickPrompts = [
    "Satyanarayan Pooja Vidhi",
    "Griha Pravesh Essentials",
    "How to prepare Panchamrit?",
    "Gayatri Mantra significance",
    "Daily Sandhyavandanam steps",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final username = auth.currentUser?.username ?? 'Guest';
      Provider.of<ChatProvider>(context, listen: false).loadHistory(username);
    });
  }

  @override
  void dispose() {
    VoiceHelper.stopListening();
    VoiceHelper.stopSpeaking();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    if (_isListening) {
      VoiceHelper.stopListening();
      setState(() => _isListening = false);
    }
    final text = presetText ?? _messageController.text;
    if (text.trim().isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Guest';
    final lang = auth.currentLanguage;

    Provider.of<ChatProvider>(context, listen: false).sendMessage(
      username: username,
      text: text,
      language: lang,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('service_chat_title'),
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => LocalizationService.showLanguageBottomSheet(context),
            icon: const Icon(Icons.language, size: 18, color: AppTheme.primarySaffron),
            label: Text(
              auth.currentLanguage,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primarySaffron),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts Horizontal Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  backgroundColor: const Color(0xFFFFF7EB),
                  side: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Messages List
          Expanded(
            child: chat.messages.isEmpty && !chat.isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🕉️', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'Ask VedaGuru AI',
                            style: GoogleFonts.cinzel(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inquire about sacred mantras, ritual rules, samagri, or Vedic customs.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length && chat.isLoading) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primarySaffron,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Consulting Vedic scriptures...',
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = chat.messages[index];
                      final isUser = msg.isUser;

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.primarySaffron : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                            border: isUser
                                ? null
                                : Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                msg.content,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: isUser ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              if (!isUser) ...[
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () {
                                    if (_speakingIndex == index) {
                                      VoiceHelper.stopSpeaking();
                                      setState(() => _speakingIndex = null);
                                    } else {
                                      setState(() => _speakingIndex = index);
                                      VoiceHelper.speakText(
                                        text: msg.content,
                                        language: auth.currentLanguage,
                                        onStart: () {
                                          if (mounted) setState(() => _speakingIndex = index);
                                        },
                                        onComplete: () {
                                          if (mounted) setState(() => _speakingIndex = null);
                                        },
                                        onError: (err) {
                                          if (mounted) {
                                            setState(() => _speakingIndex = null);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Audio: $err'), duration: const Duration(seconds: 2)),
                                            );
                                          }
                                        },
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _speakingIndex == index
                                          ? AppTheme.primarySaffron.withValues(alpha: 0.15)
                                          : AppTheme.sacredGold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _speakingIndex == index
                                            ? AppTheme.primarySaffron
                                            : AppTheme.sacredGold.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _speakingIndex == index
                                              ? Icons.stop_circle_rounded
                                              : Icons.volume_up_rounded,
                                          size: 15,
                                          color: _speakingIndex == index
                                              ? AppTheme.primarySaffron
                                              : AppTheme.primaryDark,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _speakingIndex == index ? 'Stop Voice' : 'Listen',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _speakingIndex == index
                                                ? AppTheme.primarySaffron
                                                : AppTheme.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Listening Status Banner
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primarySaffron,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🎙️ Listening in ${auth.currentLanguage}... Speak into your microphone',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC85A17),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      VoiceHelper.stopListening();
                      setState(() => _isListening = false);
                    },
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFC85A17)),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask a Vedic question...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Speech-to-Text Microphone Button
                  Container(
                    decoration: BoxDecoration(
                      color: _isListening ? const Color(0xFFFFEBEE) : const Color(0xFFFFF7EB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isListening ? Colors.red : AppTheme.sacredGold.withValues(alpha: 0.4),
                        width: _isListening ? 2 : 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                        color: _isListening ? Colors.red : AppTheme.primarySaffron,
                        size: 20,
                      ),
                      tooltip: _isListening ? 'Listening (Tap to Stop)' : 'Voice Input (Tap to Speak)',
                      onPressed: () {
                        if (_isListening) {
                          VoiceHelper.stopListening();
                          setState(() => _isListening = false);
                        } else {
                          _preListeningText = _messageController.text.trim();
                          VoiceHelper.startListening(
                            language: auth.currentLanguage,
                            onResult: (text, isFinal) {
                              setState(() {
                                final combined = _preListeningText.isEmpty ? text : '$_preListeningText $text';
                                _messageController.text = combined;
                                _messageController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: combined.length),
                                );
                              });
                            },
                            onStatusChange: (listening) {
                              setState(() => _isListening = listening);
                            },
                            onError: (err) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Voice: $err'),
                                  backgroundColor: Colors.red.shade700,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primarySaffron,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

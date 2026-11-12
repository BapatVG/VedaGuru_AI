import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AyurvedaScreen extends StatefulWidget {
  const AyurvedaScreen({super.key});

  @override
  State<AyurvedaScreen> createState() => _AyurvedaScreenState();
}

class _AyurvedaScreenState extends State<AyurvedaScreen> {
  final List<Map<String, String>> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/lifestyle/ayurveda/history/$username');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final history = (data['history'] as List? ?? []);
        setState(() {
          _messages.clear();
          if (history.isEmpty) {
            _messages.add({
              'role': 'assistant',
              'content':
                  'Namaste! I am your Ayurvedic Assistant (Vaidya). I can help you understand your Dosha (Vata, Pitta, Kapha), suggest dietary changes, or recommend ancient Ayurvedic remedies. (You can type "Find my Dosha" to start an assessment).',
            });
          } else {
            for (var m in history) {
              _messages.add({
                'role': m['role'] ?? 'assistant',
                'content': m['content'] ?? '',
              });
            }
          }
        });
      }
    } catch (_) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Namaste! I am your Ayurvedic Assistant. Ask about your Dosha, Prakriti, or daily Dinacharya.',
        });
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/lifestyle/ayurveda/chat');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'message': text,
          'language': lang,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': data['response']});
        });
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: ${data['detail'] ?? "Could not reach Ayurvedic doctor."}'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Connection error: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _clearChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/lifestyle/ayurveda/history/$username');
      await http.delete(uri);
    } catch (_) {}
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'assistant',
        'content': 'Conversation cleared. How can I guide your wellness today?',
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayurvedic Wellness & Doshas',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.textMuted),
            tooltip: 'Clear Conversation',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.teal.shade50,
            child: Text(
              '🌿 Ancient Ayurvedic wisdom for natural lifestyle harmony. For acute health concerns, always consult a certified Vaidya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.teal.shade900),
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primarySaffron : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUser ? AppTheme.primaryDark : AppTheme.sacredGold.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SelectableText(
                      msg['content'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: isUser ? Colors.white : AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySaffron),
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: "Ask about Dosha, herbs, or 'Find my Dosha'...",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primarySaffron),
                    onPressed: _sendMessage,
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

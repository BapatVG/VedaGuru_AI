import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> loadHistory(String username) async {
    _isLoading = true;
    notifyListeners();
    final history = await ApiService.getChatHistory(username);
    _messages.clear();
    _messages.addAll(history);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String username,
    required String text,
    String language = 'English',
  }) async {
    if (text.trim().isEmpty) return;

    // Add user message to local state immediately
    final userMsg = ChatMessage(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    // Call FastAPI
    final res = await ApiService.askVedicChat(
      username: username,
      message: text.trim(),
      language: language,
    );

    _isLoading = false;
    if (res['success']) {
      final aiMsg = ChatMessage(
        role: 'assistant',
        content: res['reply'],
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
    } else {
      final errMsg = ChatMessage(
        role: 'assistant',
        content: '⚠️ ${res['error'] ?? 'Could not reach VedaGuru backend.'}',
        timestamp: DateTime.now(),
      );
      _messages.add(errMsg);
    }
    notifyListeners();
  }

  void clearLocal() {
    _messages.clear();
    notifyListeners();
  }
}

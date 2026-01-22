import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class AIChatProvider with ChangeNotifier {
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [
    ChatMessage(
      role: 'assistant',
      content: 'Hello! I\'m your AI Health Assistant. How can I help you today?',
      timestamp: DateTime.now(),
    ),
  ];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  Future<void> sendMessage(String message) async {
    // Add user message
    _messages.add(ChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Show typing indicator
    _isTyping = true;
    notifyListeners();

    // Get AI response
    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final response = await _aiService.getChatResponse(message, history);

    // Add AI response
    _messages.add(ChatMessage(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    ));

    _isTyping = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _messages.add(ChatMessage(
      role: 'assistant',
      content: 'Hello! I\'m your AI Health Assistant. How can I help you today?',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
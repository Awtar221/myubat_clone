import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/chat_message.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _fallbackModel = 'gemini-pro';
  static const String _systemInstruction =
      "You are MyUbatPlus AI assistant. Only use the provided UserContext for factual info like appointments and medications. If not present, say you don't have enough info. Be concise. No medical diagnosis. For emergencies advise contacting a doctor.";

  Future<String> generateReply({
    required String userText,
    required String userContext,
    required List<ChatMessage> recentMessages,
  }) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY is missing.');
    }

    final history = recentMessages.length <= 10
        ? recentMessages
        : recentMessages.sublist(recentMessages.length - 10);
    final historyText = history
        .map(
          (m) =>
              '${m.role == 'assistant' ? 'assistant' : 'user'}: ${m.content}',
        )
        .join('\n');

    final prompt = StringBuffer()
      ..writeln('UserContext:')
      ..writeln(userContext)
      ..writeln()
      ..writeln('RecentHistory:')
      ..writeln(historyText.isEmpty ? '(empty)' : historyText)
      ..writeln()
      ..writeln('CurrentUserMessage:')
      ..writeln(userText);

    final promptText = prompt.toString();
    String usedModel = _primaryModel;
    GenerateContentResponse response;

    try {
      response = await _generateWithModel(
        modelName: _primaryModel,
        apiKey: apiKey,
        prompt: promptText,
      );
    } catch (error) {
      if (!_isModelNotFoundError(error)) {
        rethrow;
      }
      response = await _generateWithModel(
        modelName: _fallbackModel,
        apiKey: apiKey,
        prompt: promptText,
      );
      usedModel = _fallbackModel;
    }

    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      throw StateError('Gemini returned empty response.');
    }
    debugPrint('Gemini model used: $usedModel');
    return text;
  }

  Future<GenerateContentResponse> _generateWithModel({
    required String modelName,
    required String apiKey,
    required String prompt,
  }) {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );
    return model.generateContent(<Content>[Content.text(prompt)]);
  }

  bool _isModelNotFoundError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('404') || message.contains('not found');
  }
}

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/app_config.dart';
import '../../data/models/chat_message.dart';

class GeminiService {
  static const String _primaryModel = 'gemini-2.5-flash';

  Future<String> generateReply({
    required String userText,
    required String userContext,
    required List<ChatMessage> recentMessages,
    required String languageCode,
    Uint8List? imageBytes,
  }) async {
    final apiKey = AppConfig.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      throw AppConfigException(AppConfig.missingGeminiApiKeyMessage);
    }

    final model = GenerativeModel(
      model: _primaryModel,
      apiKey: apiKey,
      systemInstruction: Content.system(
        _buildSystemInstruction(languageCode),
      ),
    );

    final history = recentMessages.take(10).map((message) {
      return message.role == 'user'
          ? Content.text('User: ${message.content}')
          : Content.model([TextPart('Assistant: ${message.content}')]);
    }).toList();

    final promptParts = <Part>[
      TextPart('User Context: $userContext\n\nUser Question: $userText'),
      if (imageBytes != null) DataPart('image/jpeg', imageBytes),
    ];

    try {
      final response = await model.generateContent([
        ...history,
        Content.multi(promptParts),
      ]);
      return response.text?.trim() ?? _fallbackProcessingMessage(languageCode);
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return _fallbackConnectionMessage(languageCode);
    }
  }

  Future<Map<String, String>> scanMedication(Uint8List imageBytes) async {
    final apiKey = AppConfig.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      return {'error': AppConfig.missingGeminiApiKeyMessage};
    }

    final model = GenerativeModel(model: _primaryModel, apiKey: apiKey);
    const prompt =
        'Extract Medication Name, Dosage, and Instructions from this label. Format as Name: [val], Dosage: [val], Instructions: [val].';

    try {
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);
      return _parseMedicationData(response.text ?? '');
    } catch (e) {
      debugPrint('Medication scan error: $e');
      return {'error': 'Failed to scan label'};
    }
  }

  Map<String, String> _parseMedicationData(String text) {
    final data = <String, String>{};
    for (final line in text.split('\n')) {
      if (line.contains('Name:')) {
        data['name'] = line.split(':').last.trim();
      }
      if (line.contains('Dosage:')) {
        data['dosage'] = line.split(':').last.trim();
      }
      if (line.contains('Instructions:')) {
        data['instructions'] = line.split(':').last.trim();
      }
    }
    return data;
  }

  String _buildSystemInstruction(String languageCode) {
    final languageInstruction = switch (languageCode) {
      'ms' =>
        'Reply in Bahasa Melayu unless the user explicitly asks for another language.',
      'zh' =>
        'Reply in Simplified Chinese unless the user explicitly asks for another language.',
      _ =>
        'Reply in English unless the user explicitly asks for another language.',
    };

    return 'You are MyUbat AI health assistant. '
        'You help users manage medications, appointments, and general health questions. '
        'You can analyze symptoms and images such as rashes or wounds. '
        'Always start with a medical disclaimer. '
        'If symptoms seem urgent, such as severe pain, difficulty breathing, or heavy bleeding, advise immediate emergency care. '
        'When appropriate, suggest the user visit a doctor or use the Find Hospital feature in the app. '
        '$languageInstruction '
        'Be empathetic, concise, and professional.';
  }

  String _fallbackProcessingMessage(String languageCode) {
    return switch (languageCode) {
      'ms' => 'Maaf, saya tidak dapat memproses permintaan itu.',
      'zh' => '抱歉，我无法处理该请求。',
      _ => 'I apologize, I could not process that request.',
    };
  }

  String _fallbackConnectionMessage(String languageCode) {
    return switch (languageCode) {
      'ms' =>
        'Maaf, saya menghadapi masalah sambungan. Sila cuba lagi kemudian.',
      'zh' => '抱歉，我目前连接异常，请稍后再试。',
      _ => 'Sorry, I am having trouble connecting. Please try again later.',
    };
  }
}

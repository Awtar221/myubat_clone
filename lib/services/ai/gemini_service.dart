import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/chat_message.dart';

class GeminiService {
  static const String _apiKey = '';
  
  static const String _primaryModel = 'gemini-2.5-flash';
  
  static const String _systemInstruction =
      "You are MyUbatPlus AI health assistant. You help users manage their medications, appointments, and general health queries. "
      "You can analyze symptoms and images (like rashes or wounds). "
      "CRITICAL: Always start with a medical disclaimer. "
      "If symptoms seem urgent (severe pain, difficulty breathing, heavy bleeding), advise immediate emergency care. "
      "When appropriate, suggest the user visit a doctor or use the 'Find Hospital' feature in the app. "
      "Be empathetic, concise, and professional.";

  Future<String> generateReply({
    required String userText,
    required String userContext,
    required List<ChatMessage> recentMessages,
    Uint8List? imageBytes,
  }) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty) throw StateError('API Key missing');

    final model = GenerativeModel(
      model: _primaryModel,
      apiKey: apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );

    final history = recentMessages.take(10).map((m) {
      return m.role == 'user' 
          ? Content.text('User: ${m.content}') 
          : Content.model([TextPart('Assistant: ${m.content}')]);
    }).toList();

    final promptParts = [
      TextPart('User Context: $userContext\n\nUser Question: $userText'),
      if (imageBytes != null) DataPart('image/jpeg', imageBytes),
    ];

    try {
      final response = await model.generateContent([
        ...history,
        Content.multi(promptParts),
      ]);
      return response.text?.trim() ?? 'I apologize, I could not process that request.';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Sorry, I am having trouble connecting. Please try again later.';
    }
  }

  Future<Map<String, String>> scanMedication(Uint8List imageBytes) async {
    final model = GenerativeModel(model: _primaryModel, apiKey: _apiKey);
    const prompt = 'Extract Medication Name, Dosage, and Instructions from this label. Format as Name: [val], Dosage: [val], Instructions: [val].';
    
    try {
      final response = await model.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ]);
      return _parseMedicationData(response.text ?? '');
    } catch (e) {
      return {'error': 'Failed to scan label'};
    }
  }

  Map<String, String> _parseMedicationData(String text) {
    final Map<String, String> data = {};
    for (var line in text.split('\n')) {
      if (line.contains('Name:')) data['name'] = line.split(':').last.trim();
      if (line.contains('Dosage:')) data['dosage'] = line.split(':').last.trim();
      if (line.contains('Instructions:')) data['instructions'] = line.split(':').last.trim();
    }
    return data;
  }
}

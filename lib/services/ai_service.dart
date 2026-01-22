import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = 'YOUR_CLAUDE_API_KEY_HERE'; // Replace with your key

  // AI Health Chat
  Future<String> getChatResponse(String message, List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': history.map((m) => {
            'role': m['role'],
            'content': m['content'],
          }).toList(),
          'system': '''You are a helpful medical AI assistant for MySejahtera app in Malaysia. 
          Provide health advice, symptom checking, vaccination info, and appointment guidance. 
          Be concise, helpful, and culturally sensitive. Support Malay and English languages.
          Always remind users to consult healthcare professionals for serious concerns.''',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        return 'Maaf, saya menghadapi masalah. Sila cuba lagi. (Sorry, I encountered an error. Please try again.)';
      }
    } catch (e) {
      return 'Ralat sambungan. Sila semak internet anda. (Connection error. Please check your internet.)';
    }
  }

  // AI Risk Assessment
  Future<Map<String, dynamic>> calculateRiskScore({
    required int totalDoses,
    required List<String> recentCheckIns,
    required String currentLocation,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    int baseScore = 100 - (totalDoses * 25).clamp(0, 75);
    int exposureScore = (recentCheckIns.length * 3).clamp(0, 20);
    int locationRisk = 5; // Simulated location risk

    int finalScore = (baseScore + exposureScore + locationRisk).clamp(0, 100);

    String riskLevel;
    if (finalScore < 30) {
      riskLevel = 'Low Risk';
    } else if (finalScore < 60) {
      riskLevel = 'Medium Risk';
    } else {
      riskLevel = 'High Risk';
    }

    List<String> recommendations = [];
    if (totalDoses < 3) {
      recommendations.add('Complete your vaccination schedule');
    }
    if (finalScore > 30) {
      recommendations.add('Maintain social distancing in public places');
      recommendations.add('Wear masks in crowded areas');
    }
    recommendations.add('Monitor your health daily');
    recommendations.add('Stay updated with health guidelines');

    return {
      'riskScore': finalScore,
      'riskLevel': riskLevel,
      'factors': {
        'vaccination': totalDoses >= 3 ? 'Complete' : 'Incomplete',
        'recentExposure': exposureScore < 10 ? 'Low' : exposureScore < 20 ? 'Moderate' : 'High',
        'areaCases': locationRisk < 10 ? 'Low' : 'Moderate',
      },
      'recommendations': recommendations,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // AI Appointment Optimization
  Future<List<Map<String, dynamic>>> getOptimalAppointments({
    required String location,
    required String appointmentType,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      {
        'date': DateTime.now().add(const Duration(days: 7)),
        'time': '10:30 AM',
        'predictedWaitTime': 15,
        'confidence': 'High',
        'reason': 'Low historical traffic at this time',
      },
      {
        'date': DateTime.now().add(const Duration(days: 7)),
        'time': '2:00 PM',
        'predictedWaitTime': 25,
        'confidence': 'Medium',
        'reason': 'Moderate expected crowd',
      },
      {
        'date': DateTime.now().add(const Duration(days: 8)),
        'time': '9:00 AM',
        'predictedWaitTime': 12,
        'confidence': 'High',
        'reason': 'Early morning slot, minimal wait',
      },
    ];
  }

  // Crowd Density Prediction
  Future<Map<String, dynamic>> getCrowdPrediction(String location) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final random = DateTime.now().second % 3;
    final densities = ['Low', 'Moderate', 'High'];
    final colors = ['green', 'orange', 'red'];

    return {
      'density': densities[random],
      'color': colors[random],
      'confidence': '${85 + random * 5}%',
      'recommendation': random == 0
          ? 'Good time to visit'
          : random == 1
          ? 'Consider visiting later'
          : 'Very crowded, visit another time',
    };
  }

  // Symptom Checker
  Future<Map<String, dynamic>> checkSymptoms(List<String> symptoms) async {
    await Future.delayed(const Duration(seconds: 1));

    bool hasCOVIDSymptoms = symptoms.any((s) =>
    s.toLowerCase().contains('fever') ||
        s.toLowerCase().contains('cough') ||
        s.toLowerCase().contains('fatigue')
    );

    return {
      'assessment': hasCOVIDSymptoms ? 'Potential COVID-19 symptoms detected' : 'Symptoms noted',
      'severity': hasCOVIDSymptoms ? 'Medium' : 'Low',
      'recommendations': hasCOVIDSymptoms
          ? ['Get tested for COVID-19', 'Self-isolate', 'Monitor temperature', 'Consult doctor if worsens']
          : ['Rest and stay hydrated', 'Monitor symptoms', 'Consult doctor if persists'],
      'shouldTest': hasCOVIDSymptoms,
    };
  }
}
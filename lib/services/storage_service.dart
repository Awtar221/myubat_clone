import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _checkInsKey = 'check_ins';
  static const String _appointmentsKey = 'appointments';
  static const String _riskAssessmentKey = 'risk_assessment';
  static const String _chatHistoryKey = 'chat_history';

  // Save user data
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Save check-in
  Future<void> saveCheckIn(Map<String, dynamic> checkIn) async {
    final prefs = await SharedPreferences.getInstance();
    final checkInsJson = prefs.getString(_checkInsKey);
    List<dynamic> checkIns = checkInsJson != null ? jsonDecode(checkInsJson) : [];
    checkIns.insert(0, checkIn); // Add to beginning

    // Keep only last 50 check-ins
    if (checkIns.length > 50) {
      checkIns = checkIns.sublist(0, 50);
    }

    await prefs.setString(_checkInsKey, jsonEncode(checkIns));
  }

  // Get all check-ins
  Future<List<dynamic>> getCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final checkInsJson = prefs.getString(_checkInsKey);
    return checkInsJson != null ? jsonDecode(checkInsJson) : [];
  }

  // Save appointments
  Future<void> saveAppointments(List<Map<String, dynamic>> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appointmentsKey, jsonEncode(appointments));
  }

  // Get appointments
  Future<List<dynamic>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getString(_appointmentsKey);
    return appointmentsJson != null ? jsonDecode(appointmentsJson) : [];
  }

  // Save risk assessment
  Future<void> saveRiskAssessment(Map<String, dynamic> assessment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_riskAssessmentKey, jsonEncode(assessment));
  }

  // Get risk assessment
  Future<Map<String, dynamic>?> getRiskAssessment() async {
    final prefs = await SharedPreferences.getInstance();
    final assessmentJson = prefs.getString(_riskAssessmentKey);
    return assessmentJson != null ? jsonDecode(assessmentJson) : null;
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
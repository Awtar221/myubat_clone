import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'https://api.mysejahtera.example.com';
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // User Authentication
  Future<Map<String, dynamic>> login(String ic, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'ic': ic,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get vaccination status
  Future<Map<String, dynamic>> getVaccinationStatus(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/vaccination');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get vaccination status: $e');
    }
  }

  // Submit check-in
  Future<Map<String, dynamic>> submitCheckIn(Map<String, dynamic> checkInData) async {
    try {
      final response = await _dio.post('/checkins', data: checkInData);
      return response.data;
    } catch (e) {
      throw Exception('Check-in failed: $e');
    }
  }

  // Get health status
  Future<Map<String, dynamic>> getHealthStatus(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/health-status');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get health status: $e');
    }
  }
}
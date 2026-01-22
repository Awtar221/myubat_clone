import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/risk_assessment_model.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  RiskAssessmentModel? _riskAssessment;
  bool _isLoading = false;

  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  UserModel? get user => _user;
  RiskAssessmentModel? get riskAssessment => _riskAssessment;
  bool get isLoading => _isLoading;

  // Initialize user data
  Future<void> initializeUser() async {
    _isLoading = true;
    notifyListeners();

    final userData = await _storageService.getUser();
    if (userData != null) {
      _user = UserModel.fromJson(userData);
      await updateRiskAssessment();
    } else {
      // Create demo user
      _user = UserModel(
        id: '1',
        name: 'Ahmad Abdullah',
        ic: '901234-56-7890',
        vaccineStatus: 'Fully Vaccinated',
        totalDoses: 3,
        vaccinationHistory: [
          VaccinationRecord(
            dose: '1st Dose',
            vaccine: 'Pfizer-BioNTech',
            date: DateTime(2021, 5, 15),
            location: 'PPV KLCC',
          ),
          VaccinationRecord(
            dose: '2nd Dose',
            vaccine: 'Pfizer-BioNTech',
            date: DateTime(2021, 6, 10),
            location: 'PPV KLCC',
          ),
          VaccinationRecord(
            dose: 'Booster',
            vaccine: 'Pfizer-BioNTech',
            date: DateTime(2022, 1, 18),
            location: 'Klinik Kesihatan Bangsar',
          ),
        ],
        lastCheckIn: 'Pavilion KL',
        lastCheckInTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      await _storageService.saveUser(_user!.toJson());
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update risk assessment using AI
  Future<void> updateRiskAssessment() async {
    if (_user == null) return;

    final checkIns = await _storageService.getCheckIns();
    final recentCheckIns = checkIns
        .map((e) => e['location'] as String)
        .toList();

    final riskData = await _aiService.calculateRiskScore(
      totalDoses: _user!.totalDoses,
      recentCheckIns: recentCheckIns,
      currentLocation: _user!.lastCheckIn ?? 'Unknown',
    );

    _riskAssessment = RiskAssessmentModel.fromJson(riskData);
    notifyListeners();
  }

  // Check in to location
  Future<void> checkIn(String location) async {
    final checkInData = {
      'location': location,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _storageService.saveCheckIn(checkInData);

    _user = UserModel(
      id: _user!.id,
      name: _user!.name,
      ic: _user!.ic,
      vaccineStatus: _user!.vaccineStatus,
      totalDoses: _user!.totalDoses,
      vaccinationHistory: _user!.vaccinationHistory,
      lastCheckIn: location,
      lastCheckInTime: DateTime.now(),
    );

    await updateRiskAssessment();
    notifyListeners();
  }
}
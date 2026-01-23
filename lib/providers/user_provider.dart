import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _name = 'Ahmad bin Abdullah';
  final String _icNumber = '901234-56-7890';
  String _phoneNumber = '+60123456789';
  String _email = 'ahmad@example.com';
  String _address = 'Kuala Lumpur, Malaysia';

  // Health Status
  String _healthStatus = 'Low Risk';
  Color _healthStatusColor = const Color(0xFF10B981);

  // Getters
  String get name => _name;
  String get icNumber => _icNumber;
  String get phoneNumber => _phoneNumber;
  String get email => _email;
  String get address => _address;
  String get healthStatus => _healthStatus;
  Color get healthStatusColor => _healthStatusColor;

  void updateProfile({
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
  }) {
    if (name != null) _name = name;
    if (phoneNumber != null) _phoneNumber = phoneNumber;
    if (email != null) _email = email;
    if (address != null) _address = address;
    notifyListeners();
  }

  void updateHealthStatus(String status, Color color) {
    _healthStatus = status;
    _healthStatusColor = color;
    notifyListeners();
  }
}

class HealthProvider with ChangeNotifier {
  final List<HealthRecord> _healthRecords = [
    HealthRecord(
      date: DateTime.now().subtract(const Duration(days: 2)),
      temperature: 36.5,
      symptoms: [],
    ),
    HealthRecord(
      date: DateTime.now().subtract(const Duration(days: 1)),
      temperature: 36.7,
      symptoms: [],
    ),
    HealthRecord(
      date: DateTime.now(),
      temperature: 36.6,
      symptoms: [],
    ),
  ];

  final List<VaccinationRecord> _vaccinationRecords = [
    VaccinationRecord(
      vaccineName: 'Pfizer-BioNTech',
      doseNumber: 1,
      date: DateTime(2021, 5, 15),
      location: 'PPV KLCC',
      batchNumber: 'FL3421',
    ),
    VaccinationRecord(
      vaccineName: 'Pfizer-BioNTech',
      doseNumber: 2,
      date: DateTime(2021, 7, 10),
      location: 'PPV KLCC',
      batchNumber: 'FL4532',
    ),
    VaccinationRecord(
      vaccineName: 'Pfizer-BioNTech Booster',
      doseNumber: 3,
      date: DateTime(2022, 1, 20),
      location: 'PPV Shah Alam',
      batchNumber: 'FL6789',
    ),
  ];

  final List<TestResult> _testResults = [
    TestResult(
      testType: 'RT-PCR',
      result: 'Negative',
      date: DateTime(2024, 12, 15),
      location: 'Klinik Kesihatan Bangsar',
    ),
  ];

  final List<CheckInRecord> _checkInHistory = [];

  List<HealthRecord> get healthRecords => _healthRecords;
  List<VaccinationRecord> get vaccinationRecords => _vaccinationRecords;
  List<TestResult> get testResults => _testResults;
  List<CheckInRecord> get checkInHistory => _checkInHistory;

  void addHealthRecord(HealthRecord record) {
    _healthRecords.add(record);
    notifyListeners();
  }

  void addCheckIn(CheckInRecord record) {
    _checkInHistory.insert(0, record);
    notifyListeners();
  }
}

class HealthRecord {
  final DateTime date;
  final double temperature;
  final List<String> symptoms;

  HealthRecord({
    required this.date,
    required this.temperature,
    required this.symptoms,
  });
}

class VaccinationRecord {
  final String vaccineName;
  final int doseNumber;
  final DateTime date;
  final String location;
  final String batchNumber;

  VaccinationRecord({
    required this.vaccineName,
    required this.doseNumber,
    required this.date,
    required this.location,
    required this.batchNumber,
  });
}

class TestResult {
  final String testType;
  final String result;
  final DateTime date;
  final String location;

  TestResult({
    required this.testType,
    required this.result,
    required this.date,
    required this.location,
  });
}

class CheckInRecord {
  final String locationName;
  final String address;
  final DateTime checkInTime;
  DateTime? checkOutTime;

  CheckInRecord({
    required this.locationName,
    required this.address,
    required this.checkInTime,
    this.checkOutTime,
  });
}
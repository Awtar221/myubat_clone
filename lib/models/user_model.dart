class UserModel {
  final String id;
  final String name;
  final String ic;
  final String vaccineStatus;
  final int totalDoses;
  final List<VaccinationRecord> vaccinationHistory;
  final String? lastCheckIn;
  final DateTime? lastCheckInTime;

  UserModel({
    required this.id,
    required this.name,
    required this.ic,
    required this.vaccineStatus,
    required this.totalDoses,
    required this.vaccinationHistory,
    this.lastCheckIn,
    this.lastCheckInTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      ic: json['ic'],
      vaccineStatus: json['vaccineStatus'],
      totalDoses: json['totalDoses'],
      vaccinationHistory: (json['vaccinationHistory'] as List)
          .map((e) => VaccinationRecord.fromJson(e))
          .toList(),
      lastCheckIn: json['lastCheckIn'],
      lastCheckInTime: json['lastCheckInTime'] != null
          ? DateTime.parse(json['lastCheckInTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ic': ic,
      'vaccineStatus': vaccineStatus,
      'totalDoses': totalDoses,
      'vaccinationHistory': vaccinationHistory.map((e) => e.toJson()).toList(),
      'lastCheckIn': lastCheckIn,
      'lastCheckInTime': lastCheckInTime?.toIso8601String(),
    };
  }
}

class VaccinationRecord {
  final String dose;
  final String vaccine;
  final DateTime date;
  final String location;

  VaccinationRecord({
    required this.dose,
    required this.vaccine,
    required this.date,
    required this.location,
  });

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    return VaccinationRecord(
      dose: json['dose'],
      vaccine: json['vaccine'],
      date: DateTime.parse(json['date']),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dose': dose,
      'vaccine': vaccine,
      'date': date.toIso8601String(),
      'location': location,
    };
  }
}
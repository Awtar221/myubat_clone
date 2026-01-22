class AppointmentModel {
  final String id;
  final String type;
  final String location;
  final DateTime date;
  final String time;
  final int predictedWaitTime;
  final String status;
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.type,
    required this.location,
    required this.date,
    required this.time,
    required this.predictedWaitTime,
    required this.status,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      type: json['type'],
      location: json['location'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      predictedWaitTime: json['predictedWaitTime'],
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'location': location,
      'date': date.toIso8601String(),
      'time': time,
      'predictedWaitTime': predictedWaitTime,
      'status': status,
      'notes': notes,
    };
  }
}
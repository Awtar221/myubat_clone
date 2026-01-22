class CheckInModel {
  final String id;
  final String location;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? crowdDensity;

  CheckInModel({
    required this.id,
    required this.location,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.crowdDensity,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'],
      location: json['location'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      crowdDensity: json['crowdDensity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'crowdDensity': crowdDensity,
    };
  }
}
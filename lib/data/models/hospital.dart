import 'package:google_maps_flutter/google_maps_flutter.dart';

class Hospital {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double rating;
  final double distance; // in km
  final String busyness; // Replaced estimatedWaitTime with busyness
  final String type;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.rating,
    required this.distance,
    required this.busyness,
    required this.type,
  });

  factory Hospital.fromMap(Map<String, dynamic> map, LatLng userLocation, double distance) {
    final List types = map['types'] ?? [];
    String displayType = 'Healthcare Facility';
    if (types.contains('hospital')) {
      displayType = 'Hospital';
    } else if (types.contains('clinic')) {
      displayType = 'Clinic';
    } else if (types.contains('health')) {
      displayType = 'Health Centre';
    }

    return Hospital(
      id: map['place_id'] ?? '',
      name: map['name'] ?? '',
      address: map['vicinity'] ?? '',
      location: LatLng(
        map['geometry']['location']['lat'],
        map['geometry']['location']['lng'],
      ),
      rating: (map['rating'] ?? 0.0).toDouble(),
      distance: distance,
      busyness: _calculateBusyness(map['rating'] ?? 0.0, displayType),
      type: displayType,
    );
  }

  static String _calculateBusyness(num rating, String type) {
    final now = DateTime.now();
    int score = 0;

    // 1. Facility Type Factor
    if (type == 'Hospital') {
      score += 3;
    } else if (type == 'Clinic') {
      score += 1;
    }

    // 2. Day of Week Factor
    if (now.weekday == DateTime.monday) {
      score += 2;
    } else if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      score += 1;
    }

    // 3. Peak Hour Factor
    if (now.hour >= 8 && now.hour <= 11) {
      score += 4;
    } else if (now.hour >= 18 && now.hour <= 21) {
      score += 3;
    } else if (now.hour >= 0 && now.hour <= 5) {
      score -= 2;
    }

    // 4. Rating as proxy
    if (rating >= 4.5) {
      score += 3;
    } else if (rating >= 3.5) {
      score += 2;
    } else if (rating > 0) {
      score += 1;
    }

    if (score >= 10) {
      return 'Very Busy';
    }
    if (score >= 7) {
      return 'Busy';
    }
    if (score >= 4) {
      return 'Moderate';
    }
    if (score >= 1) {
      return 'Quiet';
    }
    return 'Not Busy';
  }
}

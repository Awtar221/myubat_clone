import 'package:google_maps_flutter/google_maps_flutter.dart';

class Hospital {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double rating;
  final double distance; // in km
  final String busyness;
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
    final String name = map['name'] ?? '';
    final List types = map['types'] ?? [];
    
    String displayType = _detectType(name, types);

    return Hospital(
      id: map['place_id'] ?? '',
      name: name,
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

  static String _detectType(String name, List types) {
    final lowerName = name.toLowerCase();
    
    // Check Pharmacy/Farmasi
    if (types.contains('pharmacy') || 
        lowerName.contains('pharmacy') || 
        lowerName.contains('farmasi')) {
      return 'Pharmacy';
    }
    
    // Check Hospital
    if (types.contains('hospital') || 
        lowerName.contains('hospital')) {
      return 'Hospital';
    }
    
    // Check Clinic/Klinik
    if (types.contains('clinic') || 
        lowerName.contains('clinic') || 
        lowerName.contains('klinik')) {
      return 'Clinic';
    }
    
    return 'Others';
  }

  static String _calculateBusyness(num rating, String type) {
    final now = DateTime.now();
    int score = 0;

    if (type == 'Hospital') {
      score += 3;
    } else if (type == 'Clinic') {
      score += 1;
    }

    if (now.weekday == DateTime.monday) {
      score += 2;
    } else if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      score += 1;
    }

    if (now.hour >= 8 && now.hour <= 11) {
      score += 4;
    } else if (now.hour >= 18 && now.hour <= 21) {
      score += 3;
    } else if (now.hour >= 0 && now.hour <= 5) {
      score -= 2;
    }

    if (rating >= 4.5) {
      score += 3;
    } else if (rating >= 3.5) {
      score += 2;
    } else if (rating > 0) {
      score += 1;
    }

    if (score >= 10) return 'Very Busy';
    if (score >= 7) return 'Busy';
    if (score >= 4) return 'Moderate';
    if (score >= 1) return 'Quiet';
    return 'Not Busy';
  }
}

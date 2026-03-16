import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../data/models/hospital.dart';

class HospitalService {
  Future<List<Hospital>> getNearestHospitals(LatLng userLocation) async {
    final apiKey = AppConfig.googleMapsApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint(AppConfig.missingGoogleMapsApiKeyMessage);
      return [];
    }

    // Search for hospitals, clinics, and doctor offices
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=10000'
        '&type=hospital|clinic|doctor|health'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        List<Hospital> hospitals = results.map((item) {
          final hospitalLoc = LatLng(
            item['geometry']['location']['lat'],
            item['geometry']['location']['lng'],
          );
          final distance = _calculateDistance(userLocation, hospitalLoc);
          return Hospital.fromMap(item, userLocation, distance);
        }).toList();

        // Sort by distance and take top 10 nearest
        hospitals.sort((a, b) => a.distance.compareTo(b.distance));
        return hospitals.take(10).toList();
      } else {
        debugPrint('Google Maps API Error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching hospitals: $e');
      return [];
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}

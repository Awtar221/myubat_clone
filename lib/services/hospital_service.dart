import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/hospital.dart';
import '../config/app_config.dart';

class HospitalService {
  final String _apiKey = AppConfig.googleMapsApiKey;

  Future<List<Hospital>> getNearestHospitals(LatLng userLocation) async {
    // To get up to 50 results per category, we search specifically for each.
    // Google Places API returns max 20 per request, but we can try to get more via keywords.
    
    final List<String> queries = [
      'type=hospital&keyword=hospital', 
      'type=pharmacy&keyword=pharmacy|farmasi',
      'type=clinic&keyword=clinic|klinik',
      'keyword=medical|health|doctor', // For "Others"
    ];

    try {
      final List<http.Response> responses = await Future.wait(
        queries.map((q) => http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=${userLocation.latitude},${userLocation.longitude}'
          '&radius=10000' // 10km radius
          '&$q'
          '&key=$_apiKey'
        )))
      );

      List<Hospital> allResults = [];
      Set<String> seenIds = {};

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['results'] ?? [];

          for (var item in results) {
            final String id = item['place_id'] ?? '';
            if (!seenIds.contains(id)) {
              seenIds.add(id);
              final hospitalLoc = LatLng(
                item['geometry']['location']['lat'],
                item['geometry']['location']['lng'],
              );
              final distance = _calculateDistance(userLocation, hospitalLoc);
              allResults.add(Hospital.fromMap(item, userLocation, distance));
            }
          }
        }
      }

      // Sort by distance
      allResults.sort((a, b) => a.distance.compareTo(b.distance));
      
      return allResults;
    } catch (e) {
      debugPrint('Error fetching healthcare: $e');
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

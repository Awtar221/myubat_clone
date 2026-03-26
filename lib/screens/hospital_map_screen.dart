import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hospital_service.dart';
import '../data/models/hospital.dart';
import '../constants/app_colors.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  late GoogleMapController _mapController;
  final HospitalService _hospitalService = HospitalService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  LatLng? _currentPosition;
  List<Hospital> _hospitals = [];
  List<Hospital> _filteredHospitals = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  Hospital? _selectedHospital;
  String _selectedType = 'All';

  final List<String> _types = ['All', 'Hospital', 'Pharmacy', 'Clinic', 'Others'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied');
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (_currentPosition != null) {
      _fetchHospitals();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _fetchHospitals() async {
    if (_currentPosition == null) return;

    final hospitals = await _hospitalService.getNearestHospitals(_currentPosition!);
    
    setState(() {
      _hospitals = hospitals;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      List<Hospital> results;
      if (_selectedType == 'All') {
        results = List.from(_hospitals);
      } else {
        results = _hospitals.where((h) => h.type == _selectedType).toList();
      }

      // Sort by distance and limit to 50 results
      results.sort((a, b) => a.distance.compareTo(b.distance));
      _filteredHospitals = results.take(50).toList();

      _markers = _filteredHospitals.map((h) => Marker(
        markerId: MarkerId(h.id),
        position: h.location,
        onTap: () {
          _onHospitalSelected(h);
        },
      )).toSet();

      if (_currentPosition != null) {
        _markers.add(Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ));
      }
    });
  }

  void _onHospitalSelected(Hospital hospital) {
    setState(() {
      _selectedHospital = hospital;
    });
    
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(hospital.location, 16),
    );

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.12, 
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openInGoogleMaps(Hospital hospital) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${hospital.location.latitude},${hospital.location.longitude}&query_place_id=${hospital.id}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Healthcare'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: (_) {
                    setState(() {
                      _selectedHospital = null;
                    });
                  },
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _types.map((type) {
                        final isSelected = _selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = type;
                                _applyFilter();
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                if (_selectedHospital != null)
                  Positioned(
                    top: 80,
                    left: 20,
                    right: 20,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedHospital!.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() => _selectedHospital = null),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedHospital!.rating.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.trending_up, color: _getBusynessColor(_selectedHospital!.busyness), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedHospital!.busyness,
                                  style: TextStyle(
                                    color: _getBusynessColor(_selectedHospital!.busyness),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedHospital!.address,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openInGoogleMaps(_selectedHospital!),
                                icon: const Icon(Icons.map),
                                label: const Text('OPEN IN GOOGLE MAPS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.3,
                  minChildSize: 0.12,
                  maxChildSize: 0.85,
                  snap: true,
                  snapSizes: const [0.12, 0.3, 0.85],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              height: 85,
                              child: GestureDetector(
                                onVerticalDragUpdate: (details) {
                                  final double delta = details.primaryDelta! / MediaQuery.of(context).size.height;
                                  _sheetController.jumpTo(
                                    (_sheetController.size - delta).clamp(0.12, 0.85),
                                  );
                                },
                                onVerticalDragEnd: (details) {
                                  final double currentSize = _sheetController.size;
                                  final List<double> snapSizes = [0.12, 0.3, 0.85];
                                  double closestSize = snapSizes[0];
                                  double minDistance = (currentSize - snapSizes[0]).abs();
                                  
                                  for (var size in snapSizes) {
                                    double distance = (currentSize - size).abs();
                                    if (distance < minDistance) {
                                      minDistance = distance;
                                      closestSize = size;
                                    }
                                  }
                                  
                                  _sheetController.animateTo(
                                    closestSize,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Container(
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        width: double.infinity,
                                        child: Center(
                                          child: Container(
                                            height: 5,
                                            width: 45,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(2.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _selectedType == 'All' ? 'Nearest Facilities' : 'Nearest $_selectedType',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${_filteredHospitals.length} found',
                                                style: const TextStyle(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final hospital = _filteredHospitals[index];
                                return _buildHospitalListItem(hospital);
                              },
                              childCount: _filteredHospitals.length,
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 50),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton(
          onPressed: () {
            _mapController.animateCamera(
              CameraUpdate.newLatLngZoom(_currentPosition!, 14),
            );
          },
          backgroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.my_location, color: AppColors.primaryColor),
        ),
      ),
    );
  }

  Widget _buildHospitalListItem(Hospital hospital) {
    final bool isSelected = _selectedHospital?.id == hospital.id;

    return InkWell(
      onTap: () => _onHospitalSelected(hospital),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(hospital.type),
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${hospital.distance.toStringAsFixed(1)} km • ${hospital.type}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hospital.busyness,
                  style: TextStyle(
                    color: _getBusynessColor(hospital.busyness),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type == 'Hospital') return Icons.local_hospital;
    if (type == 'Clinic') return Icons.medical_services;
    if (type == 'Pharmacy') return Icons.local_pharmacy;
    return Icons.health_and_safety;
  }

  Color _getBusynessColor(String status) {
    switch (status) {
      case 'Quiet':
      case 'Not Busy':
        return AppColors.success;
      case 'Moderate':
        return AppColors.warning;
      case 'Busy':
      case 'Very Busy':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

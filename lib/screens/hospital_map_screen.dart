import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/hospital_card.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  bool _showMap = true;
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _hospitals = [
    {
      'name': 'Hospital Kuala Lumpur',
      'distance': '2.3 km',
      'waitingTime': '15 mins',
      'waitingStatus': 'low', // low, medium, high
      'avgWaitingTime': '12 mins',
      'peakHours': '10:00 AM - 12:00 PM',
      'rating': 4.5,
      'type': 'Government',
      'emergency': true,
      'beds': 45,
      'currentQueue': 8,
      'departments': ['Emergency', 'Cardiology', 'Pediatrics'],
    },
    {
      'name': 'Hospital Universiti Kebangsaan Malaysia',
      'distance': '4.1 km',
      'waitingTime': '25 mins',
      'waitingStatus': 'medium',
      'avgWaitingTime': '20 mins',
      'peakHours': '9:00 AM - 11:00 AM',
      'rating': 4.7,
      'type': 'Government',
      'emergency': true,
      'beds': 32,
      'currentQueue': 15,
      'departments': ['Emergency', 'Oncology', 'Neurology'],
    },
    {
      'name': 'Klinik Kesihatan Cheras',
      'distance': '1.8 km',
      'waitingTime': '8 mins',
      'waitingStatus': 'low',
      'avgWaitingTime': '10 mins',
      'peakHours': '8:00 AM - 9:00 AM',
      'rating': 4.2,
      'type': 'Clinic',
      'emergency': false,
      'beds': 12,
      'currentQueue': 4,
      'departments': ['General', 'Vaccination'],
    },
    {
      'name': 'Hospital Tunku Azizah',
      'distance': '5.6 km',
      'waitingTime': '35 mins',
      'waitingStatus': 'high',
      'avgWaitingTime': '30 mins',
      'peakHours': '2:00 PM - 4:00 PM',
      'rating': 4.6,
      'type': 'Specialist',
      'emergency': true,
      'beds': 28,
      'currentQueue': 22,
      'departments': ['Maternity', 'Pediatrics', 'NICU'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals'),
        backgroundColor: AppColors.mapColor,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search hospitals, clinics...',
                prefixIcon: const Icon(Icons.search, color: AppColors.mapColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: AppColors.mapColor),
                  onPressed: () {
                    // Get current location
                  },
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Emergency'),
                  _buildFilterChip('Clinic'),
                  _buildFilterChip('Hospital'),
                  _buildFilterChip('Specialist'),
                ],
              ),
            ),
          ),

          // Map or List View
          Expanded(
            child: _showMap ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show route options
        },
        backgroundColor: AppColors.mapColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.directions),
        label: const Text('Get Directions'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Color.fromARGB(51, 211, 47, 47),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.mapColor : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: AppColors.mapColor,
        side: BorderSide(
          color: isSelected ? AppColors.mapColor : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Placeholder Map
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 10),
                Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Google Maps integration here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hospital Markers Info (Bottom Sheet Preview)
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: const [0.3, 0.6, 0.85],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      // Allow dragging on the handle
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby Facilities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_hospitals.length} found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: _hospitals.length,
                      itemBuilder: (context, index) {
                        return HospitalCard(
                          hospital: _hospitals[index],
                          onTap: () {
                            _showHospitalDetails(_hospitals[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _hospitals.length,
      itemBuilder: (context, index) {
        return HospitalCard(
          hospital: _hospitals[index],
          onTap: () {
            _showHospitalDetails(_hospitals[index]);
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.local_hospital),
                title: const Text('Emergency Services'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: AppColors.mapColor,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Sort by Waiting Time'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Sort by Rating'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.route),
                title: const Text('Sort by Distance'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showHospitalDetails(Map<String, dynamic> hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      hospital['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 5),
                        Text(
                          '${hospital['rating']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hospital['type'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // WAITING TIME SECTION - PROMINENT DISPLAY
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getWaitingTimeColor(hospital['waitingStatus']),
                            _getWaitingTimeColor(hospital['waitingStatus']).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: _getWaitingTimeColor(hospital['waitingStatus']).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time_filled,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Wait Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    hospital['waitingTime'],
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getWaitingTimeLabel(hospital['waitingStatus']),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Waiting Time Analytics
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildWaitingTimeStat(
                                Icons.history,
                                'Avg Wait',
                                hospital['avgWaitingTime'],
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: AppColors.primaryColor.withValues(alpha:0.2),
                              ),
                              _buildWaitingTimeStat(
                                Icons.people_outline,
                                'In Queue',
                                '${hospital['currentQueue']} people',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 18,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Peak Hours',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      hospital['peakHours'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Basic Information
                    const Text(
                      'Hospital Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Distance', hospital['distance']),
                    _buildInfoRow(Icons.bed, 'Available Beds', '${hospital['beds']} beds'),
                    if (hospital['emergency'])
                      _buildInfoRow(Icons.emergency, 'Emergency', 'Available'),

                    const SizedBox(height: 20),
                    const Text(
                      'Departments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (hospital['departments'] as List<String>)
                          .map((dept) => Chip(
                        label: Text(dept),
                        backgroundColor: AppColors.lightGreen,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                        ),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mapColor,
                              padding: const EdgeInsets.symmetric(vertical: 15)
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.mapColor,
                              side: const BorderSide(color: AppColors.mapColor),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWaitingTimeStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.mapColor),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get waiting time color based on status
  Color _getWaitingTimeColor(String status) {
    switch (status) {
      case 'low':
        return AppColors.success; // Green: <15 mins
      case 'medium':
        return AppColors.warning; // Yellow: 15-30 mins
      case 'high':
        return AppColors.error; // Red: >30 mins
      default:
        return AppColors.textSecondary;
    }
  }

  // Helper method to get waiting time text color
  String _getWaitingTimeLabel(String status) {
    switch (status) {
      case 'low':
        return 'Low Wait';
      case 'medium':
        return 'Moderate Wait';
      case 'high':
        return 'Long Wait';
      default:
        return 'Unknown';
    }
  }
}
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'doctor': 'Dr. Ahmad Hassan',
      'specialty': 'General Practitioner',
      'hospital': 'Hospital Kuala Lumpur',
      'date': '2026-02-05',
      'time': '10:30 AM',
      'type': 'Follow-up',
      'status': 'Confirmed',
    },
    {
      'doctor': 'Dr. Sarah Lee',
      'specialty': 'Endocrinologist',
      'hospital': 'Hospital Universiti',
      'date': '2026-02-12',
      'time': '2:00 PM',
      'type': 'Consultation',
      'status': 'Pending',
    },
  ];

  final List<Map<String, dynamic>> _pastAppointments = [
    {
      'doctor': 'Dr. Ahmad Hassan',
      'specialty': 'General Practitioner',
      'hospital': 'Hospital Kuala Lumpur',
      'date': '2026-01-20',
      'time': '11:00 AM',
      'type': 'Check-up',
      'status': 'Completed',
    },
    {
      'doctor': 'Dr. Lim Wei',
      'specialty': 'Dentist',
      'hospital': 'Klinik Pergigian',
      'date': '2026-01-10',
      'time': '3:30 PM',
      'type': 'Dental Cleaning',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.appointmentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // Show calendar view
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.appointmentColor,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.appointmentColor,
                tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUpcomingAppointments(),
                  _buildPastAppointments(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBookAppointmentDialog,
        backgroundColor: AppColors.appointmentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_upcomingAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 15),
            Text(
              'No upcoming appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _upcomingAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_upcomingAppointments[index], true);
      },
    );
  }

  Widget _buildPastAppointments() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _pastAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_pastAppointments[index], false);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, bool isUpcoming) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment, isUpcoming),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.appointmentColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUpcoming ? Icons.event : Icons.event_available,
                      color: AppColors.appointmentColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['doctor'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          appointment['specialty'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(appointment['status']),
                ],
              ),
              const Divider(height: 25),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      appointment['hospital'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text(
                    appointment['date'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text(
                    appointment['time'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text(
                    'Type: ${appointment['type']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (isUpcoming) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.appointmentColor,
                          side: const BorderSide(color: AppColors.appointmentColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Reschedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appointmentColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.success;
        label = 'Confirmed';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'Pending';
        break;
      case 'completed':
        color = AppColors.info;
        label = 'Completed'; // Added the missing assignment
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // alpha: 0.1 gives you that nice 10% tinted background
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4), // 40% opacity border
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color, // The full-strength color for the text
        ),
      ),
    );
  }



  void _showAppointmentDetails(Map<String, dynamic> appointment, bool isUpcoming) {
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
          maxChildSize: 0.9,
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
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailItem(Icons.person, 'Doctor', appointment['doctor']),
                    _buildDetailItem(Icons.medical_services, 'Specialty', appointment['specialty']),
                    _buildDetailItem(Icons.location_on, 'Hospital', appointment['hospital']),
                    _buildDetailItem(Icons.calendar_today, 'Date', appointment['date']),
                    _buildDetailItem(Icons.access_time, 'Time', appointment['time']),
                    _buildDetailItem(Icons.category, 'Type', appointment['type']),
                    _buildDetailItem(Icons.info, 'Status', appointment['status']),
                    const SizedBox(height: 25),
                    if (isUpcoming) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm Appointment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Appointment'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.appointmentColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookAppointmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Book New Appointment',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Doctor Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Hospital / Clinic',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.local_hospital),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () {
                      // Show date picker
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () {
                      // Show time picker
                    },
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appointmentColor,
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
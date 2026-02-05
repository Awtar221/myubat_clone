import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/medication_list_card.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _activeMedications = [
    {
      'name': 'Paracetamol 500mg',
      'dosage': '1 tablet',
      'frequency': '3 times daily',
      'nextDose': '2:00 PM',
      'stock': 15,
      'prescribedBy': 'Dr. Ahmad',
      'startDate': '2026-01-15',
      'endDate': '2026-02-15',
    },
    {
      'name': 'Metformin 850mg',
      'dosage': '2 tablets',
      'frequency': 'Twice daily',
      'nextDose': '8:00 PM',
      'stock': 30,
      'prescribedBy': 'Dr. Sarah',
      'startDate': '2025-12-01',
      'endDate': 'Ongoing',
    },
    {
      'name': 'Vitamin C 1000mg',
      'dosage': '1 tablet',
      'frequency': 'Once daily',
      'nextDose': 'Tomorrow 9:00 AM',
      'stock': 25,
      'prescribedBy': 'Self',
      'startDate': '2026-01-01',
      'endDate': '2026-03-01',
    },
  ];

  final List<Map<String, dynamic>> _completedMedications = [
    {
      'name': 'Amoxicillin 500mg',
      'dosage': '1 capsule',
      'frequency': '3 times daily',
      'completedDate': '2026-01-20',
      'prescribedBy': 'Dr. Ahmad',
    },
    {
      'name': 'Cough Syrup',
      'dosage': '10ml',
      'frequency': 'As needed',
      'completedDate': '2026-01-10',
      'prescribedBy': 'Dr. Lee',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        backgroundColor: AppColors.medicationColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textLight,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveMedications(),
          _buildCompletedMedications(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationDialog,
        backgroundColor: AppColors.medicationColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildActiveMedications() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics Card
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(204, 123, 31, 162),
                  AppColors.medicationColor,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(77, 123, 31, 162),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Active', '${_activeMedications.length}'),
                Container(
                  height: 40,
                  width: 1,
                  color: Color.fromARGB(77, 255, 255, 255),
                ),
                _buildStatItem('Today', '3'),
                Container(
                  height: 40,
                  width: 1,
                  color: Color.fromARGB(77, 255, 255, 255),
                ),
                _buildStatItem('Adherence', '92%'),
              ],
            ),
          ),

          // Medications List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Medications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeMedications.length,
                  itemBuilder: (context, index) {
                    return MedicationListCard(
                      medication: _activeMedications[index],
                      onTap: () {
                        _showMedicationDetails(_activeMedications[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompletedMedications() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _completedMedications.length,
      itemBuilder: (context, index) {
        final medication = _completedMedications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 30,
              ),
            ),
            title: Text(
              medication['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text('Completed: ${medication['completedDate']}'),
                Text('Prescribed by: ${medication['prescribedBy']}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              color: AppColors.medicationColor,
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _showMedicationDetails(Map<String, dynamic> medication) {
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(26, 123, 31, 162),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.medication,
                            size: 40,
                            color: AppColors.medicationColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Prescribed by ${medication['prescribedBy']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildDetailRow('Dosage', medication['dosage']),
                    _buildDetailRow('Frequency', medication['frequency']),
                    _buildDetailRow('Next Dose', medication['nextDose']),
                    _buildDetailRow('Stock Remaining', '${medication['stock']} doses'),
                    _buildDetailRow('Start Date', medication['startDate']),
                    _buildDetailRow('End Date', medication['endDate']),
                    const SizedBox(height: 25),
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Taken'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.medicationColor,
                              side: const BorderSide(color: AppColors.medicationColor),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove Medication'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
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

  void _showAddMedicationDialog() {
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
                    'Add Medication',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Medication Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.medication),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.science),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.schedule),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.medicationColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Medication',
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
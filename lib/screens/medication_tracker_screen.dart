import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/medication.dart';
import '../data/repositories/medication_repository.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() =>
      _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
  TabController(length: 2, vsync: this);
  final MedicationRepository _medicationRepository = MedicationRepository();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddMedicationDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveMedication() async {
              final name = nameController.text.trim();
              final scheduleTimes =
              _extractScheduleTimes(frequencyController.text);
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medication name is required.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              try {
                final medication = Medication(
                  name: name,
                  dosage: dosageController.text.trim().isEmpty
                      ? null
                      : dosageController.text.trim(),
                  instructions: frequencyController.text.trim().isEmpty
                      ? null
                      : frequencyController.text.trim(),
                  scheduleTimes: scheduleTimes,
                  startDate: Timestamp.now(),
                  isActive: true,
                );
                await _medicationRepository.upsertMedication(uid, medication);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              } finally {
                setModalState(() {
                  isSaving = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Medication',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Medication Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.medication_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.science_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: frequencyController,
                    decoration: InputDecoration(
                      labelText: 'Schedule Times',
                      hintText: '09:00, 14:00, 20:00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.schedule),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveMedication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.medicationColor,
                      ),
                      child: isSaving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text('Add Medication'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _extractScheduleTimes(String raw) {
    final normalized = <String>[];
    final segments = raw
        .split(RegExp(r'[,;\n]'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty);

    for (final segment in segments) {
      final parsed = _tryParseTo24Hour(segment);
      if (parsed == null) {
        continue;
      }
      if (!normalized.contains(parsed)) {
        normalized.add(parsed);
      }
    }

    if (normalized.isEmpty) {
      return const <String>['09:00'];
    }
    return normalized;
  }

  String? _tryParseTo24Hour(String input) {
    final hhmm = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(input);
    if (hhmm != null) {
      final hour = int.parse(hhmm.group(1)!);
      final minute = int.parse(hhmm.group(2)!);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    final amPm = RegExp(
      r'^([1-9]|1[0-2]):([0-5]\d)\s*([AaPp][Mm])$',
    ).firstMatch(input);
    if (amPm != null) {
      final hour12 = int.parse(amPm.group(1)!);
      final minute = int.parse(amPm.group(2)!);
      final suffix = amPm.group(3)!.toLowerCase();
      final hour24 = (hour12 % 12) + (suffix == 'pm' ? 12 : 0);
      return '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return null;
  }

  Future<void> _toggleTaken(
      String uid, Medication medication, bool isTaken) async {
    final updated = Medication(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      instructions: medication.instructions,
      times: medication.times,
      startDate: medication.startDate,
      endDate: medication.endDate,
      isActive: !isTaken,
      createdAt: medication.createdAt,
      updatedAt: medication.updatedAt,
    );
    await _medicationRepository.upsertMedication(uid, updated);
  }

  Future<void> _deleteMedication(String uid, String medicationId) async {
    await _medicationRepository.deleteMedication(uid, medicationId);
  }

  Widget _buildMedicationCard({
    required String uid,
    required Medication medication,
    required bool isCompletedList,
  }) {
    final subtitle =
        medication.dosage ?? medication.instructions ?? 'No dosage specified';
    final details = medication.instructions ??
        (medication.times.isNotEmpty ? medication.times.join(', ') : '-');

    return Dismissible(
      key: ValueKey(medication.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteMedication(uid, medication.id);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Checkbox(
            value: isCompletedList,
            onChanged: (value) {
              _toggleTaken(uid, medication, value ?? false);
            },
            activeColor: AppColors.success,
          ),
          title: Text(
            medication.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle),
              Text('Instructions: $details'),
            ],
          ),
          trailing: Icon(
            isCompletedList ? Icons.check_circle : Icons.medication_outlined,
            color:
            isCompletedList ? AppColors.success : AppColors.medicationColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view medications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        backgroundColor: AppColors.medicationColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<Medication>>(
        stream: _medicationRepository.listMedicationsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load medications.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? const <Medication>[];
          final active = all.where((m) => m.isActive).toList(growable: false);
          final completed =
          all.where((m) => !m.isActive).toList(growable: false);

          Widget buildList(List<Medication> items, bool completedList) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  completedList
                      ? 'No completed medications'
                      : 'No active medications',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildMedicationCard(
                uid: uid,
                medication: items[index],
                isCompletedList: completedList,
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              buildList(active, false),
              buildList(completed, true),
            ],
          );
        },
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
}

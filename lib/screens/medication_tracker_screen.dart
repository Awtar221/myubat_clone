import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../data/models/medication.dart';
import '../data/models/today_intake_item.dart';
import '../data/repositories/medication_repository.dart';
import '../l10n/app_strings.dart';
import '../services/ai/gemini_service.dart';
import '../services/notification/notification_service.dart';
import '../widgets/medication_reminder_card.dart';

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
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final Set<String> _pendingToggles = {};

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleIntake(String uid, TodayIntakeItem item) async {
    final key = '${item.medicationId}:${item.intakeId}';
    if (_pendingToggles.contains(key)) return;

    setState(() => _pendingToggles.add(key));
    try {
      await _medicationRepository.toggleIntakeTaken(
        uid,
        item.medicationId,
        item.intakeId,
        !item.taken,
      );
    } finally {
      if (mounted) setState(() => _pendingToggles.remove(key));
    }
  }

  Future<void> _deleteMedication(String uid, String medicationId) async {
    await _medicationRepository.deleteMedication(uid, medicationId);
  }

  Future<void> _scanMedicationLabel(
      Function(Map<String, String>) onScanned) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.strings.text('aiAnalyzingLabel')),
                ],
              ),
            ),
          ),
        ),
      );

      final bytes = await image.readAsBytes();
      final result = await _geminiService.scanMedication(bytes);

      if (!mounted) return;
      Navigator.pop(context);

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error']!),
              backgroundColor: AppColors.error),
        );
      } else {
        onScanned(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showAddMedicationDialog(
      {Medication? existingMedication,
      Map<String, String>? initialData}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final initialIntakeDateTime =
        existingMedication?.intakeDateTime?.toDate() ??
            existingMedication?.startDate?.toDate() ??
            DateTime.now().add(const Duration(hours: 1));

    final nameController = TextEditingController(
        text: existingMedication?.name ?? initialData?['name']);
    final dosageController = TextEditingController(
        text: existingMedication?.dosage ?? initialData?['dosage']);
    final frequencyController = TextEditingController(
        text: existingMedication?.instructions ?? initialData?['instructions']);
    final timeController = TextEditingController(
        text: existingMedication?.times.isNotEmpty == true
            ? existingMedication!.times.first
            : '${initialIntakeDateTime.hour.toString().padLeft(2, '0')}:${initialIntakeDateTime.minute.toString().padLeft(2, '0')}');

    bool isSaving = false;
    bool remindersEnabled = existingMedication?.remindersEnabled ?? true;
    DateTime selectedIntakeDateTime = initialIntakeDateTime;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              existingMedication == null
                                  ? 'Add Medication'
                                  : 'Edit Medication',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          if (existingMedication == null && initialData == null)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _scanMedicationLabel((data) =>
                                    _showAddMedicationDialog(
                                        initialData: data));
                              },
                              icon: const Icon(Icons.camera_alt, size: 20),
                              label: const Text('AI Scan'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.medicationColor),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                          controller: nameController,
                          label: 'Medication Name',
                          icon: Icons.medication_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: dosageController,
                          label: 'Dosage',
                          icon: Icons.science_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: frequencyController,
                          label: 'Instructions',
                          hint: 'e.g., Take after meal',
                          icon: Icons.info_outline),
                      const SizedBox(height: 16),
                      TextField(
                        controller: timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Schedule Time',
                          hintText: 'Tap to set time',
                          prefixIcon: const Icon(Icons.schedule,
                              color: AppColors.medicationColor),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedIntakeDateTime,
                            ),
                          );
                          if (picked != null) {
                            final timeString =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            setModalState(() {
                              timeController.text = timeString;
                              selectedIntakeDateTime = DateTime(
                                selectedIntakeDateTime.year,
                                selectedIntakeDateTime.month,
                                selectedIntakeDateTime.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedIntakeDateTime,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3),
                            ),
                          );
                          if (date == null || !context.mounted) {
                            return;
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedIntakeDateTime,
                            ),
                          );
                          if (time == null) {
                            return;
                          }
                          setModalState(() {
                            selectedIntakeDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            timeController.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Intake Date & Time',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.medicationColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          child: Text(_formatDateTime(selectedIntakeDateTime)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminders'),
                        subtitle: const Text(
                          'Reminds you 3h, 1h, 30m before',
                        ),
                        value: remindersEnabled,
                        activeThumbColor: AppColors.medicationColor,
                        onChanged: (value) {
                          setModalState(() {
                            remindersEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) return;
                                  final scheduleTime = timeController.text
                                          .trim()
                                          .isEmpty
                                      ? '${selectedIntakeDateTime.hour.toString().padLeft(2, '0')}:${selectedIntakeDateTime.minute.toString().padLeft(2, '0')}'
                                      : timeController.text.trim();

                                  setModalState(() => isSaving = true);
                                  try {
                                    final medication = Medication(
                                      id: existingMedication?.id ?? '',
                                      name: name,
                                      dosage: dosageController.text.trim(),
                                      instructions:
                                          frequencyController.text.trim(),
                                      scheduleTimes: <String>[scheduleTime],
                                      remindersEnabled: remindersEnabled,
                                      intakeDateTime: Timestamp.fromDate(
                                        selectedIntakeDateTime,
                                      ),
                                      startDate:
                                          existingMedication?.startDate ??
                                              Timestamp.fromDate(
                                                selectedIntakeDateTime,
                                              ),
                                      isActive: true,
                                    );
                                    await _medicationRepository
                                        .upsertMedication(uid, medication);
                                  } on ExactAlarmPermissionException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Saved, but reminder was not scheduled. ${e.toString()}',
                                          ),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                    return;
                                  } finally {
                                    if (mounted) {
                                      setModalState(() => isSaving = false);
                                    }
                                  }
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (remindersEnabled &&
                                      !selectedIntakeDateTime
                                          .isAfter(DateTime.now())) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Saved. Reminder time is in the past, so no reminder was scheduled.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  Navigator.of(context).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.medicationColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  existingMedication == null
                                      ? 'Add Medication'
                                      : 'Update Medication',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      String? hint,
      required IconData icon}) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.medicationColor, size: 22),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.medicationColor)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$year-$month-$day $hour:$minute $period';
  }

  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
          body: Center(child: Text(context.strings.text('signIn'))));
    }

    final strings = context.strings;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('myMedications')),
        backgroundColor: AppColors.medicationColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: strings.text('active')),
            Tab(text: strings.text('completed')),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: StreamBuilder<List<TodayIntakeItem>>(
          stream: _medicationRepository.todayIntakesStream(uid, start, end),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading medications.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.medicationColor));
            }

            final all = snapshot.data ?? const [];
            final active = all.where((m) => !m.taken).toList();
            final completed = all.where((m) => m.taken).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(uid, active, false),
                _buildList(uid, completed, true),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'medication_fab',
        onPressed: () => _showAddMedicationDialog(),
        backgroundColor: AppColors.medicationColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(strings.text('addMedication'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildList(
      String uid, List<TodayIntakeItem> items, bool completedList) {
    if (items.isEmpty) {
      return Center(
          child: Text(
              completedList
                  ? context.strings.text('completedDoses')
                  : context.strings.text('activeDoses'),
              style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey('${item.medicationId}_${item.intakeId}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 28),
          ),
          onDismissed: (_) => _deleteMedication(uid, item.medicationId),
          child: MedicationReminderCard(
            key: ValueKey(item.intakeId),
            medicationName: item.medicationName,
            time: _formatTime(item.scheduledAt),
            dosage: item.dosageText,
            instructions: item.instructions,
            isTaken: item.taken,
            isUpdating: _pendingToggles
                .contains('${item.medicationId}:${item.intakeId}'),
            onToggle: () => _toggleIntake(uid, item),
            onTap: item.taken
                ? null
                : () {
                    _medicationRepository
                        .listMedicationsOnce(uid)
                        .then((allMeds) {
                      final med =
                          allMeds.firstWhere((m) => m.id == item.medicationId);
                      if (mounted) {
                        _showAddMedicationDialog(existingMedication: med);
                      }
                    });
                  },
          ),
        );
      },
    );
  }
}

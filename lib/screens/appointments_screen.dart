import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../data/models/appointment.dart';
import '../data/repositories/appointment_repository.dart';
import '../l10n/app_strings.dart';
import '../services/notification/notification_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  Timer? _debounce;

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    await _appointmentRepository.deleteAppointment(uid, appointmentId);
  }

  Future<List<Map<String, dynamic>>> _searchLocation(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final apiKey = AppConfig.googleMapsApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint(AppConfig.missingGoogleMapsApiKeyMessage);
      return [];
    }

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    }
    return [];
  }

  Future<void> _showBookAppointmentDialog(
      {Appointment? existingAppointment}) async {
    final strings = context.strings;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final titleController =
        TextEditingController(text: existingAppointment?.title);
    final doctorController =
        TextEditingController(text: existingAppointment?.doctorName);
    final locationController =
        TextEditingController(text: existingAppointment?.locationText);
    DateTime? selectedDateTime = existingAppointment?.scheduledAt.toDate();
    bool remindersEnabled = existingAppointment?.remindersEnabled ?? true;
    bool isSaving = false;
    List<Map<String, dynamic>> locationSuggestions = [];

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
                      Text(
                          existingAppointment == null
                              ? strings.text('addAppointment')
                              : strings.text('editAppointment'),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildTextField(
                          controller: titleController,
                          label: strings.text('appointmentTitle'),
                          icon: Icons.event_note_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: doctorController,
                          label: strings.text('doctorName'),
                          icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      TextField(
                        controller: locationController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: strings.text('location'),
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: AppColors.appointmentColor, size: 22),
                          suffixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.appointmentColor)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) {
                            _debounce?.cancel();
                          }
                          _debounce = Timer(const Duration(milliseconds: 500),
                              () async {
                            final suggestions = await _searchLocation(value);
                            if (context.mounted) {
                              setModalState(
                                  () => locationSuggestions = suggestions);
                            }
                          });
                        },
                      ),
                      if (locationSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: locationSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = locationSuggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(suggestion['description'],
                                    style: const TextStyle(fontSize: 14)),
                                onTap: () {
                                  setModalState(() {
                                    locationController.text =
                                        suggestion['description'];
                                    locationSuggestions = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)),
                          );
                          if (date == null) {
                            return;
                          }
                          if (!context.mounted) {
                            return;
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                selectedDateTime ?? DateTime.now()),
                          );
                          if (time == null) {
                            return;
                          }
                          setModalState(() => selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute));
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date & Time',
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.appointmentColor,
                                size: 22),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          child: Text(
                            selectedDateTime == null
                                ? 'Select Date & Time'
                                : '${_formatDate(Timestamp.fromDate(selectedDateTime!))} ${_formatTime(Timestamp.fromDate(selectedDateTime!))}',
                            style: TextStyle(
                                color: selectedDateTime == null
                                    ? Colors.grey[600]
                                    : Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminders'),
                        subtitle: const Text('Reminds you 3h, 1h, 30m before'),
                        value: remindersEnabled,
                        activeThumbColor: AppColors.appointmentColor,
                        onChanged: (value) {
                          setModalState(() => remindersEnabled = value);
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
                                  if (titleController.text.isEmpty ||
                                      selectedDateTime == null) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please fill in title and date')),
                                    );
                                    return;
                                  }
                                  setModalState(() => isSaving = true);
                                  try {
                                    await _appointmentRepository
                                        .upsertAppointment(
                                            uid,
                                            Appointment(
                                              id: existingAppointment?.id ?? '',
                                              title:
                                                  titleController.text.trim(),
                                              startAt: Timestamp.fromDate(
                                                  selectedDateTime!),
                                              eventDateTime: Timestamp.fromDate(
                                                  selectedDateTime!),
                                              status:
                                                  existingAppointment?.status ??
                                                      'scheduled',
                                              doctorName:
                                                  doctorController.text.trim(),
                                              locationText: locationController
                                                  .text
                                                  .trim(),
                                              remindersEnabled:
                                                  remindersEnabled,
                                            ));
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
                                      Navigator.pop(context);
                                    }
                                    return;
                                  } finally {
                                    if (context.mounted) {
                                      setModalState(() => isSaving = false);
                                    }
                                  }
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (remindersEnabled &&
                                      !selectedDateTime!
                                          .isAfter(DateTime.now())) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          strings.text(
                                            'savedPastAppointmentReminder',
                                          ),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  Navigator.pop(context); // CLOSES DIALOG
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appointmentColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  existingAppointment == null
                                      ? strings.text('addAppointment')
                                      : strings.text('editAppointment'),
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
      required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.appointmentColor, size: 22),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.appointmentColor)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isPast = appointment.scheduledAt.toDate().isBefore(DateTime.now());
    return Dismissible(
      key: ValueKey(appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        _deleteAppointment(appointment.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[100]!)),
        child: ListTile(
          onTap: () =>
              _showBookAppointmentDialog(existingAppointment: appointment),
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.appointmentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(isPast ? Icons.event_available : Icons.event,
                color: AppColors.appointmentColor),
          ),
          title: Text(appointment.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${_formatDate(appointment.scheduledAt)} at ${_formatTime(appointment.scheduledAt)}\n${appointment.locationText ?? 'No location'}'),
          isThreeLine: true,
          trailing: const Icon(Icons.edit_outlined,
              size: 20, color: AppColors.appointmentColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
          body: Center(child: Text(context.strings.text('signIn'))));
    }

    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('mySchedule')),
        backgroundColor: AppColors.appointmentColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: strings.text('upcoming')),
            Tab(text: strings.text('past')),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: StreamBuilder<List<Appointment>>(
          stream: _appointmentRepository.listAppointmentsStream(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final now = DateTime.now();
            final upcoming = snapshot.data!
                .where((a) => a.scheduledAt.toDate().isAfter(now))
                .toList();
            final past = snapshot.data!
                .where((a) => !a.scheduledAt.toDate().isAfter(now))
                .toList();
            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(upcoming, strings.text('noUpcomingAppointments')),
                _buildList(past, strings.text('noPastAppointments')),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'appointments_fab',
        onPressed: _showBookAppointmentDialog,
        backgroundColor: AppColors.appointmentColor,
        label: Text(strings.text('addAppointment'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildList(List<Appointment> items, String emptyText) {
    if (items.isEmpty) {
      return Center(
          child: Text(emptyText, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildAppointmentCard(items[index]),
    );
  }
}

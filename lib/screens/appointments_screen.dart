import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/appointment.dart';
import '../data/repositories/appointment_repository.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final AppointmentRepository _appointmentRepository = AppointmentRepository();

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    await _appointmentRepository.deleteAppointment(uid, appointmentId);
  }

  Future<void> _showBookAppointmentDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? selectedDateTime;
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
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now.subtract(const Duration(days: 1)),
                lastDate: DateTime(now.year + 5),
              );
              if (pickedDate == null) {
                return;
              }
              if (!context.mounted) {
                return;
              }

              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(now),
              );
              if (pickedTime == null) {
                return;
              }
              if (!context.mounted) {
                return;
              }

              setModalState(() {
                selectedDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            Future<void> save() async {
              final title = titleController.text.trim();
              if (title.isEmpty || selectedDateTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter title and date/time.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              try {
                final appointment = Appointment(
                  title: title,
                  startAt: Timestamp.fromDate(selectedDateTime!),
                  status: 'scheduled',
                  doctorName: doctorController.text.trim().isEmpty
                      ? null
                      : doctorController.text.trim(),
                  locationText: locationController.text.trim().isEmpty
                      ? null
                      : locationController.text.trim(),
                );
                await _appointmentRepository.upsertAppointment(
                    uid, appointment);
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
                    'Book New Appointment',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.event_note_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: doctorController,
                    decoration: InputDecoration(
                      labelText: 'Doctor Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickDateTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date & Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        selectedDateTime == null
                            ? 'Select date and time'
                            : '${selectedDateTime!.year.toString().padLeft(4, '0')}-${selectedDateTime!.month.toString().padLeft(2, '0')}-${selectedDateTime!.day.toString().padLeft(2, '0')} ${TimeOfDay.fromDateTime(selectedDateTime!).format(context)}',
                        style: TextStyle(
                          color: selectedDateTime == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appointmentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Book Appointment'),
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

  Widget _buildAppointmentCard(Appointment appointment) {
    final status = appointment.status.toLowerCase();
    final isCompleted = status == 'completed' || status == 'cancelled';

    return Dismissible(
      key: ValueKey(appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteAppointment(appointment.id);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.appointmentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCompleted ? Icons.event_available : Icons.event,
              color: AppColors.appointmentColor,
            ),
          ),
          title: Text(
            appointment.title.isEmpty
                ? 'Untitled Appointment'
                : appointment.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((appointment.doctorName ?? '').isNotEmpty)
                  Text('Doctor: ${appointment.doctorName}'),
                if ((appointment.locationText ?? '').isNotEmpty)
                  Text('Location: ${appointment.locationText}'),
                Text(
                  '${_formatDate(appointment.startAt)} • ${_formatTime(appointment.startAt)}',
                ),
                Text('Status: ${appointment.status}'),
              ],
            ),
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
        body: Center(child: Text('Please sign in to view appointments.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.appointmentColor,
      ),
      body: DefaultTabController(
        length: 2,
        child: StreamBuilder<List<Appointment>>(
          stream: _appointmentRepository.listAppointmentsStream(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Unable to load appointments.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.data ?? const <Appointment>[];
            final now = DateTime.now();
            final upcoming = all
                .where((a) =>
                    a.startAt.toDate().isAfter(now) && a.status != 'completed')
                .toList(growable: false);
            final past = all
                .where((a) =>
                    !a.startAt.toDate().isAfter(now) || a.status == 'completed')
                .toList(growable: false);

            Widget buildList(List<Appointment> items, String emptyText) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    emptyText,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildAppointmentCard(items[index]),
              );
            }

            return Column(
              children: [
                const TabBar(
                  labelColor: AppColors.appointmentColor,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.appointmentColor,
                  tabs: [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildList(upcoming, 'No upcoming appointments'),
                      buildList(past, 'No past appointments'),
                    ],
                  ),
                ),
              ],
            );
          },
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
}

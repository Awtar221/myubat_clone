import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MedicationReminderCard extends StatelessWidget {
  final String medicationName;
  final String time;
  final String dosage;
  final bool isTaken;
  final bool isUpdating;
  final VoidCallback? onToggle;

  const MedicationReminderCard({
    super.key,
    required this.medicationName,
    required this.time,
    required this.dosage,
    required this.isTaken,
    this.isUpdating = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isTaken ? Icons.check_circle : Icons.schedule,
                color: isTaken ? AppColors.success : AppColors.warning,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicationName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Icon(
                        Icons.medical_services,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dosage,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isTaken ? Icons.undo : Icons.check_circle_outline,
                    ),
              color: isTaken ? AppColors.textSecondary : AppColors.primaryColor,
              onPressed: isUpdating ? null : onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

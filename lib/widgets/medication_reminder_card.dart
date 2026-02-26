import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MedicationReminderCard extends StatelessWidget {
  final String medicationName;
  final String time;
  final String dosage;
  final String? instructions;
  final bool isTaken;
  final bool isUpdating;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const MedicationReminderCard({
    super.key,
    required this.medicationName,
    required this.time,
    required this.dosage,
    this.instructions,
    required this.isTaken,
    this.isUpdating = false,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Visual Status Indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isTaken ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    color: isTaken ? AppColors.success : AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicationName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildChip(Icons.access_time_rounded, time, AppColors.medicationColor),
                          const SizedBox(width: 8),
                          _buildChip(Icons.science_rounded, dosage, Colors.grey[600]!),
                        ],
                      ),
                      if (instructions != null && instructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          instructions!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action Button
                IconButton(
                  onPressed: isUpdating ? null : onToggle,
                  icon: isUpdating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Icon(
                          isTaken ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
                          color: isTaken ? Colors.grey[400] : AppColors.primaryColor,
                          size: 26,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

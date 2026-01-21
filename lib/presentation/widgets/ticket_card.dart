import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

class TicketCard extends StatelessWidget {
  final String customerName;
  final String mobile;
  final String vehicleNumber;
  final String deviceType;
  final String issue;
  final String status;

  const TicketCard({
    super.key,
    required this.customerName,
    required this.mobile,
    required this.vehicleNumber,
    required this.deviceType,
    required this.issue,
    required this.status,
  });

  Color _getStatusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'open':
        return theme.colorScheme.error; // Red for open
      case 'in progress':
      case 'working':
        return Colors.orange; // Orange for in progress
      case 'resolved':
      case 'completed':
        return theme.colorScheme.secondary; // Green for resolved
      case 'closed':
        return Colors.grey; // Grey for closed
      default:
        return theme.colorScheme.primary; // Primary color for others
    }
  }

  Color _getStatusTextColor(String status, BuildContext context) {
    final bgColor = _getStatusColor(status, context);

    // Calculate brightness for contrast
    final brightness = ThemeData.estimateBrightnessForColor(bgColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      color: cs.surface, // Theme-aware card color
      margin: const EdgeInsets.symmetric(vertical: AppPadding.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: cs.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$customerName ($mobile)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppPadding.xs),
            Text(
              "Vehicle: $vehicleNumber",
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            Text(
              "Device: $deviceType",
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppPadding.xs),
            Text(
              "Issue: $issue",
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppPadding.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppPadding.xs,
                  horizontal: AppPadding.sm,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status, context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusTextColor(status, context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
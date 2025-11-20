import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.lightCard,
      margin: const EdgeInsets.symmetric(vertical: AppPadding.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$customerName ($mobile)",
              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.xs),
            Text("Vehicle: $vehicleNumber", style: AppTextStyles.bodyText1),
            Text("Device: $deviceType", style: AppTextStyles.bodyText1),
            const SizedBox(height: AppPadding.xs),
            Text("Issue: $issue", style: AppTextStyles.bodyText2),
            const SizedBox(height: AppPadding.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppPadding.xs,
                  horizontal: AppPadding.sm,
                ),
                decoration: BoxDecoration(
                  color: status == "Open" ? Colors.red.shade300 : Colors.green.shade300,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.bodyText2.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

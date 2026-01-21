import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Devices",
          style: AppTextStyles.titleLarge(context),
        ),
        centerTitle: true,
        backgroundColor: cs.primary,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(isDarkMode ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.devices_other,
                  size: 60,
                  color: cs.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Main message
              Text(
                "Device Management",
                style: AppTextStyles.headline1(context).copyWith(
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.primary,
                    width: 1,
                  ),
                ),
                child: Text(
                  "COMING SOON",
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Brief description
              Text(
                "We're working on a feature to help you add and manage tracking devices.",
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Simple contact option
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to ticket form for device requests
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => TicketFormScreen(preSelectedSubject: "New Device Request")
                  // ));
                },
                icon: Icon(
                  Icons.support_agent,
                  color: cs.primary,
                ),
                label: Text(
                  "Request Device Now",
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  side: BorderSide(color: cs.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
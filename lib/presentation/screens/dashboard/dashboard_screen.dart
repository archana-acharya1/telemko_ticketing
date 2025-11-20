import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/dashboard/payment_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/quick_link_card.dart';
import '../tickets/ticket_form_screen.dart';
import '../tickets/gps_ticket_screen.dart';
import '../tickets/fuel_ticket_screen.dart';
import '../tickets/dashcam_ticket_screen.dart';
import '../auth/logout_screen.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import 'customer_support_screen.dart';
import 'devices_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        title: Text(
          "Telemko Support",
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogoutScreen()),
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // LARGE CREATE SUPPORT TICKET CARD
            QuickLinkCard(
              title: "Create Support Ticket",
              icon: Icons.support_agent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicketFormScreen()),
                );
              },
              variant: QuickLinkCardVariant.large,
            ),

            const SizedBox(height: AppPadding.lg),

            // QUICK LINKS TITLE
            Text(
              "Quick Links",
              style: AppTextStyles.headline2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.md),

            // QUICK LINKS GRID (all pink)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppPadding.sm,
              mainAxisSpacing: AppPadding.sm,
              childAspectRatio: 0.9,
              children: [
                QuickLinkCard(
                  title: "GPS",
                  icon: Icons.gps_fixed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GPSTicketScreen()),
                    );
                  },
                ),
                QuickLinkCard(
                  title: "Fuel\nSensor",
                  icon: Icons.local_gas_station,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FuelTicketScreen()),
                    );
                  },
                ),
                QuickLinkCard(
                  title: "Dashcam\nLive",
                  icon: Icons.video_camera_back,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashcamTicketScreen()),
                    );
                  },
                ),
                QuickLinkCard(
                  title: "Customer\nSupport",
                  icon: Icons.call,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  CustomerSupportScreen()),
                    );
                  },
                ),
                QuickLinkCard(
                  title: "Make\nPayment",
                  icon: Icons.payment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentScreen()),
                    );
                  },
                ),
                QuickLinkCard(
                  title: "New\nDevices",
                  icon: Icons.devices,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DevicesScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

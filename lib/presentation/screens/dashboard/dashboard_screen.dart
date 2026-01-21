import 'package:flutter/material.dart';
import '../../widgets/quick_link_card.dart';
import '../tickets/ticket_form_screen.dart';
import '../auth/logout_screen.dart';
import '../../../core/theme/app_constants.dart';
import '../tickets/ticket_history_screen.dart';
import 'customer_support_screen.dart';
import 'devices_screen.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import '../dashboard/payment_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    print("[Dashboard] Dashboard screen loaded");

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(
          "Telemko Support",
          style: TextStyle( // Fixed: Use TextStyle instead of AppTextStyles
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              print("[Dashboard] Logout button tapped");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogoutScreen()),
              );
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
              Color(0xFF0A1A2F), // Dark blue top
              Color(0xFF121212), // Dark background
            ]
                : [
              Color(0xFFF5FAFF), // light gradient top
              Color(0xFFEAF3FD), // light gradient bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CREATE SUPPORT TICKET
                GestureDetector(
                  onTap: () {
                    print("[Dashboard] Create Support Ticket tapped");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TicketFormScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.4)
                              : Colors.black26,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.support_agent,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Create Support Ticket",
                                style: TextStyle( // Fixed: Use TextStyle instead of AppTextStyles
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Report issues and get help instantly",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // TICKETS & SUPPORT title
                Text(
                  "Tickets & Support",
                  style: TextStyle( // Fixed: Use TextStyle instead of AppTextStyles
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppPadding.md),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppPadding.sm,
                  mainAxisSpacing: AppPadding.sm,
                  childAspectRatio: 0.85,
                  children: [
                    _buildQuickLink(context, title: "GPS", icon: Icons.gps_fixed),
                    _buildQuickLink(context, title: "Fuel Sensor", icon: Icons.local_gas_station),
                    _buildQuickLink(context, title: "Dashcam Live", icon: Icons.video_camera_back),
                    _buildQuickLink(context, title: "Customer Support", icon: Icons.call),
                    _buildQuickLink(context, title: "Make Payment", icon: Icons.payment),
                    _buildQuickLink(context, title: "New Devices", icon: Icons.devices),
                    _buildQuickLink(
                      context,
                      title: "My Tickets",
                      icon: Icons.receipt_long,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink(BuildContext context, {required String title, required IconData icon}) {
    // Determine which screen to show based on title
    Widget targetScreen;

    switch (title) {
      case "GPS":
        targetScreen = TicketFormScreen(preSelectedSubject: "GPS Not Working");
        break;
      case "Fuel Sensor":
        targetScreen = TicketFormScreen(preSelectedSubject: "Fuel Data Not Showing");
        break;
      case "Dashcam Live":
        targetScreen = TicketFormScreen(preSelectedSubject: "Video Not Showing");
        break;
      case "Customer Support":
        targetScreen = CustomerSupportScreen();
        break;
      case "Make Payment":
        targetScreen = const PaymentScreen();
        break;
      case "New Devices":
        targetScreen = const DevicesScreen();
        break;
      case "My Tickets":
        targetScreen = const TicketHistoryScreen();
        break;
      default:
        targetScreen = const TicketFormScreen(); // Default general form
    }

    return QuickLinkCard(
      title: title,
      icon: icon,
      textColor: Theme.of(context).colorScheme.onSurface,
      onTap: () {
        print("[Dashboard] Quick link tapped: $title");
        Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
      },
    );
  }
}
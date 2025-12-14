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
import '../tickets/ticket_history_screen.dart';
import 'customer_support_screen.dart';
import 'devices_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          "Telemko Support",
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogoutScreen()),
              );
            },
          )
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gradientTop,
              AppColors.gradientBottom,
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

                /// CREATE SUPPORT TICKET (RESPONSIVE)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TicketFormScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Colors.white,
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
                                style: AppTextStyles.headline2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Report issues and get help instantly",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                /// QUICK LINKS TITLE
                Text(
                  "Quick Links",
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppPadding.md),

                /// QUICK LINKS GRID
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppPadding.sm,
                  mainAxisSpacing: AppPadding.sm,
                  childAspectRatio: 0.85,
                  children: [
                    _buildQuickLink(
                      context,
                      title: "GPS",
                      icon: Icons.gps_fixed,
                      screen: const GPSTicketScreen(),
                    ),
                    _buildQuickLink(
                      context,
                      title: "Fuel Sensor",
                      icon: Icons.local_gas_station,
                      screen: const FuelTicketScreen(),
                    ),
                    _buildQuickLink(
                      context,
                      title: "Dashcam Live",
                      icon: Icons.video_camera_back,
                      screen: const DashcamTicketScreen(),
                    ),
                    _buildQuickLink(
                      context,
                      title: "Customer Support",
                      icon: Icons.call,
                      screen: CustomerSupportScreen(),
                    ),
                    _buildQuickLink(
                      context,
                      title: "Make Payment",
                      icon: Icons.payment,
                      screen: const PaymentScreen(),
                    ),
                    _buildQuickLink(
                      context,
                      title: "New Devices",
                      icon: Icons.devices,
                      screen: const DevicesScreen(),
                    ),
                    _buildQuickLink(
                      context,
                      title: "My Tickets",
                      icon: Icons.receipt_long,
                      screen: const TicketHistoryScreen(mobile: ""),
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

  Widget _buildQuickLink(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Widget screen,
      }) {
    return QuickLinkCard(
      title: title,
      icon: icon,
      textColor: Colors.black87,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }
}

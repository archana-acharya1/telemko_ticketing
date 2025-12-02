import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/profile/profile_screen.dart';
import 'package:telemko_support/presentation/screens/tickets/ticket_selection_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/payment_screen.dart';
import '../dashboard/devices_screen.dart';
import '../dashboard/customer_support_screen.dart';
import '../tickets/ticket_form_screen.dart';
import '../../../core/theme/app_colors.dart';

class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    PaymentScreen(),
    TicketSelectionScreen(),
    DevicesScreen(),
    CustomerSupportScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        elevation: 8,

        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey.shade600,

        selectedIconTheme: const IconThemeData(
          color: AppColors.primaryBlue,
          size: 28,
        ),

        unselectedIconTheme: IconThemeData(
          color: Colors.grey.shade600,
        ),

        enableFeedback: false,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: "Payment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Ticket",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: "Devices",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: "Support",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

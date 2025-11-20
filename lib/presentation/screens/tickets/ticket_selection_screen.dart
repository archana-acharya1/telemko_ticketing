import 'package:flutter/material.dart';
import '../../widgets/quick_link_card.dart';
import 'ticket_form_screen.dart';
import 'gps_ticket_screen.dart';
import 'fuel_ticket_screen.dart';
import 'dashcam_ticket_screen.dart';

class TicketSelectionScreen extends StatelessWidget {
  const TicketSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Ticket Type"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            QuickLinkCard(
              title: "Generic Ticket",
              icon: Icons.add_circle_outline,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TicketFormScreen())),
            ),
            QuickLinkCard(
              title: "GPS Ticket",
              icon: Icons.gps_fixed,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GPSTicketScreen())),
            ),
            QuickLinkCard(
              title: "Fuel Sensor Ticket",
              icon: Icons.local_gas_station,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FuelTicketScreen())),
            ),
            QuickLinkCard(
              title: "Dashcam Ticket",
              icon: Icons.videocam,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DashcamTicketScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

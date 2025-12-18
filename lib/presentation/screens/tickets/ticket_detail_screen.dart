import 'package:flutter/material.dart';

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ticket ${ticket["name"] ?? ticket["id"] ?? ""}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ticket Details",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                detailItem("Ticket ID", ticket["name"] ?? ticket["id"] ?? ""),
                detailItem("Customer Name", ticket["customer"] ?? ""),
                detailItem("Vehicle Number", ticket["custom_vehical_number"] ?? ""),
                detailItem("Status", ticket["status"] ?? ""),
                detailItem("Subject", ticket["subject"] ?? ""),
                detailItem("Description", ticket["description"] ?? ""),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Actions coming soon..."),
                      ),
                    );
                  },
                  child: const Text("Take Action (Upcoming)"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget detailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              )),
          const SizedBox(height: 4),
          Text(value.isNotEmpty ? value : "-", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

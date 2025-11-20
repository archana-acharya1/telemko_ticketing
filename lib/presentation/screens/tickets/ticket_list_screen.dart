import 'package:flutter/material.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatelessWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock ticket list (later will come from repository/API)
    final mockTickets = [
      {
        "id": "TCK-001",
        "name": "John Doe",
        "vehicle": "Ba 2 Pa 1234",
        "status": "Pending",
      },
      {
        "id": "TCK-002",
        "name": "Ram Shrestha",
        "vehicle": "Ba 5 Cha 9876",
        "status": "Resolved",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
      ),

      body: ListView.separated(
        itemCount: mockTickets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),

        itemBuilder: (context, index) {
          final t = mockTickets[index];

          return ListTile(
            leading: CircleAvatar(
              child: Text("${index + 1}"),
            ),

            title: Text(t["id"]!),
            subtitle: Text("${t["name"]} • ${t["vehicle"]}"),

            trailing: Text(
              t["status"]!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: t["status"] == "Resolved" ? Colors.green : Colors.orange,
              ),
            ),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(ticket: t),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/issue_service.dart';
import '../dashboard/lib/data/local/session_manager.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  List<dynamic> tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _loading = true);
    try {
      final email = await SessionManager.getEmail();
      if (email != null) {
        tickets = await IssueService.fetchIssuesByEmail(email);

        tickets.sort((a, b) {
          final dateA = DateTime.tryParse(a["opening_date"] ?? "") ?? DateTime(2000);
          final dateB = DateTime.tryParse(b["opening_date"] ?? "") ?? DateTime(2000);
          return dateB.compareTo(dateA); // Newest first
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching tickets: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("My Tickets")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
          ? const Center(child: Text("No tickets found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final t = tickets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(t["subject"] ?? ""),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer: ${t["customer"] ?? ""}"),
                  Text("Mobile: ${t["custom_mobile_number"] ?? ""}"),
                  Text("Vehicle: ${t["custom_vehical_number"] ?? ""}"),
                  Text("Status: ${t["status"] ?? ""}"),
                ],
              ),
              trailing: Text(t["opening_date"]?.toString().split(" ")[0] ?? ""),
            ),
          );
        },
      ),
    );
  }
}

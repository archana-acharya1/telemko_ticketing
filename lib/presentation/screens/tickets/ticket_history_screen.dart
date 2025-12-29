import 'package:flutter/material.dart';

import '../../../data/api/api_client.dart';
import '../dashboard/lib/data/local/session_manager.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    setState(() => isLoading = true);
    try {
      // Make sure session is loaded
      final sid = await SessionManager.getSid();
      print("[TicketHistoryScreen] Fetching tickets with SID: $sid");
      
      if (sid == null || sid.isEmpty) {
        print("[TicketHistoryScreen] ERROR: No SID found. User not logged in.");
        setState(() {
          tickets = [];
        });
        return;
      }

      // Fetch tickets using ApiClient
      print("[TicketHistoryScreen] Calling get_tickets API...");
      final res = await ApiClient.get("/api/method/telemko_support.api.get_tickets");
      print("[TicketHistoryScreen] get_tickets response: $res");
      
      setState(() {
        tickets = res["message"] ?? [];
      });
      print("[TicketHistoryScreen] Loaded ${tickets.length} tickets");
    } catch (e) {
      print("[TicketHistoryScreen] ERROR fetching tickets: $e");
      print("[TicketHistoryScreen] Error type: ${e.runtimeType}");
      setState(() {
        tickets = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tickets")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return ListTile(
            title: Text(ticket["title"] ?? "No title"),
            subtitle: Text(ticket["description"] ?? "No description"),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../services/issue_service.dart';

class TicketHistoryScreen extends StatefulWidget {
  final String mobile;

  const TicketHistoryScreen({super.key, required this.mobile});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> issues = [];

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await IssueService.fetchIssues(
        mobile: widget.mobile,
      );

      setState(() {
        issues = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Widget _buildListTile(Map<String, dynamic> issue) {
    final name = issue['name'] ?? "";
    final subject = issue['subject'] ?? "(no subject)";
    final status = issue['status'] ?? "";
    final customer = issue['customer'] ?? "";
    final mobile = issue['custom_mobile_number'] ?? "";
    final vehicle = issue['custom_vehical_number'] ?? "";
    final openingDate = issue['opening_date'] ?? "";

    Color statusColor;
    if (status.toLowerCase().contains('closed')) {
      statusColor = Colors.green;
    } else if (status.toLowerCase().contains('open')) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.isNotEmpty) Text(customer),
            Row(
              children: [
                if (mobile.isNotEmpty) Text(mobile, style: const TextStyle(fontSize: 12)),
                if (mobile.isNotEmpty && vehicle.isNotEmpty) const SizedBox(width: 8),
                if (vehicle.isNotEmpty) Text(vehicle, style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (openingDate.isNotEmpty) Text("Opened: $openingDate", style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right)
          ],
        ),
        onTap: () {
          // TODO: navigate to details screen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: RefreshIndicator(
        onRefresh: _loadIssues,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(child: Text('Error: $errorMessage')),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _loadIssues,
                child: const Text('Retry'),
              ),
            ),
          ],
        )
            : issues.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No tickets found')),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final item = issues[index];
            final issueMap = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
            return _buildListTile(issueMap);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to create ticket screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

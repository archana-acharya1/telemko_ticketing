import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/tickets/ticket_form_screen.dart';
import '../../../services/issue_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../dashboard/lib/data/local/session_manager.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (!isRefreshing) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      // Fetch tickets with customer details
      final fetchedTickets = await IssueService.fetchMyIssues();

      // DEBUG: Print what fields are available
      if (fetchedTickets.isNotEmpty) {
        print("[TicketHistoryScreen] First ticket has these fields:");
        fetchedTickets[0].forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            print("  $key: $value");
          }
        });
      }

      // Ensure sorting by creation date (newest first)
      fetchedTickets.sort((a, b) {
        final dateA = a["creation"] ?? "";
        final dateB = b["creation"] ?? "";
        return dateB.compareTo(dateA); // Newest first
      });

      setState(() {
        tickets = fetchedTickets;
        isLoading = false;
        isRefreshing = false;
      });

      print("[TicketHistoryScreen] Successfully loaded ${tickets.length} tickets");
    } catch (e) {
      print("[TicketHistoryScreen] ERROR loading tickets: $e");
      setState(() {
        errorMessage = e.toString();
        tickets = [];
        isLoading = false;
        isRefreshing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load tickets: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _refreshTickets() async {
    setState(() => isRefreshing = true);
    await _loadTickets();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Refreshed ${tickets.length} tickets"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Format date nicely
  String _formatDate(dynamic date) {
    if (date == null) return "Unknown date";
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        return date.toString();
      }
    }
    return "Invalid date";
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in progress':
      case 'working':
        return Colors.orange;
      case 'resolved':
      case 'completed':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primaryBlue;
    }
  }

  // Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Build the ticket card with all customer details
  Widget _buildTicketCard(Map<String, dynamic> ticket, int index) {
    // DEBUG: Print all available fields
    print("[TicketHistoryScreen] Ticket ${ticket["name"]} fields:");
    ticket.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        print("  $key: $value");
      }
    });

    final status = ticket["status"]?.toString() ?? "Open";
    final priority = ticket["priority"]?.toString() ?? "Medium";
    final subject = ticket["subject"] ?? "No Subject";
    final description = ticket["description"] ?? "No description";
    final creationDate = _formatDate(ticket["creation"]);
    final ticketId = ticket["name"] ?? "N/A";

    // FIXED: Extract customer details with multiple field name attempts
    // Try different possible field names for customer
    final customerName = ticket["customer"]?.toString() ??
        ticket["customer_name"]?.toString() ??
        ticket["raised_by"]?.toString() ??
        ticket["opened_by"]?.toString() ??
        "Not specified";

    // Try different possible field names for mobile
    final customerMobile = ticket["contact_mobile"]?.toString() ??
        ticket["mobile_no"]?.toString() ??
        ticket["mobile"]?.toString() ??
        ticket["phone"]?.toString() ??
        "Not specified";

    // Try different possible field names for vehicle
    final vehicleNumber = ticket["vehicle_number"]?.toString() ??
        ticket["vehicle"]?.toString() ??
        ticket["vehicle_no"]?.toString() ??
        "Not specified";

    final issueType = ticket["issue_type"]?.toString() ??
        ticket["type"]?.toString() ??
        "General";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ticket ID and Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ticket #$ticketId",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creationDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Status and Priority badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Priority badge
                      if (priority.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Priority: $priority",
                            style: TextStyle(
                              color: _getPriorityColor(priority),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Subject/Title
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Customer Details Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Customer Name
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: "Customer",
                      value: customerName,
                    ),

                    const SizedBox(height: 6),

                    // Mobile Number
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: "Mobile",
                      value: customerMobile,
                    ),

                    const SizedBox(height: 6),

                    // Vehicle Number
                    _buildDetailRow(
                      icon: Icons.directions_car,
                      label: "Vehicle",
                      value: vehicleNumber,
                    ),

                    const SizedBox(height: 6),

                    // Issue Type
                    _buildDetailRow(
                      icon: Icons.category,
                      label: "Issue Type",
                      value: issueType,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Description Preview
              if (description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description.length > 100
                          ? "${description.substring(0, 100)}..."
                          : description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // View Details Button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View Details",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show detailed ticket view
  void _showTicketDetails(Map<String, dynamic> ticket) {
    // Extract fields for details view
    final customerName = ticket["customer"]?.toString() ??
        ticket["customer_name"]?.toString() ??
        ticket["raised_by"]?.toString() ??
        "Not specified";

    final customerMobile = ticket["contact_mobile"]?.toString() ??
        ticket["mobile_no"]?.toString() ??
        "Not specified";

    final vehicleNumber = ticket["vehicle_number"]?.toString() ??
        "Not specified";

    final customerEmail = ticket["contact_email"]?.toString() ??
        ticket["raised_by"]?.toString() ??
        "Not specified";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTicketDetailsSheet(ticket, customerName, customerMobile, vehicleNumber, customerEmail),
    );
  }

  Widget _buildTicketDetailsSheet(Map<String, dynamic> ticket, String customerName, String customerMobile, String vehicleNumber, String customerEmail) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Ticket header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ticket #${ticket["name"] ?? "N/A"}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket["status"] ?? "Open").withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(ticket["status"] ?? "Open"),
                      ),
                    ),
                    child: Text(
                      (ticket["status"] ?? "Open").toString().toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(ticket["status"] ?? "Open"),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "Created: ${_formatDate(ticket["creation"])}",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Information Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Customer Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailCardRow("Name", customerName),
                              _buildDetailCardRow("Mobile", customerMobile),
                              _buildDetailCardRow("Email", customerEmail),
                              _buildDetailCardRow("Vehicle", vehicleNumber),
                              if (ticket["vehicle_model"] != null)
                                _buildDetailCardRow("Vehicle Model", ticket["vehicle_model"]),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Issue Details Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Issue Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailCardRow("Subject", ticket["subject"] ?? "No subject"),
                              _buildDetailCardRow("Type", ticket["issue_type"] ?? "General"),
                              _buildDetailCardRow("Priority", ticket["priority"] ?? "Medium"),
                              _buildDetailCardRow("Status", ticket["status"] ?? "Open"),
                              if (ticket["assigned_to"] != null)
                                _buildDetailCardRow("Assigned To", ticket["assigned_to"]),
                              if (ticket["branch"] != null)
                                _buildDetailCardRow("Branch", ticket["branch"]),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                ticket["description"] ?? "No description provided",
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (ticket["resolution_details"] != null)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Resolution",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      ticket["resolution_details"],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No tickets found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create your first support ticket to get started",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: "Create Ticket",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketFormScreen()));
            },
            color: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Failed to load tickets",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  text: "Retry",
                  onPressed: _loadTickets,
                  color: AppColors.primaryBlue,
                  expanded: false,
                  width: 120,
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: "Login Again",
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  },
                  color: Colors.grey,
                  expanded: false,
                  width: 120,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Support Tickets"),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: Icon(isRefreshing ? Icons.refresh : Icons.refresh_outlined),
            onPressed: isRefreshing ? null : _refreshTickets,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? _buildErrorState()
          : tickets.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadTickets,
        child: ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            return _buildTicketCard(tickets[index], index);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketFormScreen()));
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
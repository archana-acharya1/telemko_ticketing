import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/tickets/ticket_form_screen.dart';
import '../../../services/issue_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../auth/login_screen.dart';
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
    print("🎫 Loading tickets - Checking session...");
    await SessionManager.printSessionDebugInfo();

    final session = await SessionManager.getCustomerSession();
    if (session == null || session["sid"] == null) {
      print("❌ No valid session found. Redirecting to login...");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Session expired. Please login again.",
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
      return;
    }
    if (!isRefreshing) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final session = await SessionManager.getCustomerSession();
      print("[TicketHistoryScreen] Current session: ${session?.toString()}");
      print("[TicketHistoryScreen] SID from SessionManager: ${await SessionManager.getSid()}");

      final fetchedTickets = await IssueService.fetchMyIssues();

      if (fetchedTickets.isNotEmpty) {
        print("[TicketHistoryScreen] === DEBUG ALL TICKET FIELDS ===");
        for (int i = 0; i < fetchedTickets.length && i < 5; i++) {
          final ticket = fetchedTickets[i] as Map<String, dynamic>;
          print("\n[TicketHistoryScreen] Ticket #${i + 1} - ID: ${ticket["name"]}");

          final customFields = [
            "custom_mobile_no",
            "custom_vehical_number",
            "mobile_no",
            "contact_mobile",
            "vehicle_number",
            "raised_by",
            "customer",
            "customer_name"
          ];

          for (final field in customFields) {
            if (ticket.containsKey(field)) {
              final value = ticket[field];
              print("  $field: ${value ?? "NULL"} (Type: ${value?.runtimeType})");
            } else {
              print("  $field: NOT IN TICKET");
            }
          }

          print("  Test Mobile: ${_extractMobileNumber(ticket)}");
          print("  Test Vehicle: ${_extractVehicleNumber(ticket)}");
        }
        print("[TicketHistoryScreen] ===============================");
      }

      fetchedTickets.sort((a, b) {
        final dateA = a["creation"] ?? "";
        final dateB = b["creation"] ?? "";
        return dateB.compareTo(dateA);
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
            content: Text(
              "Failed to load tickets: ${e.toString()}",
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
          content: Text(
            "Refreshed ${tickets.length} tickets",
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  String _extractMobileNumber(Map<String, dynamic> ticket) {
    if (ticket.containsKey("custom_mobile_no") &&
        ticket["custom_mobile_no"] != null &&
        ticket["custom_mobile_no"].toString().trim().isNotEmpty) {
      return ticket["custom_mobile_no"].toString().trim();
    }

    if (ticket.containsKey("mobile_no") &&
        ticket["mobile_no"] != null &&
        ticket["mobile_no"].toString().trim().isNotEmpty) {
      return ticket["mobile_no"].toString().trim();
    }

    if (ticket.containsKey("contact_mobile") &&
        ticket["contact_mobile"] != null &&
        ticket["contact_mobile"].toString().trim().isNotEmpty) {
      return ticket["contact_mobile"].toString().trim();
    }

    if (ticket.containsKey("raised_by") &&
        ticket["raised_by"] != null) {
      final value = ticket["raised_by"].toString().trim();
      if (_isPhoneNumber(value)) {
        return value;
      }
    }

    final phoneKeywords = ['phone', 'mobile', 'contact'];
    for (final key in ticket.keys) {
      if (phoneKeywords.any((keyword) => key.toLowerCase().contains(keyword))) {
        if (ticket[key] != null && ticket[key].toString().trim().isNotEmpty) {
          return ticket[key].toString().trim();
        }
      }
    }

    return "Not specified";
  }

  String _extractVehicleNumber(Map<String, dynamic> ticket) {
    if (ticket.containsKey("custom_vehical_number") &&
        ticket["custom_vehical_number"] != null &&
        ticket["custom_vehical_number"].toString().trim().isNotEmpty) {
      return ticket["custom_vehical_number"].toString().trim();
    }

    if (ticket.containsKey("custom_vehicle_number") &&
        ticket["custom_vehicle_number"] != null &&
        ticket["custom_vehicle_number"].toString().trim().isNotEmpty) {
      return ticket["custom_vehicle_number"].toString().trim();
    }

    if (ticket.containsKey("vehicle_number") &&
        ticket["vehicle_number"] != null &&
        ticket["vehicle_number"].toString().trim().isNotEmpty) {
      return ticket["vehicle_number"].toString().trim();
    }

    if (ticket.containsKey("vehical_number") &&
        ticket["vehical_number"] != null &&
        ticket["vehical_number"].toString().trim().isNotEmpty) {
      return ticket["vehical_number"].toString().trim();
    }

    final vehicleKeywords = ['vehicle', 'vehical', 'registration', 'plate', 'reg'];
    for (final key in ticket.keys) {
      if (vehicleKeywords.any((keyword) => key.toLowerCase().contains(keyword))) {
        if (ticket[key] != null && ticket[key].toString().trim().isNotEmpty) {
          return ticket[key].toString().trim();
        }
      }
    }

    if (ticket.containsKey("description") && ticket["description"] != null) {
      final description = ticket["description"].toString();
      final vehiclePattern = RegExp(r'[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,2}\s?\d{4}');
      final match = vehiclePattern.firstMatch(description);
      if (match != null) {
        return match.group(0)!;
      }
    }

    return "Not specified";
  }

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

  Color _getStatusColor(String status, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (status.toLowerCase()) {
      case 'open':
        return isDarkMode ? Colors.lightBlue : Colors.blue;
      case 'in progress':
      case 'working':
        return isDarkMode ? Colors.orangeAccent : Colors.orange;
      case 'resolved':
      case 'completed':
        return isDarkMode ? Colors.lightGreen : Colors.green;
      case 'closed':
        return isDarkMode ? Colors.grey[400]! : Colors.grey;
      case 'rejected':
      case 'cancelled':
        return isDarkMode ? Colors.redAccent : Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getPriorityColor(String priority, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (priority?.toLowerCase()) {
      case 'high':
        return isDarkMode ? Colors.redAccent : Colors.red;
      case 'medium':
        return isDarkMode ? Colors.orangeAccent : Colors.orange;
      case 'low':
        return isDarkMode ? Colors.lightBlue : Colors.blue;
      default:
        return isDarkMode ? Colors.grey[400]! : Colors.grey;
    }
  }

  List<String> _extractImageUrls(String html) {
    List<String> urls = [];
    try {
      final regex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
      final matches = regex.allMatches(html);

      for (var match in matches) {
        if (match.groupCount >= 1) {
          final url = match.group(1);
          if (url != null && url.isNotEmpty && (url.contains('http') || url.contains('/files/'))) {
            String fullUrl = url;
            if (url.startsWith('/files/')) {
              fullUrl = 'http://erp.telemko.com$url';
            }
            urls.add(fullUrl);
          }
        }
      }
    } catch (e) {
      print("[TicketHistoryScreen] Error extracting images: $e");
    }
    return urls;
  }

  String _cleanDescriptionText(String html) {
    try {
      return html
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim();
    } catch (e) {
      return html;
    }
  }

  bool _isPhoneNumber(String str) {
    if (str.isEmpty) return false;
    final digitsOnly = str.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = ticket["status"]?.toString() ?? "Open";
    final priority = ticket["priority"]?.toString() ?? "Medium";
    final subject = ticket["subject"] ?? "No Subject";
    final description = ticket["description"] ?? "";
    final creationDate = _formatDate(ticket["creation"]);
    final ticketId = ticket["name"] ?? "N/A";

    final customerName = ticket["customer"]?.toString() ??
        ticket["customer_name"]?.toString() ??
        ticket["raised_by"]?.toString() ??
        "Not specified";

    final customerMobile = _extractMobileNumber(ticket);
    final vehicleNumber = _extractVehicleNumber(ticket);
    final issueType = ticket["issue_type"]?.toString() ?? "General";

    final imageUrls = _extractImageUrls(description);
    final hasImages = imageUrls.isNotEmpty;

    final cleanDescription = _cleanDescriptionText(description);
    final descriptionPreview = cleanDescription.length > 100
        ? "${cleanDescription.substring(0, 100)}..."
        : cleanDescription;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: isDarkMode ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ticket #$ticketId",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creationDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status, context).withOpacity(isDarkMode ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(status, context),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status, context),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (priority.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority, context).withOpacity(isDarkMode ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Priority: $priority",
                            style: TextStyle(
                              color: _getPriorityColor(priority, context),
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

              Text(
                subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: "Customer",
                      value: customerName,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: "Mobile",
                      value: customerMobile,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      icon: Icons.directions_car,
                      label: "Vehicle No.",
                      value: vehicleNumber,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      icon: Icons.category,
                      label: "Issue Type",
                      value: issueType,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (hasImages)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.green.withOpacity(0.2)
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.green.withOpacity(0.5)
                          : Colors.green[100]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image,
                        size: 14,
                        color: isDarkMode ? Colors.greenAccent : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${imageUrls.length} image(s)",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.greenAccent : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              if (descriptionPreview.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Description:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descriptionPreview,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View Details",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[200] : Colors.black87,
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

  void _showTicketDetails(Map<String, dynamic> ticket) {
    final customerName = ticket["customer"]?.toString() ??
        ticket["customer_name"]?.toString() ??
        ticket["raised_by"]?.toString() ??
        "Not specified";

    final customerMobile = _extractMobileNumber(ticket);
    final vehicleNumber = _extractVehicleNumber(ticket);
    final customerEmail = ticket["raised_by"]?.toString() ?? "Not specified";

    final description = ticket["description"]?.toString() ?? "";
    final imageUrls = _extractImageUrls(description);
    final cleanDescription = _cleanDescriptionText(description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTicketDetailsSheet(
          ticket,
          customerName,
          customerMobile,
          vehicleNumber,
          customerEmail,
          description,
          imageUrls,
          cleanDescription
      ),
    );
  }

  Widget _buildTicketDetailsSheet(
      Map<String, dynamic> ticket,
      String customerName,
      String customerMobile,
      String vehicleNumber,
      String customerEmail,
      String description,
      List<String> imageUrls,
      String cleanDescription
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ticket #${ticket["name"] ?? "N/A"}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket["status"] ?? "Open", context)
                          .withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(ticket["status"] ?? "Open", context),
                      ),
                    ),
                    child: Text(
                      (ticket["status"] ?? "Open").toString().toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(ticket["status"] ?? "Open", context),
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
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: isDarkMode ? 0 : 2,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Customer Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailCardRow("Customer Name", customerName, isDarkMode),
                              _buildDetailCardRow("Mobile Number", customerMobile, isDarkMode),
                              _buildDetailCardRow("Email", customerEmail, isDarkMode),
                              _buildDetailCardRow("Vehicle Number", vehicleNumber, isDarkMode),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        elevation: isDarkMode ? 0 : 2,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Issue Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailCardRow("Subject", ticket["subject"] ?? "No subject", isDarkMode),
                              _buildDetailCardRow("Type", ticket["issue_type"] ?? "General", isDarkMode),
                              _buildDetailCardRow("Priority", ticket["priority"] ?? "Medium", isDarkMode),
                              _buildDetailCardRow("Status", ticket["status"] ?? "Open", isDarkMode),
                              if (ticket["resolution_details"] != null && ticket["resolution_details"].toString().isNotEmpty)
                                _buildDetailCardRow("Resolution Details", ticket["resolution_details"].toString(), isDarkMode),
                            ],
                          ),
                        ),
                      ),

                      if (imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          elevation: isDarkMode ? 0 : 2,
                          color: isDarkMode
                              ? Theme.of(context).colorScheme.surfaceVariant
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attachments",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imageUrls.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDarkMode
                                                ? Colors.grey[700]!
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            imageUrls[index],
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: isDarkMode
                                                        ? Colors.grey[600]
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      Card(
                        elevation: isDarkMode ? 0 : 2,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (imageUrls.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Text Description:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      Text(
                                        cleanDescription.isNotEmpty ? cleanDescription : "No description provided",
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: isDarkMode ? Colors.grey[300] : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildDetailCardRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[200] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No tickets found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create your first support ticket to get started",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: "Create Ticket",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketFormScreen()));
              },
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDarkMode ? Colors.redAccent : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load tickets",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[200] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  text: "Retry",
                  onPressed: _loadTickets,
                  color: Theme.of(context).colorScheme.primary,
                  expanded: false,
                  width: 120,
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: "Login Again",
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Support Tickets"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              isRefreshing ? Icons.refresh : Icons.refresh_outlined,
              color: Colors.white,
            ),
            onPressed: isRefreshing ? null : _refreshTickets,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Container(
        color: isDarkMode
            ? Theme.of(context).colorScheme.background
            : Colors.grey[50],
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : errorMessage.isNotEmpty
            ? _buildErrorState()
            : tickets.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
          onRefresh: _loadTickets,
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              return _buildTicketCard(tickets[index], index);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketFormScreen()));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
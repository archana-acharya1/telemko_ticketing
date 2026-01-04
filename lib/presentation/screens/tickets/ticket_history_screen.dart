import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/tickets/ticket_form_screen.dart';
import '../../../services/issue_service.dart';
import '../../../core/theme/app_colors.dart';
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
          SnackBar(content: Text("Session expired. Please login again.")),
        );

        // Navigate back to login
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
      // Fetch tickets with ALL fields including custom_vehical_number
      final fetchedTickets = await IssueService.fetchMyIssues();

      // DEBUG: Print what fields are available
      if (fetchedTickets.isNotEmpty) {
        print("[TicketHistoryScreen] === DEBUG ALL TICKET FIELDS ===");
        for (int i = 0; i < fetchedTickets.length && i < 5; i++) {
          final ticket = fetchedTickets[i] as Map<String, dynamic>;
          print("\n[TicketHistoryScreen] Ticket #${i + 1} - ID: ${ticket["name"]}");

          // Check forw ALL fields including custom ones
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

          // Test extraction
          print("  Test Mobile: ${_extractMobileNumber(ticket)}");
          print("  Test Vehicle: ${_extractVehicleNumber(ticket)}");
        }
        print("[TicketHistoryScreen] ===============================");
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

  // NEW: Improved mobile number extraction
  String _extractMobileNumber(Map<String, dynamic> ticket) {
    // Priority 1: Check custom_mobile_no (main field from form)
    if (ticket.containsKey("custom_mobile_no") &&
        ticket["custom_mobile_no"] != null &&
        ticket["custom_mobile_no"].toString().trim().isNotEmpty) {
      final value = ticket["custom_mobile_no"].toString().trim();
      print("[Mobile Extraction] Found in custom_mobile_no: $value");
      return value;
    }

    // Priority 2: Check mobile_no (alternative field)
    if (ticket.containsKey("mobile_no") &&
        ticket["mobile_no"] != null &&
        ticket["mobile_no"].toString().trim().isNotEmpty) {
      final value = ticket["mobile_no"].toString().trim();
      print("[Mobile Extraction] Found in mobile_no: $value");
      return value;
    }

    // Priority 3: Check contact_mobile
    if (ticket.containsKey("contact_mobile") &&
        ticket["contact_mobile"] != null &&
        ticket["contact_mobile"].toString().trim().isNotEmpty) {
      final value = ticket["contact_mobile"].toString().trim();
      print("[Mobile Extraction] Found in contact_mobile: $value");
      return value;
    }

    // Priority 4: Check if raised_by is a phone number
    if (ticket.containsKey("raised_by") &&
        ticket["raised_by"] != null) {
      final value = ticket["raised_by"].toString().trim();
      if (_isPhoneNumber(value)) {
        print("[Mobile Extraction] Using raised_by as phone: $value");
        return value;
      }
    }

    // Priority 5: Check all fields that might contain phone number
    final phoneKeywords = ['phone', 'mobile', 'contact'];
    for (final key in ticket.keys) {
      if (phoneKeywords.any((keyword) => key.toLowerCase().contains(keyword))) {
        if (ticket[key] != null && ticket[key].toString().trim().isNotEmpty) {
          final value = ticket[key].toString().trim();
          print("[Mobile Extraction] Found in $key: $value");
          return value;
        }
      }
    }

    print("[Mobile Extraction] No mobile number found");
    return "Not specified";
  }

  // NEW: Improved vehicle number extraction
  String _extractVehicleNumber(Map<String, dynamic> ticket) {
    // Priority 1: Check custom_vehical_number (note spelling: vehical not vehicle)
    if (ticket.containsKey("custom_vehical_number") &&
        ticket["custom_vehical_number"] != null &&
        ticket["custom_vehical_number"].toString().trim().isNotEmpty) {
      final value = ticket["custom_vehical_number"].toString().trim();
      print("[Vehicle Extraction] Found in custom_vehical_number: $value");
      return value;
    }

    // Priority 2: Check custom_vehicle_number (correct spelling)
    if (ticket.containsKey("custom_vehicle_number") &&
        ticket["custom_vehicle_number"] != null &&
        ticket["custom_vehicle_number"].toString().trim().isNotEmpty) {
      final value = ticket["custom_vehicle_number"].toString().trim();
      print("[Vehicle Extraction] Found in custom_vehicle_number: $value");
      return value;
    }

    // Priority 3: Check vehicle_number
    if (ticket.containsKey("vehicle_number") &&
        ticket["vehicle_number"] != null &&
        ticket["vehicle_number"].toString().trim().isNotEmpty) {
      final value = ticket["vehicle_number"].toString().trim();
      print("[Vehicle Extraction] Found in vehicle_number: $value");
      return value;
    }

    // Priority 4: Check vehical_number (typo)
    if (ticket.containsKey("vehical_number") &&
        ticket["vehical_number"] != null &&
        ticket["vehical_number"].toString().trim().isNotEmpty) {
      final value = ticket["vehical_number"].toString().trim();
      print("[Vehicle Extraction] Found in vehical_number: $value");
      return value;
    }

    // Priority 5: Check all fields that might contain vehicle number
    final vehicleKeywords = ['vehicle', 'vehical', 'registration', 'plate', 'reg'];
    for (final key in ticket.keys) {
      if (vehicleKeywords.any((keyword) => key.toLowerCase().contains(keyword))) {
        if (ticket[key] != null && ticket[key].toString().trim().isNotEmpty) {
          final value = ticket[key].toString().trim();
          print("[Vehicle Extraction] Found in $key: $value");
          return value;
        }
      }
    }

    // Priority 6: Check description for vehicle pattern
    if (ticket.containsKey("description") && ticket["description"] != null) {
      final description = ticket["description"].toString();
      // Look for vehicle number patterns like MH12AB1234, DL01CD5678
      final vehiclePattern = RegExp(r'[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,2}\s?\d{4}');
      final match = vehiclePattern.firstMatch(description);
      if (match != null) {
        final value = match.group(0)!;
        print("[Vehicle Extraction] Found in description: $value");
        return value;
      }
    }

    print("[Vehicle Extraction] No vehicle number found");
    return "Not specified";
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

  // Helper to extract image URLs from HTML description
  List<String> _extractImageUrls(String html) {
    List<String> urls = [];
    try {
      // Simple regex to find img tags
      final regex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
      final matches = regex.allMatches(html);

      for (var match in matches) {
        if (match.groupCount >= 1) {
          final url = match.group(1);
          if (url != null && url.isNotEmpty && (url.contains('http') || url.contains('/files/'))) {
            // Make sure URL is absolute
            String fullUrl = url;
            if (url.startsWith('/files/')) {
              fullUrl = 'http://erp.telemko.com$url';
            }
            urls.add(fullUrl);
          }
        }
      }
      print("[TicketHistoryScreen] Found ${urls.length} images in description");
    } catch (e) {
      print("[TicketHistoryScreen] Error extracting images: $e");
    }
    return urls;
  }

  // Clean HTML tags for text display
  String _cleanDescriptionText(String html) {
    try {
      // Simple regex to remove HTML tags
      return html
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim();
    } catch (e) {
      return html;
    }
  }

  // Check if string is a phone number
  bool _isPhoneNumber(String str) {
    if (str.isEmpty) return false;
    // Remove all non-digit characters
    final digitsOnly = str.replaceAll(RegExp(r'[^0-9]'), '');
    // Check if it's 10-15 digits (reasonable phone number length)
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  // Build the ticket card with all customer details
  Widget _buildTicketCard(Map<String, dynamic> ticket, int index) {
    final status = ticket["status"]?.toString() ?? "Open";
    final priority = ticket["priority"]?.toString() ?? "Medium";
    final subject = ticket["subject"] ?? "No Subject";
    final description = ticket["description"] ?? "";
    final creationDate = _formatDate(ticket["creation"]);
    final ticketId = ticket["name"] ?? "N/A";

    // Extract customer details using improved methods
    final customerName = ticket["customer"]?.toString() ??
        ticket["customer_name"]?.toString() ??
        ticket["raised_by"]?.toString() ??
        "Not specified";

    // Use the new extraction methods
    final customerMobile = _extractMobileNumber(ticket);
    final vehicleNumber = _extractVehicleNumber(ticket);
    final issueType = ticket["issue_type"]?.toString() ?? "General";

    // Extract images from description
    final imageUrls = _extractImageUrls(description);
    final hasImages = imageUrls.isNotEmpty;

    // Clean description for text preview
    final cleanDescription = _cleanDescriptionText(description);
    final descriptionPreview = cleanDescription.length > 100
        ? "${cleanDescription.substring(0, 100)}..."
        : cleanDescription;

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

                    // Mobile Number (extracted using improved method)
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: "Mobile",
                      value: customerMobile,
                    ),

                    const SizedBox(height: 6),

                    // Vehicle Number (extracted using improved method)
                    _buildDetailRow(
                      icon: Icons.directions_car,
                      label: "Vehicle No.",
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

              // Image preview indicator
              if (hasImages)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        "${imageUrls.length} image(s)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Description Preview
              if (descriptionPreview.isNotEmpty)
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
                      descriptionPreview,
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

    // Use improved extraction methods
    final customerMobile = _extractMobileNumber(ticket);
    final vehicleNumber = _extractVehicleNumber(ticket);
    final customerEmail = ticket["raised_by"]?.toString() ?? "Not specified";

    final description = ticket["description"]?.toString() ?? "";
    final imageUrls = _extractImageUrls(description);
    final cleanDescription = _cleanDescriptionText(description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTicketDetailsSheet(ticket, customerName, customerMobile, vehicleNumber, customerEmail, description, imageUrls, cleanDescription),
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
                              _buildDetailCardRow("Customer Name", customerName),
                              _buildDetailCardRow("Mobile Number", customerMobile),
                              _buildDetailCardRow("Email", customerEmail),
                              _buildDetailCardRow("Vehicle Number", vehicleNumber),
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
                              if (ticket["resolution_details"] != null && ticket["resolution_details"].toString().isNotEmpty)
                                _buildDetailCardRow("Resolution Details", ticket["resolution_details"].toString()),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Attachments Card (if any images found)
                      if (imageUrls.isNotEmpty)
                        Column(
                          children: [
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Attachments",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                                              border: Border.all(color: Colors.grey[300]!),
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
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child: Icon(Icons.broken_image, color: Colors.grey),
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
                            const SizedBox(height: 16),
                          ],
                        ),

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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
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
                                            const Text(
                                              "Text Description:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      Text(
                                        cleanDescription.isNotEmpty ? cleanDescription : "No description provided",
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
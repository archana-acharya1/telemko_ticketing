import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import 'ticket_history_screen.dart';

class TicketFormScreen extends StatefulWidget {
  // Add an optional parameter for pre-selected subject
  final String? preSelectedSubject;

  const TicketFormScreen({super.key, this.preSelectedSubject});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final descriptionController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  bool isLoading = false;
  bool isFetchingUserInfo = true;
  String? customerName;
  String? customerEmail;
  String? mobileNumber;
  String? errorMessage;
  bool isPhoneLogin = false; // Track if user logged in with phone

  // Subjects for dropdown
  final List<String> subjects = [
    "Inactive Device Issue",
    "Fuel Data Not Showing",
    "Video Not Showing",
    "GPS Not Working",
    "Other Issue"
  ];
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchUserInformation();

    // Use pre-selected subject if provided, otherwise default to first item
    selectedSubject = widget.preSelectedSubject ?? subjects[0];
  }

  Future<void> _fetchUserInformation() async {
    setState(() {
      isFetchingUserInfo = true;
      errorMessage = null;
    });

    try {
      final session = await SessionManager.getCustomerSession();
      final sid = session?["sid"] ?? "";

      if (sid.isEmpty) {
        throw Exception("No active session found. Please login again.");
      }

      // Get logged user from Frappe API
      final loggedUserUrl = Uri.parse("http://erp.telemko.com/api/method/frappe.auth.get_logged_user");

      final loggedUserResponse = await http.get(
        loggedUserUrl,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (loggedUserResponse.statusCode == 200) {
        final loggedUserData = jsonDecode(loggedUserResponse.body);
        final username = loggedUserData["message"]?.toString() ?? "";

        if (username.isNotEmpty) {
          // Check if username is phone number (contains only digits)
          final isPhoneNumber = RegExp(r'^[0-9]+$').hasMatch(username);
          setState(() => isPhoneLogin = isPhoneNumber);

          print("[TicketFormScreen] Username: $username, Is Phone Login: $isPhoneNumber");

          await _fetchUserDetails(sid, username, session, isPhoneNumber);
        } else {
          // Use session data as fallback
          customerName = session?["customer_name"] ?? "";
          customerEmail = session?["email"] ?? "";
          mobileNumber = session?["mobile_no"] ?? "";
        }
      } else {
        // Fallback to session data
        customerName = session?["customer_name"] ?? "";
        customerEmail = session?["email"] ?? "";
        mobileNumber = session?["mobile_no"] ?? "";
      }
    } catch (e) {
      print("[TicketFormScreen] Error fetching user info: $e");
      errorMessage = "Failed to load user information: ${e.toString()}";

      // Fallback to session data
      final session = await SessionManager.getCustomerSession();
      customerName = session?["customer_name"] ?? "";
      customerEmail = session?["email"] ?? "";
      mobileNumber = session?["mobile_no"] ?? "";
    } finally {
      setState(() => isFetchingUserInfo = false);
    }
  }

  Future<void> _fetchUserDetails(String sid, String username, Map<String, dynamic>? session, bool isPhoneNumber) async {
    try {
      // If it's a phone number, fetch customer by mobile_no
      if (isPhoneNumber) {
        await _fetchCustomerByMobile(sid, username, session);
        return;
      }

      // Otherwise, it's email or username
      // First try to get from User doctype
      final userUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/User/$username"
              "?fields=[\"email\", \"full_name\", \"mobile_no\"]"
      );

      final userResponse = await http.get(
        userUrl,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        if (userData["data"] != null) {
          final user = userData["data"];
          setState(() {
            customerEmail = user["email"]?.toString() ?? "";
            customerName = user["full_name"]?.toString() ?? session?["customer_name"] ?? "";
            mobileNumber = user["mobile_no"]?.toString() ?? session?["mobile_no"] ?? "";
          });

          // Debug: Check what we got
          print("[TicketFormScreen] User details from User doctype:");
          print("  Email: $customerEmail");
          print("  Name: $customerName");
          print("  Mobile: $mobileNumber");

          // If we got email, try to get customer details by email
          if (customerEmail != null && customerEmail!.isNotEmpty && customerEmail!.contains("@")) {
            await _fetchCustomerByEmail(sid, customerEmail!, session);
          }
          return;
        }
      }

      // If not found in User, try Customer doctype
      await _fetchCustomerDetails(sid, username, session);
    } catch (e) {
      print("[TicketFormScreen] Error fetching user details: $e");
      setState(() {
        customerName = session?["customer_name"] ?? username;
        customerEmail = session?["email"] ?? "";
        mobileNumber = session?["mobile_no"] ?? "";
      });
    }
  }

  Future<void> _fetchCustomerByMobile(String sid, String mobileNumber, Map<String, dynamic>? session) async {
    try {
      print("[TicketFormScreen] Fetching customer by mobile: $mobileNumber");

      final customerUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/Customer"
              "?fields=[\"name\", \"customer_name\", \"mobile_no\", \"email_id\"]"
              "&filters=[[\"mobile_no\", \"=\", \"$mobileNumber\"]]"
              "&limit_page_length=1"
      );

      final customerResponse = await http.get(
        customerUrl,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (customerResponse.statusCode == 200) {
        final customerData = jsonDecode(customerResponse.body);
        if (customerData["data"] != null && customerData["data"].isNotEmpty) {
          final customer = customerData["data"][0];
          print("[TicketFormScreen] Found customer by mobile:");
          print("  Customer ID: ${customer["name"]}");
          print("  Customer Name: ${customer["customer_name"]}");
          print("  Mobile: ${customer["mobile_no"]}");
          print("  Email: ${customer["email_id"]}");

          setState(() {
            customerName = customer["customer_name"]?.toString() ?? "";
            mobileNumber = customer["mobile_no"]?.toString() ?? mobileNumber;
            customerEmail = customer["email_id"]?.toString() ?? "";
          });
        } else {
          print("[TicketFormScreen] No customer found with mobile: $mobileNumber");
          // Create a dummy email for phone-only users
          setState(() {
            customerName = session?["customer_name"] ?? "Customer";
            customerEmail = "$mobileNumber@phoneuser.telemko.com"; // Dummy email
          });
        }
      } else {
        // Create a dummy email for phone-only users
        setState(() {
          customerName = session?["customer_name"] ?? "Customer";
          customerEmail = "$mobileNumber@phoneuser.telemko.com"; // Dummy email
        });
      }
    } catch (e) {
      print("[TicketFormScreen] Error fetching customer by mobile: $e");
      // Create a dummy email for phone-only users
      setState(() {
        customerName = session?["customer_name"] ?? "Customer";
        customerEmail = "$mobileNumber@phoneuser.telemko.com"; // Dummy email
      });
    }
  }

  Future<void> _fetchCustomerByEmail(String sid, String email, Map<String, dynamic>? session) async {
    try {
      final customerUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/Customer"
              "?fields=[\"name\", \"customer_name\", \"mobile_no\", \"email_id\"]"
              "&filters=[[\"email_id\", \"=\", \"$email\"]]"
              "&limit_page_length=1"
      );

      final customerResponse = await http.get(
        customerUrl,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (customerResponse.statusCode == 200) {
        final customerData = jsonDecode(customerResponse.body);
        if (customerData["data"] != null && customerData["data"].isNotEmpty) {
          final customer = customerData["data"][0];
          print("[TicketFormScreen] Found customer by email:");
          print("  Customer ID: ${customer["name"]}");
          print("  Customer Name: ${customer["customer_name"]}");
          print("  Mobile: ${customer["mobile_no"]}");
          print("  Email: ${customer["email_id"]}");

          setState(() {
            if (customer["customer_name"] != null && customer["customer_name"].toString().isNotEmpty) {
              customerName = customer["customer_name"]?.toString() ?? customerName;
            }
            if (customer["mobile_no"] != null && customer["mobile_no"].toString().isNotEmpty) {
              mobileNumber = customer["mobile_no"]?.toString() ?? mobileNumber;
            }
          });
        }
      }
    } catch (e) {
      print("[TicketFormScreen] Error fetching customer by email: $e");
    }
  }

  Future<void> _fetchCustomerDetails(String sid, String username, Map<String, dynamic>? session) async {
    try {
      // Try different filters
      String filterField = username.contains("@") ? "email_id" : "customer_name";
      String filterValue = username;

      final customerUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/Customer"
              "?fields=[\"name\", \"customer_name\", \"mobile_no\", \"email_id\"]"
              "&filters=[[\"$filterField\", \"=\", \"$filterValue\"]]"
              "&limit_page_length=1"
      );

      final customerResponse = await http.get(
        customerUrl,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (customerResponse.statusCode == 200) {
        final customerData = jsonDecode(customerResponse.body);
        if (customerData["data"] != null && customerData["data"].isNotEmpty) {
          final customer = customerData["data"][0];
          setState(() {
            customerName = customer["customer_name"]?.toString() ?? username;
            mobileNumber = customer["mobile_no"]?.toString() ?? "";
            customerEmail = customer["email_id"]?.toString() ?? "";
          });
          return;
        }
      }

      // If not found, use session data
      setState(() {
        customerName = session?["customer_name"] ?? username;
        mobileNumber = session?["mobile_no"] ?? "";
        customerEmail = session?["email"] ?? "";
      });
    } catch (e) {
      print("[TicketFormScreen] Error fetching customer details: $e");
      setState(() {
        customerName = session?["customer_name"] ?? username;
        mobileNumber = session?["mobile_no"] ?? "";
        customerEmail = session?["email"] ?? "";
      });
    }
  }

  Future<void> submitTicket() async {
    final description = descriptionController.text.trim();
    final vehicleNumber = vehicleNumberController.text.trim();

    // Validate required fields
    if (selectedSubject == null || selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a subject")),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description")),
      );
      return;
    }

    // IMPORTANT: For phone login users, we generate a dummy email
    if (isPhoneLogin && (customerEmail == null || customerEmail!.isEmpty)) {
      // Generate a consistent dummy email for phone users
      final phone = mobileNumber ?? "unknown";
      customerEmail = "$phone@phoneuser.telemko.com";
    }

    setState(() => isLoading = true);

    try {
      final session = await SessionManager.getCustomerSession();
      final sid = session?["sid"] ?? "";

      // Get values with fallbacks
      final loggedCustomerName = customerName ?? session?["customer_name"] ?? "Customer";
      final loggedCustomerEmail = customerEmail ?? session?["email"] ?? "";
      final loggedMobile = mobileNumber ?? session?["mobile_no"] ?? "";

      if (sid.isEmpty) {
        throw Exception("No session found. Please login again.");
      }

      // DEBUG: Print what we're sending
      print("[TicketFormScreen] Creating ticket with:");
      print("  Customer Email: $loggedCustomerEmail");
      print("  Customer Name: $loggedCustomerName");
      print("  Mobile: $loggedMobile");
      print("  Vehicle: $vehicleNumber");
      print("  Is Phone Login: $isPhoneLogin");

      // Create ticket with ALL customer details
      final Map<String, dynamic> ticketData = {
        "subject": selectedSubject,
        "description": description,
        "status": "Open", // Default status
      };

      // SOLUTION: Use customer_name for the customer field - this should exist in your ERP
      // For phone users without proper customer_name, use mobile number as customer field
      if (loggedCustomerName.isNotEmpty && loggedCustomerName != "Customer") {
        // Use customer name for the customer field
        ticketData["customer"] = loggedCustomerName;
      } else if (loggedMobile.isNotEmpty) {
        // For phone users, use mobile number as customer
        ticketData["customer"] = loggedMobile;
        print("[TicketFormScreen] Using mobile as customer field: $loggedMobile");
      } else {
        // Fallback to email
        ticketData["customer"] = loggedCustomerEmail;
      }

      // Customer display name
      if (loggedCustomerName.isNotEmpty) {
        ticketData["customer_name"] = loggedCustomerName;
      }

      // Who raised the ticket - use email or mobile for phone users
      if (loggedCustomerEmail.isNotEmpty) {
        ticketData["raised_by"] = loggedCustomerEmail;
      } else if (loggedMobile.isNotEmpty) {
        // For phone-only users, use mobile number as raised_by
        ticketData["raised_by"] = loggedMobile;
      }

      // Mobile number
      if (loggedMobile.isNotEmpty) {
        ticketData["mobile_no"] = loggedMobile;
      }

      // Vehicle number - Use custom_vehical_number as per your ERP
      if (vehicleNumber.isNotEmpty) {
        ticketData["custom_vehical_number"] = vehicleNumber;
      }

      final url = Uri.parse("http://erp.telemko.com/api/resource/Issue");

      // Debug log
      print("[TicketFormScreen] Final ticket data being sent:");
      ticketData.forEach((key, value) {
        print("  $key: $value");
      });

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
        body: jsonEncode(ticketData),
      );

      print("[TicketFormScreen] Create ticket response: ${response.statusCode}");
      print("[TicketFormScreen] Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final ticketId = responseData["data"]?["name"] ?? "";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ticketId.isNotEmpty
                ? "Ticket #$ticketId created successfully"
                : "Ticket created successfully"),
          ),
        );

        // Clear form
        descriptionController.clear();
        vehicleNumberController.clear();

        // Navigate to Ticket History after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
          );
        });
      } else {
        final errorBody = response.body;
        throw Exception(
            "Failed to create ticket. Status: ${response.statusCode}\n$errorBody"
        );
      }
    } catch (e) {
      print("[TicketFormScreen] Error creating ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildInfoField(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value ?? "Loading...",
            style: TextStyle(
              fontSize: 16,
              color: value != null ? Colors.black87 : Colors.grey,
              fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: controller,
          hintText: hintText,
          prefixIcon: prefixIcon,
          maxLines: maxLines,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subject *",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubject,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              iconSize: 24,
              elevation: 8,
              isExpanded: true,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSubject = newValue;
                });
              },
              items: subjects.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Support Ticket"),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: isFetchingUserInfo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show a note if GPS Not Working is pre-selected
            if (selectedSubject == "GPS Not Working")
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed, color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "GPS Issue Ticket - 'GPS Not Working' is pre-selected",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Customer Information Section
            const Text(
              "Your Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Auto-filled from your account",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Name (auto-filled, read-only)
            _buildInfoField("Customer Name", customerName),

            // Email (auto-filled, read-only) - Show note for phone users
            if (isPhoneLogin && (customerEmail == null || !customerEmail!.contains("@")))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoField("Email", "Not available (Phone login)"),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Note: You logged in with phone number. A system email will be used for ticket creation.",
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              )
            else
              _buildInfoField("Email", customerEmail),

            // Mobile Number (auto-filled, read-only)
            _buildInfoField("Mobile Number", mobileNumber),

            const SizedBox(height: 24),

            // Ticket Information Section
            const Text(
              "Ticket Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Subject Dropdown (required)
            _buildSubjectDropdown(),

            // Vehicle Number Field (optional)
            _buildLabeledTextField(
              label: "Vehicle Number (Optional)",
              hintText: "Enter vehicle number (if applicable)",
              prefixIcon: Icons.directions_car,
              controller: vehicleNumberController,
            ),

            // Description Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Description *",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: descriptionController,
                  hintText: "Describe your issue in detail...",
                  prefixIcon: Icons.description,
                  maxLines: 6,
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: isLoading ? "Creating Ticket..." : "Submit Ticket",
                onPressed: isLoading ? null : submitTicket,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            // Info Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPhoneLogin
                          ? "You logged in with phone number. Tickets will be linked to your mobile number."
                          : "Your customer information is fetched from your account. Tickets will be linked to your email.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
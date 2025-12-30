import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../auth/logout_screen.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? userName;
  String? userEmail;
  String? userMobile;
  String? errorMessage;
  bool isPhoneLogin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final session = await SessionManager.getCustomerSession();
      final sid = session?["sid"] ?? "";

      if (sid.isEmpty) {
        throw Exception("No active session found");
      }

      // First, get logged username from Frappe
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
          // Check if username is phone number
          final isPhoneNumber = RegExp(r'^[0-9]+$').hasMatch(username);
          setState(() => isPhoneLogin = isPhoneNumber);

          if (isPhoneNumber) {
            // For phone login, fetch customer by mobile
            await _fetchCustomerByMobile(sid, username, session);
          } else {
            // For email/username login
            await _fetchUserDetails(sid, username, session);
          }
        } else {
          // Use session data
          _setFromSession(session);
        }
      } else {
        // Fallback to session data
        _setFromSession(session);
      }
    } catch (e) {
      print("[ProfileScreen] Error fetching user data: $e");
      setState(() {
        errorMessage = "Failed to load profile data";
        // Try to get from session
        _tryGetFromSession();
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCustomerByMobile(String sid, String mobileNumber, Map<String, dynamic>? session) async {
    try {
      final customerUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/Customer"
              "?fields=[\"customer_name\", \"mobile_no\", \"email_id\"]"
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
          setState(() {
            userName = customer["customer_name"]?.toString() ?? "Customer";
            userMobile = customer["mobile_no"]?.toString() ?? mobileNumber;
            userEmail = customer["email_id"]?.toString() ?? "$mobileNumber@phoneuser.telemko.com";
          });
          return;
        }
      }

      // If customer not found, use session data
      _setFromSession(session);
    } catch (e) {
      print("[ProfileScreen] Error fetching customer by mobile: $e");
      _setFromSession(session);
    }
  }

  Future<void> _fetchUserDetails(String sid, String username, Map<String, dynamic>? session) async {
    try {
      // Try to get from User doctype first
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
            userName = user["full_name"]?.toString() ?? session?["customer_name"] ?? username;
            userEmail = user["email"]?.toString() ?? "";
            userMobile = user["mobile_no"]?.toString() ?? session?["mobile_no"] ?? "";
          });

          // If we have email, try to get customer details
          if (userEmail != null && userEmail!.isNotEmpty && userEmail!.contains("@")) {
            await _fetchCustomerByEmail(sid, userEmail!, session);
          }
          return;
        }
      }

      // Try to get from Customer doctype
      await _fetchCustomerDetails(sid, username, session);
    } catch (e) {
      print("[ProfileScreen] Error fetching user details: $e");
      _setFromSession(session);
    }
  }

  Future<void> _fetchCustomerByEmail(String sid, String email, Map<String, dynamic>? session) async {
    try {
      final customerUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/Customer"
              "?fields=[\"customer_name\", \"mobile_no\", \"email_id\"]"
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
          setState(() {
            if (customer["customer_name"] != null && customer["customer_name"].toString().isNotEmpty) {
              userName = customer["customer_name"]?.toString() ?? userName;
            }
            if (customer["mobile_no"] != null && customer["mobile_no"].toString().isNotEmpty) {
              userMobile = customer["mobile_no"]?.toString() ?? userMobile;
            }
          });
        }
      }
    } catch (e) {
      print("[ProfileScreen] Error fetching customer by email: $e");
    }
  }

  Future<void> _fetchCustomerDetails(String sid, String username, Map<String, dynamic>? session) async {
    try {
      String filterField = username.contains("@") ? "email_id" : "customer_name";
      String filterValue = username;

      final customerUrl = Uri.parse(
          "http://erp.telemko.com/api/resource/Customer"
              "?fields=[\"customer_name\", \"mobile_no\", \"email_id\"]"
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
            userName = customer["customer_name"]?.toString() ?? username;
            userMobile = customer["mobile_no"]?.toString() ?? "";
            userEmail = customer["email_id"]?.toString() ?? "";
          });
          return;
        }
      }

      _setFromSession(session);
    } catch (e) {
      print("[ProfileScreen] Error fetching customer details: $e");
      _setFromSession(session);
    }
  }

  void _setFromSession(Map<String, dynamic>? session) {
    setState(() {
      userName = session?["customer_name"]?.toString() ?? "User";
      userEmail = session?["email"]?.toString() ?? "Not available";
      userMobile = session?["mobile_no"]?.toString() ?? "Not available";

      // If it's a phone login and no email, create a dummy email
      if (isPhoneLogin && (userEmail == null || userEmail!.isEmpty || !userEmail!.contains("@"))) {
        final phone = userMobile ?? "unknown";
        userEmail = "$phone@phoneuser.telemko.com";
      }
    });
  }

  void _tryGetFromSession() async {
    try {
      final session = await SessionManager.getCustomerSession();
      _setFromSession(session);
    } catch (e) {
      print("[ProfileScreen] Error getting session: $e");
    }
  }

  Widget _buildInfoRow(String label, String? value, {bool isPhoneLoginField = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? "Loading...",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (isPhoneLoginField && userEmail != null && userEmail!.contains("phoneuser.telemko.com"))
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              "Note: You logged in with phone number",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Loading profile...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? "Failed to load profile",
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Retry",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Profile",
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _fetchUserData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
          ? _buildErrorState()
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  isPhoneLogin ? Icons.phone_android : Icons.person,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow("Name", userName),
            _buildInfoRow("Email", userEmail, isPhoneLoginField: isPhoneLogin),
            _buildInfoRow("Phone Number", userMobile),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "App Version",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              "1.0.0",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogoutScreen()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
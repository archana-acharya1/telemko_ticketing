import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import 'ticket_history_screen.dart';

class TicketFormScreen extends StatefulWidget {
  final String? preSelectedSubject;

  const TicketFormScreen({super.key, this.preSelectedSubject});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final descriptionController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<File> selectedFiles = [];
  bool isFetchingUserInfo = true;
  String? customerName;
  String? customerEmail;
  String? mobileNumber;
  String? errorMessage;
  bool isPhoneLogin = false;

  bool isLoading = false;
  bool isUploading = false;

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
    selectedSubject = widget.preSelectedSubject ?? subjects[0];
  }

  // ================== FILE PICKER ==================

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          selectedFiles.add(file);
        });

        _showSuccess("File added: ${pickedFile.path.split('/').last}");
      }
    } catch (e) {
      print("[TicketFormScreen] Error picking image: $e");
      _showError("Failed to pick image");
    }
  }

  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  // ================== UPLOAD FILES AND GET URLS ==================

  Future<List<String>> _uploadFilesAndGetUrls() async {
    List<String> uploadedUrls = [];

    if (selectedFiles.isEmpty) return uploadedUrls;

    try {
      final session = await SessionManager.getCustomerSession();
      final sid = session?["sid"] ?? "";

      if (sid.isEmpty) {
        throw Exception("No active session found");
      }

      for (var file in selectedFiles) {
        final fileName = file.path.split('/').last;
        final fileBytes = await file.readAsBytes();

        print("[TicketFormScreen] Uploading file: $fileName");

        final url = Uri.parse("http://erp.telemko.com/api/method/upload_file");

        final request = http.MultipartRequest('POST', url);
        request.headers['Cookie'] = 'sid=$sid';
        request.headers['Accept'] = 'application/json';

        request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileName,
            )
        );

        request.fields['is_private'] = '0';
        request.fields['folder'] = 'Home';

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(responseBody);
          final message = jsonResponse["message"];

          if (message is Map<String, dynamic>) {
            String? fileUrl = message["file_url"]?.toString();
            if (fileUrl == null || fileUrl.isEmpty) {
              fileUrl = message["file_name"]?.toString();
            }

            if (fileUrl != null && fileUrl.isNotEmpty) {
              if (!fileUrl.startsWith('/files/') && !fileUrl.startsWith('http')) {
                fileUrl = '/files/$fileUrl';
              }

              if (fileUrl.startsWith('/files/')) {
                fileUrl = 'http://erp.telemko.com$fileUrl';
              }

              uploadedUrls.add(fileUrl);
              print("[TicketFormScreen] File uploaded successfully: $fileUrl");
            }
          }
        } else {
          print("[TicketFormScreen] Upload failed for $fileName");
        }
      }

      return uploadedUrls;
    } catch (e) {
      print("[TicketFormScreen] Error uploading files: $e");
      return uploadedUrls;
    }
  }

  // ================== BUILD DESCRIPTION WITH IMAGES ==================

  String _buildDescriptionWithImages(String originalDescription, List<String> fileUrls) {
    if (fileUrls.isEmpty) return originalDescription;

    String description = originalDescription;

    // Add spacing and a visual separator
    description += "\n\n\n\n<br>\n";

    // Add each image on a new line
    for (var fileUrl in fileUrls) {
      final fileName = fileUrl.split('/').last;
      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif');

      if (isImage) {
        // Image with better spacing
        description += '<br><img src="$fileUrl" style="max-width: 400px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px;"><br>\n';
      }
    }

    return description;
  }

  // ================== USER DATA FETCHING - UPDATED FIX ==================

  Future<void> _fetchUserInformation() async {
    setState(() {
      isFetchingUserInfo = true;
      errorMessage = null;
    });

    try {
      // Get session data - this works for BOTH login types
      final session = await SessionManager.getCustomerSession();

      if (session == null) {
        throw Exception("No session found. Please login again.");
      }

      final sid = session["sid"] ?? "";
      final loginType = session["login_type"] ?? "";

      if (sid.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      print("🔍 Login Type: $loginType");
      print("📱 Session Data: Name=${session["customer_name"]}, Mobile=${session["mobile_no"]}, Email=${session["email_id"]}");

      // USE SESSION DATA DIRECTLY - Don't fetch from ERP
      setState(() {
        customerName = session["customer_name"] ?? "Customer";
        mobileNumber = session["mobile_no"] ?? "";
        customerEmail = session["email_id"] ?? "";

        // Check if it's a phone login
        isPhoneLogin = loginType == "otp" || loginType == "mobile" ||
            (mobileNumber!.isNotEmpty && (customerEmail == null || customerEmail!.isEmpty));

        // If no email but we have mobile, create system email
        if (isPhoneLogin && (customerEmail == null || customerEmail!.isEmpty)) {
          if (mobileNumber!.isNotEmpty) {
            customerEmail = "$mobileNumber@phoneuser.telemko.com";
          } else {
            customerEmail = "customer@telemko.com";
          }
        }
      });

      print("✅ Using customer data:");
      print("   Name: $customerName");
      print("   Mobile: $mobileNumber");
      print("   Email: $customerEmail");
      print("   Is Phone Login: $isPhoneLogin");

    } catch (e) {
      print("[TicketFormScreen] Error: $e");
      setState(() {
        errorMessage = "Failed to load user info";
        customerName = "Customer";
        customerEmail = "customer@telemko.com";
        mobileNumber = "";
        isPhoneLogin = true;
      });
    } finally {
      setState(() => isFetchingUserInfo = false);
    }
  }

  // ================== TICKET SUBMISSION - UPDATED FIX ==================

  Future<void> submitTicket() async {
    // DEBUG: Print session info before starting
    print("🔍 === DEBUG BEFORE TICKET CREATION ===");
    final session = await SessionManager.getCustomerSession();
    print("Session: $session");
    print("customerName: $customerName");
    print("customerEmail: $customerEmail");
    print("mobileNumber: $mobileNumber");
    print("isPhoneLogin: $isPhoneLogin");
    print("================================");

    final description = descriptionController.text.trim();
    final vehicleNumber = vehicleNumberController.text.trim();

    if (selectedSubject == null || selectedSubject!.isEmpty) {
      _showError("Please select a subject");
      return;
    }

    if (description.isEmpty) {
      _showError("Please enter a description");
      return;
    }

    // Ensure we have email for phone users
    if (isPhoneLogin && (customerEmail == null || customerEmail!.isEmpty)) {
      if (mobileNumber != null && mobileNumber!.isNotEmpty) {
        customerEmail = "$mobileNumber@phoneuser.telemko.com";
      } else {
        customerEmail = "customer@telemko.com";
      }
    }

    setState(() => isLoading = true);

    try {
      final session = await SessionManager.getCustomerSession();
      final sid = session?["sid"] ?? "";

      // Use the data we already have from _fetchUserInformation()
      final loggedCustomerName = customerName ?? "Customer";
      final loggedCustomerEmail = customerEmail ?? "";
      final loggedMobile = mobileNumber ?? "";

      // Make SURE we have an email for phone users
      if (isPhoneLogin && loggedCustomerEmail.isEmpty) {
        if (loggedMobile.isNotEmpty) {
          customerEmail = "$loggedMobile@phoneuser.telemko.com";
        } else {
          customerEmail = "customer@telemko.com";
        }
      }

      print("🎫 Creating ticket with:");
      print("   Customer: $loggedCustomerName");
      print("   Email: $customerEmail");
      print("   Mobile: $loggedMobile");
      print("   Is Phone Login: $isPhoneLogin");

      if (sid.isEmpty) {
        throw Exception("No session found. Please login again.");
      }

      // ========== STEP 1: UPLOAD FILES FIRST (IF ANY) ==========
      List<String> uploadedFileUrls = [];
      if (selectedFiles.isNotEmpty) {
        setState(() => isUploading = true);
        uploadedFileUrls = await _uploadFilesAndGetUrls();
        setState(() => isUploading = false);
      }

      // ========== STEP 2: CREATE TICKET WITH EMBEDDED IMAGES ==========
      String finalDescription = description;

      // Build description with embedded HTML images
      if (uploadedFileUrls.isNotEmpty) {
        finalDescription = _buildDescriptionWithImages(description, uploadedFileUrls);
      }

      // TICKET DATA - FIXED FOR BOTH LOGIN TYPES
      final Map<String, dynamic> ticketData = {
        "subject": selectedSubject,
        "description": finalDescription, // This now contains HTML with embedded images
        "status": "Open",
      };

      // ALWAYS include customer - use mobile number if name is generic
      if (loggedCustomerName.isNotEmpty) {
        if (loggedCustomerName == "Customer" || loggedCustomerName.contains("Customer")) {
          // For generic names, use mobile number format
          if (loggedMobile.isNotEmpty) {
            ticketData["customer"] = "Customer ($loggedMobile)";
          } else {
            ticketData["customer"] = loggedCustomerName;
          }
        } else {
          ticketData["customer"] = loggedCustomerName;
        }
      }

      // ALWAYS include raised_by
      if (customerEmail != null && customerEmail!.isNotEmpty) {
        ticketData["raised_by"] = customerEmail!;
      } else if (loggedMobile.isNotEmpty) {
        ticketData["raised_by"] = loggedMobile;
      }

      // ALWAYS include mobile number
      if (loggedMobile.isNotEmpty) {
        ticketData["custom_mobile_no"] = loggedMobile;
      }

      if (vehicleNumber.isNotEmpty) {
        ticketData["custom_vehical_number"] = vehicleNumber;
      }

      print("📤 Sending ticket data: $ticketData");

      final url = Uri.parse("http://erp.telemko.com/api/resource/Issue");

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

        if (ticketId.isEmpty) {
          throw Exception("No ticket ID returned from server");
        }

        print("[TicketFormScreen] Ticket created with ID: $ticketId");

        // ========== SHOW SUCCESS MESSAGE ==========
        String successMessage;
        if (selectedFiles.isNotEmpty && uploadedFileUrls.isNotEmpty) {
          successMessage = "Ticket #$ticketId created successfully!\n"
              "${uploadedFileUrls.length} file(s) uploaded and embedded in description.";
        } else if (selectedFiles.isNotEmpty) {
          successMessage = "Ticket #$ticketId created successfully!\n"
              "Note: Files could not be uploaded but ticket was created.";
        } else {
          successMessage = "Ticket #$ticketId created successfully!";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Clear form
        descriptionController.clear();
        vehicleNumberController.clear();
        setState(() {
          selectedFiles.clear();
        });

        // Navigate after delay
        Future.delayed(const Duration(milliseconds: 2000), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
          );
        });

      } else {
        final errorBody = response.body;
        throw Exception("Failed to create ticket. Status: ${response.statusCode}. Body: $errorBody");
      }
    } catch (e) {
      print("[TicketFormScreen] Error creating ticket: $e");

      String errorMsg = e.toString();
      if (errorMsg.contains("PermissionError") || errorMsg.contains("403")) {
        errorMsg = "Permission denied. Please check user permissions in Frappe.";
      } else if (errorMsg.contains("customer")) {
        errorMsg = "Customer field issue. Please check if user exists in ERP.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $errorMsg"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isUploading = false;
      });
    }
  }

  // ================== HELPER METHODS ==================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ================== UI WIDGETS (UNCHANGED) ==================

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

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attachments (Optional)",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Upload Button
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.add_a_photo),
          label: const Text(
            "Add Photo/File",
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Upload status
        if (isUploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  "Uploading files...",
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ],
            ),
          ),

        // File list
        if (selectedFiles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                "Selected Files (${selectedFiles.length}):",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(selectedFiles.length, (index) {
                final file = selectedFiles[index];
                final fileName = file.path.split('/').last;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Will be embedded in ticket description",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _removeFile(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),

        const SizedBox(height: 8),

        // Info note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Files will be uploaded and embedded as images in the ticket description.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
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
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "GPS Issue Ticket - 'GPS Not Working' is pre-selected",
                        style: const TextStyle(
                          color: Colors.blue,
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
                  color: const Color(0xFFFFF3E0),
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
                      color: const Color(0xFFFFF3E0),
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
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Attachment Section
            _buildAttachmentSection(),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: isLoading ? "Creating Ticket..." : "Submit Ticket",
                onPressed: (isLoading || isUploading) ? null : submitTicket,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            // Info Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPhoneLogin
                          ? "You logged in with phone number. Tickets will be linked to your mobile number."
                          : "Your customer information is fetched from your account. Tickets will be linked to your email.",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1565C0),
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
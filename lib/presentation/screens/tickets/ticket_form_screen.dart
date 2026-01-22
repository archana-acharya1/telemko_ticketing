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

  Future<void> _pickFile() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Gallery',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Camera',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
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

  String _buildDescriptionWithImages(String originalDescription, List<String> fileUrls) {
    if (fileUrls.isEmpty) return originalDescription;

    String description = originalDescription;
    description += "\n\n\n\n<br>\n";

    for (var fileUrl in fileUrls) {
      final fileName = fileUrl.split('/').last;
      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif');

      if (isImage) {
        description += '<br><img src="$fileUrl" style="max-width: 400px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px;"><br>\n';
      }
    }

    return description;
  }

  Future<void> _fetchUserInformation() async {
    setState(() {
      isFetchingUserInfo = true;
      errorMessage = null;
    });

    try {
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

      setState(() {
        customerName = session["customer_name"] ?? "Customer";
        mobileNumber = session["mobile_no"] ?? "";
        customerEmail = session["email_id"] ?? "";

        isPhoneLogin = loginType == "otp" || loginType == "mobile" ||
            (mobileNumber!.isNotEmpty && (customerEmail == null || customerEmail!.isEmpty));

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

  Future<void> submitTicket() async {
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

      final loggedCustomerName = customerName ?? "Customer";
      final loggedCustomerEmail = customerEmail ?? "";
      final loggedMobile = mobileNumber ?? "";

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

      List<String> uploadedFileUrls = [];
      if (selectedFiles.isNotEmpty) {
        setState(() => isUploading = true);
        uploadedFileUrls = await _uploadFilesAndGetUrls();
        setState(() => isUploading = false);
      }

      String finalDescription = description;
      if (uploadedFileUrls.isNotEmpty) {
        finalDescription = _buildDescriptionWithImages(description, uploadedFileUrls);
      }

      final Map<String, dynamic> ticketData = {
        "subject": selectedSubject,
        "description": finalDescription,
        "status": "Open",
      };

      if (loggedCustomerName.isNotEmpty) {
        if (loggedCustomerName == "Customer" || loggedCustomerName.contains("Customer")) {
          if (loggedMobile.isNotEmpty) {
            ticketData["customer"] = "Customer ($loggedMobile)";
          } else {
            ticketData["customer"] = loggedCustomerName;
          }
        } else {
          ticketData["customer"] = loggedCustomerName;
        }
      }

      if (customerEmail != null && customerEmail!.isNotEmpty) {
        ticketData["raised_by"] = customerEmail!;
      } else if (loggedMobile.isNotEmpty) {
        ticketData["raised_by"] = loggedMobile;
      }

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

        descriptionController.clear();
        vehicleNumberController.clear();
        setState(() {
          selectedFiles.clear();
        });

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
          backgroundColor: Theme.of(context).colorScheme.error,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
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

  Widget _buildInfoField(String label, String? value, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
            color: isDarkMode
                ? Theme.of(context).colorScheme.surfaceVariant
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                  : Colors.grey[300]!,
            ),
          ),
          child: Text(
            value ?? "Loading...",
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode
                  ? (value != null ? Colors.white : Colors.grey[400])
                  : (value != null ? Colors.black87 : Colors.grey),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: controller,
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          maxLines: maxLines,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subject *",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
                  : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubject,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
              iconSize: 24,
              elevation: 8,
              isExpanded: true,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              dropdownColor: isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attachments (Optional)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: Icon(
            Icons.add_a_photo,
            color: Colors.white,
          ),
          label: const Text(
            "Add Photo/File",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 8),

        if (isUploading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Uploading files...",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        if (selectedFiles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                "Selected Files (${selectedFiles.length}):",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                    color: isDarkMode
                        ? Colors.green.withOpacity(0.2)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.green.withOpacity(0.5)
                          : const Color(0xFFC8E6C9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: isDarkMode ? Colors.greenAccent : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Will be embedded in ticket description",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.greenAccent.withOpacity(0.8)
                                    : const Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: isDarkMode ? Colors.redAccent : Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _removeFile(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: isDarkMode ? Colors.blueAccent : Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Files will be uploaded and embedded as images in the ticket description.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.blueAccent
                        : const Color(0xFF1565C0),
                  ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Support Ticket"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        color: isDarkMode
            ? Theme.of(context).colorScheme.background
            : Colors.grey[50],
        child: isFetchingUserInfo
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedSubject == "GPS Not Working")
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.blueAccent : Colors.blue,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        color: isDarkMode ? Colors.blueAccent : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "GPS Issue Ticket - 'GPS Not Working' is pre-selected",
                          style: TextStyle(
                            color: isDarkMode ? Colors.blueAccent : Colors.blue,
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
                    color: isDarkMode
                        ? Colors.orange.withOpacity(0.2)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.orangeAccent : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: isDarkMode ? Colors.orangeAccent : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: isDarkMode ? Colors.orangeAccent : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                "Your Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Auto-filled from your account",
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              _buildInfoField("Customer Name", customerName, context),

              if (isPhoneLogin && (customerEmail == null || !customerEmail!.contains("@")))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoField("Email", "Not available (Phone login)", context),
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.orange.withOpacity(0.2)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Note: You logged in with phone number. A system email will be used for ticket creation.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.orangeAccent : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                )
              else
                _buildInfoField("Email", customerEmail, context),

              _buildInfoField("Mobile Number", mobileNumber, context),

              const SizedBox(height: 24),

              Text(
                "Ticket Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildSubjectDropdown(),

              _buildLabeledTextField(
                label: "Vehicle Number(optional)",
                hintText: "Enter vehicle number (if applicable)",
                prefixIcon: Icons.directions_car,
                controller: vehicleNumberController,
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description *",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: descriptionController,
                    labelText: "",
                    hintText: "Describe your issue in detail...",
                    prefixIcon: Icons.description,
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildAttachmentSection(),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: isLoading ? "Creating Ticket..." : "Submit Ticket",
                  onPressed: (isLoading || isUploading) ? null : submitTicket,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: isDarkMode ? Colors.blueAccent : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPhoneLogin
                            ? "You logged in with phone number. Tickets will be linked to your mobile number."
                            : "Your customer information is fetched from your account. Tickets will be linked to your email.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.blueAccent
                              : const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
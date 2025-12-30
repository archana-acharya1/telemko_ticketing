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

    // Add a separator
    description += "\n\n   \n";

    // Add each file as clickable image/link in HTML format
    for (var fileUrl in fileUrls) {
      final fileName = fileUrl.split('/').last;
      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif');

      if (isImage) {
        // For images, embed HTML that Frappe will render
        description += '\n<img src="$fileUrl" alt="$fileName" width="300"><br>';
        description += '<a href="$fileUrl">$fileName</a>\n';
      } else {
        // For non-images, just show the link
        description += '\n<a href="$fileUrl">$fileName</a>\n';
      }
    }

    return description;
  }

  // ================== USER DATA FETCHING ==================

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
          final isPhoneNumber = RegExp(r'^[0-9]+$').hasMatch(username);
          setState(() => isPhoneLogin = isPhoneNumber);

          await _fetchUserDetails(sid, username, session, isPhoneNumber);
        } else {
          customerName = session?["customer_name"] ?? "";
          customerEmail = session?["email"] ?? "";
          mobileNumber = session?["mobile_no"] ?? "";
        }
      } else {
        customerName = session?["customer_name"] ?? "";
        customerEmail = session?["email"] ?? "";
        mobileNumber = session?["mobile_no"] ?? "";
      }
    } catch (e) {
      print("[TicketFormScreen] Error fetching user info: $e");
      errorMessage = "Failed to load user information";

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
      if (isPhoneNumber) {
        await _fetchCustomerByMobile(sid, username, session);
        return;
      }

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

          if (customerEmail != null && customerEmail!.isNotEmpty && customerEmail!.contains("@")) {
            await _fetchCustomerByEmail(sid, customerEmail!, session);
          }
          return;
        }
      }

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
          setState(() {
            customerName = customer["customer_name"]?.toString() ?? "";
            this.mobileNumber = customer["mobile_no"]?.toString() ?? mobileNumber;
            customerEmail = customer["email_id"]?.toString() ?? "";
          });
        } else {
          setState(() {
            customerName = session?["customer_name"] ?? "Customer";
            customerEmail = "$mobileNumber@phoneuser.telemko.com";
          });
        }
      } else {
        setState(() {
          customerName = session?["customer_name"] ?? "Customer";
          customerEmail = "$mobileNumber@phoneuser.telemko.com";
        });
      }
    } catch (e) {
      print("[TicketFormScreen] Error fetching customer by mobile: $e");
      setState(() {
        customerName = session?["customer_name"] ?? "Customer";
        customerEmail = "$mobileNumber@phoneuser.telemko.com";
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

  // ================== TICKET SUBMISSION ==================

  Future<void> submitTicket() async {
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
      final phone = mobileNumber ?? "unknown";
      customerEmail = "$phone@phoneuser.telemko.com";
    }

    setState(() => isLoading = true);

    try {
      final session = await SessionManager.getCustomerSession();
      final sid = session?["sid"] ?? "";

      final loggedCustomerName = customerName ?? session?["customer_name"] ?? "Customer";
      final loggedCustomerEmail = customerEmail ?? session?["email"] ?? "";
      final loggedMobile = mobileNumber ?? session?["mobile_no"] ?? "";

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

      final Map<String, dynamic> ticketData = {
        "subject": selectedSubject,
        "description": finalDescription, // This now contains HTML with embedded images
        "status": "Open",
      };

      if (loggedCustomerName.isNotEmpty && loggedCustomerName != "Customer") {
        ticketData["customer"] = loggedCustomerName;
      } else if (loggedMobile.isNotEmpty) {
        ticketData["customer"] = loggedMobile;
      } else {
        ticketData["customer"] = loggedCustomerEmail;
      }

      if (loggedCustomerName.isNotEmpty) {
        ticketData["customer_name"] = loggedCustomerName;
      }

      if (loggedCustomerEmail.isNotEmpty) {
        ticketData["raised_by"] = loggedCustomerEmail;
      } else if (loggedMobile.isNotEmpty) {
        ticketData["raised_by"] = loggedMobile;
      }

      if (loggedMobile.isNotEmpty) {
        ticketData["mobile_no"] = loggedMobile;
      }

      if (vehicleNumber.isNotEmpty) {
        ticketData["custom_vehical_number"] = vehicleNumber;
      }

      final url = Uri.parse("http://erp.telemko.com/api/resource/Issue");

      print("[TicketFormScreen] Creating ticket with embedded images...");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
        body: jsonEncode(ticketData),
      );

      print("[TicketFormScreen] Create ticket response: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final ticketId = responseData["data"]?["name"] ?? "";

        if (ticketId.isEmpty) {
          throw Exception("No ticket ID returned from server");
        }

        print("[TicketFormScreen] Ticket created with ID: $ticketId");

        // ========== STEP 3: ATTACH FILES TO TICKET (OPTIONAL - ALREADY IN DESCRIPTION) ==========
        // You can still attach files properly to the Issue doctype if needed
        if (uploadedFileUrls.isNotEmpty) {
          // Optional: Link files to the ticket in Frappe's attachment system
          for (var fileUrl in uploadedFileUrls) {
            try {
              final attachUrl = Uri.parse("http://erp.telemko.com/api/method/frappe.desk.form.save.add_attachments");

              final attachResponse = await http.post(
                attachUrl,
                headers: {
                  "Content-Type": "application/json",
                  "Cookie": "sid=$sid",
                },
                body: jsonEncode({
                  "docname": ticketId,
                  "filename": fileUrl.split('/').last,
                  "file_url": fileUrl,
                  "doctype": "Issue",
                }),
              );

              if (attachResponse.statusCode == 200) {
                print("[TicketFormScreen] File attached to ticket: $fileUrl");
              }
            } catch (e) {
              print("[TicketFormScreen] Error attaching file: $e");
              // Continue even if attachment fails - images are already in description
            }
          }
        }

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
        throw Exception("Failed to create ticket. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("[TicketFormScreen] Error creating ticket: $e");

      String errorMsg = e.toString();
      if (errorMsg.contains("PermissionError") || errorMsg.contains("403")) {
        errorMsg = "Permission denied. Please check user permissions in Frappe.";
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

  // ================== UI WIDGETS ==================

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
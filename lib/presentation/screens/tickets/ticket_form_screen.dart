import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/issue_service.dart';
import '../../../services/customer_service.dart';
import '../dashboard/lib/data/local/session_manager.dart';

class TicketFormScreen extends StatefulWidget {
  const TicketFormScreen({super.key});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mobileController = TextEditingController();
  final _customerController = TextEditingController();
  final _vehicleController = TextEditingController();

  File? _selectedImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final email = await SessionManager.getEmail();
      debugPrint("[TicketForm] Session email: $email");

      if (email != null && email.isNotEmpty) {
        final mobile = await CustomerService.fetchMobileByEmail(email);
        final customer = await CustomerService.fetchCustomerByEmail(email);
        debugPrint("[TicketForm] Fetched customer: $customer, mobile: $mobile");

        setState(() {
          _mobileController.text = mobile ?? "";
          _customerController.text = customer ?? "";
        });
      }
    } catch (e) {
      debugPrint("[TicketForm] Error initializing user: $e");
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        debugPrint("[TicketForm] Image selected: ${picked.path}");
        setState(() => _selectedImage = File(picked.path));
      } else {
        debugPrint("[TicketForm] No image selected");
      }
    } catch (e) {
      debugPrint("[TicketForm] Error picking image: $e");
    }
  }

  Future<void> submitTicket() async {
    if (_subjectController.text.isEmpty || _descriptionController.text.isEmpty) {
      debugPrint("[TicketForm] Subject or description is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject and description are required")),
      );
      return;
    }

    setState(() => _loading = true);
    debugPrint("[TicketForm] Submitting ticket...");

    try {
      final email = await SessionManager.getEmail();
      if (email == null) throw Exception("Logged-in email not found");
      debugPrint("[TicketForm] Ticket raised by: $email");

      final issueId = await IssueService.createIssue({
        "subject": _subjectController.text,
        "description": _descriptionController.text,
        "customer_name": _customerController.text,
        "raised_by": email,
        "custom_vehical_number": _vehicleController.text,
        "custom_mobile_number": _mobileController.text,
      });
      debugPrint("[TicketForm] Ticket created with ID: $issueId");

      if (_selectedImage != null) {
        await IssueService.attachImage(issueId: issueId, image: _selectedImage!);
        debugPrint("[TicketForm] Image attached to ticket $issueId");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket created successfully")),
      );
      debugPrint("[TicketForm] Ticket submission completed");
      Navigator.pop(context);
    } catch (e) {
      debugPrint("[TicketForm] Error creating ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _mobileController.dispose();
    _customerController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Create Ticket")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Support Ticket",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Customer (read-only)
                TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                ),
                const SizedBox(height: 16),

                // Mobile (read-only)
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: "Mobile Number"),
                ),
                const SizedBox(height: 16),

                // Vehicle
                TextField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(labelText: "Vehicle Number"),
                ),
                const SizedBox(height: 16),

                // Subject Dropdown
                DropdownButtonFormField<String>(
                  value: _subjectController.text.isNotEmpty ? _subjectController.text : null,
                  decoration: const InputDecoration(
                    labelText: "Issue Subject",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Inactive", child: Text("Inactive")),
                    DropdownMenuItem(value: "Fuel not showing", child: Text("Fuel not showing")),
                    DropdownMenuItem(value: "Video not showing", child: Text("Video not showing")),
                    DropdownMenuItem(value: "GPS not showing", child: Text("GPS not showing")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _subjectController.text = value ?? "";
                      debugPrint("[TicketForm] Subject selected: ${_subjectController.text}");
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 16),

                // Image upload
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Upload Image"),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text("Image selected: ${_selectedImage!.path.split('/').last}"),
                  ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : submitTicket,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Ticket"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

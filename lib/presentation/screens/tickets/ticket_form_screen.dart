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
    final email = await SessionManager.getEmail();
    if (email != null && email.isNotEmpty) {
      final mobile = await CustomerService.fetchMobileByEmail(email);
      final customer = await CustomerService.fetchCustomerByEmail(email);
      setState(() {
        _mobileController.text = mobile ?? "";
        _customerController.text = customer ?? "";
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> submitTicket() async {
    if (_subjectController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject and description are required")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final email = await SessionManager.getEmail();
      if (email == null) throw Exception("Logged-in email not found");

      final issueId = await IssueService.createIssue({
        "subject": _subjectController.text,
        "description": _descriptionController.text,
        "customer_name": _customerController.text,
        "raised_by": email,
        "custom_vehical_number": _vehicleController.text,
        "custom_mobile_number": _mobileController.text,
      });

      if (_selectedImage != null) {
        await IssueService.attachImage(issueId: issueId, image: _selectedImage!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket created successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
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
                Text("Create Support Ticket",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Customer (read-only)
                TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                  // readOnly: true,
                ),
                const SizedBox(height: 16),


                // Mobile (read-only)
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: "Mobile Number"),
                  // readOnly: true,
                ),
                const SizedBox(height: 16),

                // Vehicle
                TextField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(labelText: "Vehicle Number"),
                  // readOnly: true,
                ),
                const SizedBox(height: 16),


                // Subject
                DropdownButtonFormField<String>(
                    value: _subjectController.text.isNotEmpty ? _subjectController.text: null,
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

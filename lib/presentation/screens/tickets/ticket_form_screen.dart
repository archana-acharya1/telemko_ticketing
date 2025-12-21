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
      // Fetch logged-in user's email
      final email = await SessionManager.getEmail();
      if (email == null || email.isEmpty) {
        throw Exception("Logged-in email not found");
      }

      // Call createIssue with named parameters
      final issueId = await IssueService.createIssue(
        subject: _subjectController.text,
        description: _descriptionController.text,
        customer: _customerController.text,
        raisedBy: email, // use the fetched email
        customVehicleNumber: _mobileController.text,
      );

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

                // Mobile (read-only)
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: "Mobile Number"),
                  // readOnly: true,
                ),
                const SizedBox(height: 16),

                // Customer (read-only)
                TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                  // readOnly: true,
                ),
                const SizedBox(height: 16),

                // Subject
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: "Issue Subject"),
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

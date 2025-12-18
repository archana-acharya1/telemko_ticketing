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

  File? _selectedImage;
  bool _loading = false;

  /// Pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  /// Submit ticket
  Future<void> submitTicket() async {
    if (_subjectController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject and description are required")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ⃣ Get logged-in user email
      final userEmail = await SessionManager.getUserEmail();
      if (userEmail == null) throw Exception("User not logged in");

      //  Get customer name linked to user
      final customerName = await CustomerService.fetchCustomerForUser(userEmail);

      //  Create Issue
      final issueId = await IssueService.createIssue({
        "subject": _subjectController.text,
        "description": _descriptionController.text,
        "customer": customerName ?? "",
        "raised_by": userEmail,
      });

      //  Attach image if selected
      if (_selectedImage != null) {
        await IssueService.attachImage(issueId: issueId, image: _selectedImage!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket created successfully")),
      );

      Navigator.pop(context); // Go back to ticket history
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Ticket")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: "Subject"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload Image"),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Image selected"),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : submitTicket,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Submit Ticket"),
            ),
          ],
        ),
      ),
    );
  }
}

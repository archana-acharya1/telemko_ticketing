import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/issue_service.dart';

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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> submitTicket() async {
    setState(() => _loading = true);

    try {
      /// 1️⃣ Create Issue
      final issueId = await IssueService.createIssue({
        "subject": _subjectController.text,
        "description": _descriptionController.text,
      });

      /// 2️⃣ Attach image
      if (_selectedImage != null) {
        await IssueService.attachImage(
          issueId: issueId,
          image: _selectedImage!,
        );
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

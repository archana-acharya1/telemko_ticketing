import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import 'ticket_history_screen.dart';

class TicketFormScreen extends StatefulWidget {
  const TicketFormScreen({super.key});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isLoading = false;

  Future<void> submitTicket() async {
    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final session = await SessionManager.getCustomerSession();
      final customerName = session?["customer_name"] ?? "";
      final sid = session?["sid"] ?? "";

      if (customerName.isEmpty || sid.isEmpty) {
        throw Exception("No session found. Please login again.");
      }

      final url = Uri.parse("http://erp.telemko.com/api/resource/Issue");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid", // ✅ Use SID here
        },
        body: jsonEncode({
          "customer": customerName,
          "subject": subject,
          "description": description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ticket created successfully")));
        subjectController.clear();
        descriptionController.clear();

        // Navigate to Ticket History
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
        );
      } else {
        throw Exception(
            "Failed to create ticket. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Ticket")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppTextField(
              controller: subjectController,
              hintText: "Subject",
              prefixIcon: Icons.subject,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: descriptionController,
              hintText: "Description",
              prefixIcon: Icons.description,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: isLoading ? "Submitting..." : "Submit Ticket",
                onPressed: isLoading ? () {} : submitTicket,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

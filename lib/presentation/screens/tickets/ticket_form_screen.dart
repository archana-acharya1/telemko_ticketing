import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/customer_service.dart';
import '../../../services/issue_service.dart';
import 'ticket_history_screen.dart';

class TicketFormScreen extends StatefulWidget {
  const TicketFormScreen({super.key});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final phoneController = TextEditingController();
  final vehicleController = TextEditingController();
  // final nameController = TextEditingController();
  final remarksController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<File> attachments = [];

  List<String> customerList = [];
  String? selectedCustomer;
  bool loadingCustomers = true;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final customers = await CustomerService.fetchCustomers();
      setState(() {
        customerList = customers;
        loadingCustomers = false;
      });
    } catch (e) {
      setState(() => loadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load customers: $e")),
      );
    }
  }

  Future<void> pickAttachment() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) setState(() => attachments.add(File(file.path)));
  }

  void removeAttachment(int index) {
    setState(() => attachments.removeAt(index));
  }

  Future<void> submitTicket() async {
    if (phoneController.text.isEmpty ||
        vehicleController.text.isEmpty ||
        selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final ticketData = {
        "customer": selectedCustomer,
        "subject": "Support Ticket",
        "custom_mobile_number": phoneController.text,
        "custom_vehical_number": vehicleController.text,
        "custom_issue": remarksController.text,
      };

      final createdTicket = await IssueService.createIssue(ticketData);
      final ticketId = createdTicket["data"]["name"];

      for (var file in attachments) {
        await IssueService.uploadAttachment(ticketId, file);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketHistoryScreen(mobile: phoneController.text)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Support Ticket"), centerTitle: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Create Ticket",
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Mobile Number"),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: vehicleController,
                      decoration: const InputDecoration(labelText: "Vehicle Number"),
                    ),
                    const SizedBox(height: 15),

                    loadingCustomers
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Customer",
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCustomer,
                      items: customerList.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCustomer = value);
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: remarksController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: "Remarks (optional)", alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 20),

                    Text("Attachments (optional)",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: pickAttachment,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text("Add Attachment"),
                    ),
                    const SizedBox(height: 12),

                    if (attachments.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(
                          attachments.length,
                              (index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  attachments[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => removeAttachment(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitTicket,
                        child: const Text("Send"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

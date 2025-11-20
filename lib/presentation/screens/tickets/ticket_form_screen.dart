import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TicketFormScreen extends StatefulWidget {
  const TicketFormScreen({super.key});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final phoneController = TextEditingController();
  final vehicleController = TextEditingController();
  final nameController = TextEditingController();
  final remarksController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<File> attachments = [];

  Future<void> pickAttachment() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: cs.primary),
              title: Text("Choose from Gallery",
                  style: theme.textTheme.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (file != null) {
                  setState(() => attachments.add(File(file.path)));
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.camera_alt, color: cs.primary),
              title: Text("Take Photo", style: theme.textTheme.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (file != null) {
                  setState(() => attachments.add(File(file.path)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void removeAttachment(int index) {
    setState(() {
      attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support Ticket"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 3,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: cs.primary.withOpacity(0.25), // auto light/dark
              width: 2,
            ),
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Ticket",
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Number",
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Customer Name",
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: remarksController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Remarks (optional)",
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Attachments (optional)",
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

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
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
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
                    onPressed: () {
                      print("Phone: ${phoneController.text}");
                      print("Vehicle: ${vehicleController.text}");
                      print("Name: ${nameController.text}");
                      print("Remarks: ${remarksController.text}");
                      print("Attachments: ${attachments.length}");

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ticket Submitted (mock)"),
                        ),
                      );
                    },
                    child: const Text("Send"),
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

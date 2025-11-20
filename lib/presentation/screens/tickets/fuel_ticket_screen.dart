import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FuelTicketScreen extends StatefulWidget {
  const FuelTicketScreen({super.key});

  @override
  State<FuelTicketScreen> createState() => _FuelTicketScreenState();
}

class _FuelTicketScreenState extends State<FuelTicketScreen> {
  final phoneController = TextEditingController();
  final vehicleController = TextEditingController();
  final nameController = TextEditingController();
  final remarksController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<File> attachments = [];

  final List<String> fuelIssues = [
    "Fuel Level Not Updating",
    "Wrong Fuel Reading",
    "Fuel Draining Not Detected",
    "Fuel Spike Detected",
    "Sensor Offline",
    "High Variation in Fuel Levels",
  ];

  String? selectedIssue;

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
              title: const Text("Choose from Gallery"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 70);
                if (file != null) {
                  setState(() => attachments.add(File(file.path)));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: cs.primary),
              title: const Text("Take Photo"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 70);
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
        title: const Text("Fuel Sensor Ticket"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 3,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.primary.withOpacity(0.25), width: 2),
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Report Fuel Sensor Issue",
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // PHONE
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Mobile Number"),
                ),

                const SizedBox(height: 15),

                // VEHICLE
                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(labelText: "Vehicle Number"),
                ),

                const SizedBox(height: 15),

                // NAME
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                ),

                const SizedBox(height: 20),

                // ISSUE TYPE
                Text(
                  "Fuel Sensor Issue Type",
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedIssue,
                  items: fuelIssues
                      .map((issue) =>
                      DropdownMenuItem(value: issue, child: Text(issue)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: "Select Issue",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedIssue = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // REMARKS
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Remarks (optional)",
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                // ATTACHMENTS
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
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                // SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedIssue == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an issue type."),
                          ),
                        );
                        return;
                      }

                      print("Phone: ${phoneController.text}");
                      print("Vehicle: ${vehicleController.text}");
                      print("Name: ${nameController.text}");
                      print("Issue: $selectedIssue");
                      print("Remarks: ${remarksController.text}");
                      print("Attachments: ${attachments.length}");

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Fuel Sensor Ticket Submitted (mock)"),
                        ),
                      );
                    },
                    child: const Text("Submit Fuel Ticket"),
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

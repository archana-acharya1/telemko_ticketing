import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_sizes.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  static const String companyName = "Telemko Autolink Pvt.Ltd";
  static const String bankName = "PRABHU BANK LTD.";
  static const String accountNumber = "0710150286300010";
  static const String qrAssetPath = "assets/images/company_qr.png";

  Future<void> _copy(BuildContext context, String label, String value) async {
    print("[PaymentScreen] Copy requested → $label");

    await Clipboard.setData(ClipboardData(text: value));
    print("[PaymentScreen] Copied successfully → $label");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied to clipboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _saveQrToGallery(BuildContext context) async {
    print("[PaymentScreen] Save QR initiated");

    try {
      final byteData = await rootBundle.load(qrAssetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}/telemko_payment_qr.png");

      await file.writeAsBytes(bytes);
      print("[PaymentScreen] QR saved temporarily at ${file.path}");

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Telemko Payment QR\nCompany: $companyName\nBank: $bankName\nAccount: $accountNumber",
      );
      print("[PaymentScreen] Share sheet opened successfully");

    } catch (e) {
      print("[PaymentScreen] QR save/share failed → $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to share QR: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildCopyCard(BuildContext context,
      {required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? cs.outline.withOpacity(0.2) : Colors.grey[200]!,
        ),
      ),
      color: isDarkMode ? cs.surfaceVariant : Colors.white,
      child: InkWell(
        onTap: () => _copy(context, label, value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy,
                color: cs.primary.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Make Payment",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cs.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: cs.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR Code Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? cs.surfaceVariant : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Clean QR Image without border
                  Image.asset(
                    qrAssetPath,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Scan to Pay",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scan this QR code with your bank app\nto make payment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _saveQrToGallery(context),
                          icon: Icon(
                            Icons.share,
                            color: cs.primary,
                            size: 20,
                          ),
                          label: Text(
                            "Share",
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: cs.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveQrToGallery(context),
                          icon: Icon(
                            Icons.download,
                            color: cs.onPrimary,
                            size: 20,
                          ),
                          label: Text(
                            "Save QR",
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Bank Details Header
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: cs.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Bank Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Tap any detail to copy to clipboard",
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 20),

            // Bank Details Cards
            _buildCopyCard(
              context,
              label: "Company Name",
              value: companyName,
              icon: Icons.business,
            ),

            const SizedBox(height: 12),

            _buildCopyCard(
              context,
              label: "Bank Name",
              value: bankName,
              icon: Icons.account_balance,
            ),

            const SizedBox(height: 12),

            _buildCopyCard(
              context,
              label: "Account Number",
              value: accountNumber,
              icon: Icons.credit_card,
            ),

            const SizedBox(height: 32),

            // Payment Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: cs.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Payment Instructions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(context, "1. Scan QR code with your bank app"),
                  _buildInstructionItem(context, "2. Verify payment details are correct"),
                  _buildInstructionItem(context, "3. Complete transaction"),
                  _buildInstructionItem(context, "4. Save payment receipt"),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_sizes.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  static const String companyName = "Telemko Autolink Pvt.Ltd";
  static const String bankName = "PRABHU BANK LTD.";
  static const String accountNumber = "0710150286300010";
  static const String qrAssetPath = "assets/images/company_qr.png";

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied")),
    );
  }

  Future<void> _saveQrToGallery(BuildContext context) async {
    try {
      // Load QR from assets
      final byteData = await rootBundle.load(qrAssetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();

      // Save temporarily inside app cache
      final tempDir = await getTemporaryDirectory();
      final file = File(
        "${tempDir.path}/telemko_qr.png",
      );

      await file.writeAsBytes(bytes);

      // Open Android share sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Telemko Payment QR",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save QR: $e")),
      );
    }
  }



  Widget _copyTile(BuildContext context,
      {required String label, required String value}) {
    return Card(
      elevation: AppSizes.bankCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.bankCardBorderRadius),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        trailing: const Icon(Icons.copy),
        onTap: () => _copy(context, label, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Make Payment", style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: Column(
          children: [
            Card(
              elevation: AppSizes.qrCardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.qrCardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.qrCardPadding),
                child: Column(
                  children: [
                    Image.asset(qrAssetPath,
                        height: AppSizes.qrImageHeight),
                    const SizedBox(height: AppSizes.spacingSmall),
                    const Text(
                      "Scan this QR to make payment",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _saveQrToGallery(context),
                      icon: const Icon(Icons.download),
                      label: const Text("Save to Gallery"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingLarge),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bank Details",
                style: theme.textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _copyTile(context, label: "Company Name", value: companyName),
            _copyTile(context, label: "Bank Name", value: bankName),
            _copyTile(context, label: "Account Number", value: accountNumber),
          ],
        ),
      ),
    );
  }
}

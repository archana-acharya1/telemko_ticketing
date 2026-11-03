import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerSupportScreen extends StatelessWidget {
  CustomerSupportScreen({super.key});

  final String supportPhone = "+977-9802599213";
  final String whatsappPhone = "+977-9802599213";
  final String facebookPageId = "telemko";

  Future<void> _callNumber(String number) async {
    print("[Customer Support] Call customer tapped: $number");
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      print("[Customer Support] Launching phone dialer");
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("[Customer Support] Cannot launch phone dialer");
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String number) async {
    print("[CustomerSupport] WhatsApp support tapped");
    // removes any non-digit characters like + or -
    final phone = number.replaceAll(RegExp(r'[^0-9]'), '');

    // Pre-typed message (URL-encoded)
    final message = Uri.encodeComponent("Hello, I have an issue and need support");

    final Uri url = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(url)) {
      print("[CustomerSupport] Launching WhatsApp");
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("[CustomerSupport] WhatsApp not available");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Could not open WhatsApp"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openFacebookChat(String pageId) async {
    print("[CustomerSupport] Facebook Messenger tapped");
    final Uri url = Uri.parse("https://m.me/$pageId");
    if (await canLaunchUrl(url)) {
      print("[CustomerSupport] Launching Facebook");
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("[CustomerSupport] Facebook Messenger not available");
    }
  }

  Future<void> openEmail(BuildContext context) async {
    print("[CustomerSupport] Email support tapped");
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@telemko.com',
      queryParameters: {
        'subject': 'Technical Query',
        'body': 'Hello, I need support regarding...',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      print("[CustomerSupport] Launching Email app");
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      print("[Customer Support] Email app not available");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    print("[CustomerSupport] Screen Loaded");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Customer Support",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Text(
                "Contact Us",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Call Support Tile
            _buildSupportTile(
              context: context,
              iconWidget: Icon(
                Icons.call_outlined,
                color: Colors.green,
                size: 24,
              ),
              title: "Call Support ($supportPhone)",
              onTap: () => _callNumber(supportPhone),
            ),

            const SizedBox(height: 15),

            // WhatsApp Tile
            _buildSupportTile(
              context: context,
              iconWidget: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Color(0xFF25D366), // Official WhatsApp green
                size: 24,
              ),
              title: "Chat on WhatsApp",
              onTap: () => _openWhatsApp(context, whatsappPhone),
            ),

            const SizedBox(height: 15),

            // Facebook Messenger Tile
            _buildSupportTile(
              context: context,
              iconWidget: const FaIcon(
                FontAwesomeIcons.facebookMessenger,
                color: Color(0xFF0084FF), // Official Messenger blue
                size: 24,
              ),
              title: "Chat on Facebook Messenger",
              onTap: () => _openFacebookChat(facebookPageId),
            ),

            const SizedBox(height: 15),

            // Email Tile
            _buildSupportTile(
              context: context,
              iconWidget: Icon(
                Icons.mail_outline,
                color: primaryColor,
                size: 24,
              ),
              title: "Email Us",
              onTap: () => openEmail(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile({
    required BuildContext context,
    required Widget iconWidget,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: iconWidget,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
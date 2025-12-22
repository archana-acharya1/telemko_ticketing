import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CustomerSupportScreen extends StatelessWidget {
  CustomerSupportScreen({super.key});

  final String supportPhone = "+977-9802599213";
  final String whatsappPhone = "+977-9802599213";
  final String facebookPageId = "telemko";

  Future<void> _callNumber(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String number) async {
    // removes any non-digit characters like + or -
    final phone = number.replaceAll(RegExp(r'[^0-9]'), '');

    // Pre-typed message (URL-encoded)
    final message = Uri.encodeComponent("Hello, I have an issue and need support");

    final Uri url = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }


  Future<void> _openFacebookChat(String pageId) async {
    final Uri url = Uri.parse("https://m.me/$pageId");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }


  Future<void> openEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@telemko.com',
      queryParameters: {
        'subject': 'Technical Query',
        'body': 'Hello, I need support regarding...',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customer Support", style: AppTextStyles.headline2),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Text(
                "Contact Us",
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildSupportTile(
              context: context,
              icon: Icons.call_outlined,
              iconColor: Colors.green,
              title: "Call Support ($supportPhone)",
              onTap: () => _callNumber(supportPhone),
            ),

            const SizedBox(height: 15),

            _buildSupportTile(
              context: context,
              icon: FontAwesomeIcons.whatsapp,
              iconColor: Colors.green,
              title: "Chat on WhatsApp",
              onTap: () => _openWhatsApp(context, whatsappPhone),
            ),

            const SizedBox(height: 15),

            _buildSupportTile(
              context: context,
              icon: FontAwesomeIcons.facebookMessenger,
              iconColor: Colors.blue,
              title: "Chat on Facebook Messenger",
              onTap: () => _openFacebookChat(facebookPageId),
            ),

            const SizedBox(height: 15),

            _buildSupportTile(
              context: context,
              icon: Icons.mail_outline,
              iconColor: AppColors.primaryBlue,
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
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.lightCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: AppTextStyles.bodyText1),
        onTap: onTap,
      ),
    );
  }
}

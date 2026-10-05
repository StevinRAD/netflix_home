import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'language_notifier.dart';

class ContactHelper {
  static const String whatsappNumber = '6283813755415';
  static const String telegramUsername = 'elloeq';

  static Future<void> launchWhatsApp({String? text}) async {
    final encodedText = text != null ? Uri.encodeComponent(text) : '';
    final waUrl = Uri.parse('https://wa.me/$whatsappNumber?text=$encodedText');
    final waAppUrl = Uri.parse('whatsapp://send?phone=$whatsappNumber&text=$encodedText');
    try {
      if (await canLaunchUrl(waAppUrl)) {
        await launchUrl(waAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> launchTelegram({String? text}) async {
    final encodedText = text != null ? Uri.encodeComponent(text) : '';
    final tgUrl = Uri.parse('https://t.me/$telegramUsername?text=$encodedText');
    try {
      await launchUrl(tgUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      debugPrint('Could not launch Telegram');
    }
  }

  static Future<void> showContactOptions(BuildContext context, {String? defaultText}) async {
    final isIndo = LanguageNotifier.isIndonesian.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIndo ? 'Hubungi Admin' : 'Contact Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIndo ? 'Pilih metode untuk menghubungi admin:' : 'Choose a method to contact admin:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366), size: 32),
                  title: Text(
                    isIndo ? 'Chat via WhatsApp' : 'Chat via WhatsApp',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    launchWhatsApp(text: defaultText);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.telegram, color: Color(0xFF0088cc), size: 32),
                  title: Text(
                    isIndo ? 'Chat via Telegram' : 'Chat via Telegram',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    launchTelegram(text: defaultText);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

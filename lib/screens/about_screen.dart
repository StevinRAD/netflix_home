import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/language_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          LanguageNotifier.isIndonesian.value ? 'Tentang Aplikasi' : 'About App',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // App Icon / Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // App Name & Version
            Text(
              'Netflix Home',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.hasData ? 'v${snapshot.data!.version}' : 'Loading...';
                  return Text(
                    version,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // Creator & Specs Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    title: LanguageNotifier.isIndonesian.value ? 'Dibuat Oleh' : 'Created By',
                    value: 'elloe',
                    isDark: isDark,
                  ),
                  const Divider(height: 30, color: Colors.grey, thickness: 0.2),
                  _buildDetailRow(
                    icon: Icons.verified_user_outlined,
                    title: LanguageNotifier.isIndonesian.value ? 'Lisensi' : 'License',
                    value: 'Private (Netflix Home)',
                    isDark: isDark,
                  ),
                  const Divider(height: 30, color: Colors.grey, thickness: 0.2),
                  _buildDetailRow(
                    icon: Icons.security,
                    title: LanguageNotifier.isIndonesian.value ? 'Sistem Keamanan' : 'Security System',
                    value: LanguageNotifier.isIndonesian.value ? 'Enkripsi Token Khusus' : 'Custom Token Encryption',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Footer Note
            Text(
              LanguageNotifier.isIndonesian.value 
                  ? '© ${DateTime.now().year} Netflix Home by elloe.\nHak cipta dilindungi.'
                  : '© ${DateTime.now().year} Netflix Home by elloe.\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFE50914), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

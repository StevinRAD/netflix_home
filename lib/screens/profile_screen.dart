import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'about_screen.dart';
import 'dashboard_guide_screen.dart';
import '../utils/language_notifier.dart';
import '../services/supabase_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  DateTime? _accessExpiryDate;
  String _appVersion = 'Loading...';
  // ignore: unused_field
  bool _isLoadingExpiry = true;
  Timer? _countdownTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _loadAppVersion();
    _loadExpiryDate();
    _startTimer();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'Netflix Home v${packageInfo.version}';
      });
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Update the countdown every second
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadExpiryDate() async {
    final expiry = await SupabaseService.fetchExpiryDate();
    if (mounted) {
      setState(() {
        _accessExpiryDate = expiry;
        _isLoadingExpiry = false;
      });
      _fadeController.forward();
    }
  }

  bool get _isAccessExpired {
    if (_accessExpiryDate == null) return true;
    return DateTime.now().isAfter(_accessExpiryDate!);
  }

  int get _remainingDays {
    if (_accessExpiryDate == null) return 0;
    final diff = _accessExpiryDate!.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inDays + (diff.inHours % 24 > 0 ? 1 : 0);
  }

  String _getRemainingTimeText() {
    if (_accessExpiryDate == null) {
      return LanguageNotifier.isIndonesian.value
          ? 'Belum Ada Paket'
          : 'No Package';
    }

    final diff = _accessExpiryDate!.difference(DateTime.now());

    if (diff.isNegative) {
      return LanguageNotifier.isIndonesian.value
          ? 'Paket Habis'
          : 'Package Expired';
    }

    if (diff.inHours < 24) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);
      return LanguageNotifier.isIndonesian.value
          ? '$hours Jam $minutes Menit $seconds Detik'
          : '${hours}h ${minutes}m ${seconds}s';
    } else {
      final days = diff.inDays + (diff.inHours % 24 > 0 ? 1 : 0);
      return LanguageNotifier.isIndonesian.value
          ? '$days Hari Lagi'
          : '$days Days Left';
    }
  }

  String _getIndonesianMonth(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  double get _expiryProgress {
    if (_accessExpiryDate == null || _isAccessExpired) return 0.0;
    final diff = _accessExpiryDate!.difference(DateTime.now());
    return (diff.inDays / 30.0).clamp(0.0, 1.0);
  }

  Future<void> _contactAdminWhatsApp({String? customMessage}) async {
    final text = customMessage ??
        'Halo Admin Netflix Home, saya (${widget.username}) butuh bantuan perpanjangan paket / informasi akun.';
    final waUrl = Uri.parse(
        'https://wa.me/6282268426070?text=${Uri.encodeComponent(text)}');
    final waAppUrl = Uri.parse(
        'whatsapp://send?phone=6282268426070&text=${Uri.encodeComponent(text)}');
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

  void _openTutorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const OnboardingScreen(isViewOnly: true)),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGIN GUIDES MODAL
  // ═══════════════════════════════════════════════════════════════
  void _showLoginGuidesModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.devices_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageNotifier.isIndonesian.value
                                ? 'Panduan Login Perangkat'
                                : 'Device Login Guide',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            LanguageNotifier.isIndonesian.value
                                ? 'Pilih perangkat Anda'
                                : 'Choose your device',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDeviceGuideCard(
                      icon: Icons.computer_rounded,
                      emoji: '💻',
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Komputer / Laptop'
                          : 'Computer / Laptop',
                      desc: LanguageNotifier.isIndonesian.value
                          ? 'Tekan "Kirim via WA" pada opsi Laptop/PC untuk mengirim link khusus PC, lalu klik link tersebut di komputer Anda.'
                          : 'Press "Send via WA" on the Laptop/PC option to send a special PC link, then click the link on your computer.',
                      color: Colors.blueAccent,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildDeviceGuideCard(
                      icon: Icons.smartphone_rounded,
                      emoji: '📱',
                      title: LanguageNotifier.isIndonesian.value
                          ? 'HP Android & iPhone'
                          : 'Android & iPhone',
                      desc: LanguageNotifier.isIndonesian.value
                          ? 'Tekan tombol "Buka" opsi HP atau scan "QR Code" dengan kamera HP. Lalu tekan "Buka Aplikasi" untuk otomatis login.'
                          : 'Press "Open" on Mobile option or scan "QR Code" with your camera. Then press "Open App" to auto-login.',
                      color: const Color(0xFF46D369),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildDeviceGuideCard(
                      icon: Icons.tv_rounded,
                      emoji: '📺',
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Smart TV (Link TV9)'
                          : 'Smart TV (TV9 Link)',
                      desc: LanguageNotifier.isIndonesian.value
                          ? 'Buka link TV9 di HP/Laptop. Masukkan kode angka 8 digit yang muncul di layar Smart TV untuk menghubungkan.'
                          : 'Open the TV9 link on Phone/Laptop. Enter the 8-digit code shown on your Smart TV to connect.',
                      color: Colors.amber,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceGuideCard({
    required IconData icon,
    required String emoji,
    required String title,
    required String desc,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $title',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CHANGE PASSWORD MODAL
  // ═══════════════════════════════════════════════════════════════
  void _showChangePasswordModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isUpdating = false;
    bool showCurrentPass = false;
    bool showNewPass = false;
    bool showConfirmPass = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageNotifier.isIndonesian.value
                                    ? 'Ganti Kata Sandi'
                                    : 'Change Password',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                LanguageNotifier.isIndonesian.value
                                    ? 'Perbarui password login Anda'
                                    : 'Update your login password',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPasswordField(
                          controller: currentPassCtrl,
                          label: LanguageNotifier.isIndonesian.value
                              ? 'Password Saat Ini'
                              : 'Current Password',
                          icon: Icons.key_rounded,
                          obscure: !showCurrentPass,
                          onToggle: () =>
                              setStateModal(() => showCurrentPass = !showCurrentPass),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          controller: newPassCtrl,
                          label: LanguageNotifier.isIndonesian.value
                              ? 'Password Baru'
                              : 'New Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: !showNewPass,
                          onToggle: () =>
                              setStateModal(() => showNewPass = !showNewPass),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          controller: confirmPassCtrl,
                          label: LanguageNotifier.isIndonesian.value
                              ? 'Konfirmasi Password Baru'
                              : 'Confirm New Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: !showConfirmPass,
                          onToggle: () => setStateModal(
                              () => showConfirmPass = !showConfirmPass),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    isUpdating ? null : () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.black26),
                                ),
                                child: Text(
                                  LanguageNotifier.isIndonesian.value
                                      ? 'Batal'
                                      : 'Cancel',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isUpdating
                                    ? null
                                    : () async {
                                        if (newPassCtrl.text.isEmpty ||
                                            newPassCtrl.text !=
                                                confirmPassCtrl.text) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  const SizedBox(width: 10),
                                                  Flexible(
                                                    child: Text(LanguageNotifier
                                                            .isIndonesian.value
                                                        ? 'Password baru tidak cocok atau masih kosong!'
                                                        : 'New password does not match or is empty!'),
                                                  ),
                                                ],
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          );
                                          return;
                                        }
                                        if (currentPassCtrl.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  const SizedBox(width: 10),
                                                  Flexible(
                                                    child: Text(LanguageNotifier
                                                            .isIndonesian.value
                                                        ? 'Password saat ini harus diisi!'
                                                        : 'Current password must be filled!'),
                                                  ),
                                                ],
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          );
                                          return;
                                        }

                                        setStateModal(
                                            () => isUpdating = true);

                                        try {
                                          await SupabaseService.changePassword(
                                            currentPassCtrl.text,
                                            newPassCtrl.text,
                                          );

                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Colors.white,
                                                        size: 18),
                                                    const SizedBox(width: 10),
                                                    Text(LanguageNotifier
                                                            .isIndonesian.value
                                                        ? 'Password berhasil diperbarui!'
                                                        : 'Password successfully updated!'),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    const Color(0xFF46D369),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.error_outline,
                                                        color: Colors.white,
                                                        size: 18),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                          '${LanguageNotifier.isIndonesian.value ? 'Gagal' : 'Failed'}: ${e.toString().replaceAll('Exception: ', '')}'),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                            );
                                            setStateModal(
                                                () => isUpdating = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE50914),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: isUpdating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : Text(
                                        LanguageNotifier.isIndonesian.value
                                            ? 'Simpan'
                                            : 'Save',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFFE50914)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE50914), width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  REDEEM VOUCHER MODAL
  // ═══════════════════════════════════════════════════════════════
  void _showRedeemModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeCtrl = TextEditingController();
    bool isRedeeming = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.orange.shade800],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageNotifier.isIndonesian.value
                                    ? 'Redeem Voucher'
                                    : 'Redeem Voucher',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                LanguageNotifier.isIndonesian.value
                                    ? 'Masukkan kode untuk perpanjang paket'
                                    : 'Enter code to extend package',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'XXXX-XXXX',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                              letterSpacing: 2,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.amber.shade700, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isRedeeming
                                    ? null
                                    : () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.black26),
                                ),
                                child: Text(
                                  LanguageNotifier.isIndonesian.value
                                      ? 'Batal'
                                      : 'Cancel',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isRedeeming
                                    ? null
                                    : () async {
                                        if (codeCtrl.text.trim().isEmpty) {
                                          return;
                                        }
                                        setStateModal(
                                            () => isRedeeming = true);

                                        final result =
                                            await SupabaseService.redeemVoucher(
                                                codeCtrl.text.trim());

                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    result['success'] == true
                                                        ? Icons
                                                            .check_circle_rounded
                                                        : Icons.error_outline,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Flexible(
                                                    child: Text(result[
                                                            'message'] ??
                                                        'Terjadi kesalahan.'),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  result['success'] == true
                                                      ? const Color(0xFF46D369)
                                                      : Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          );
                                          if (result['success'] == true) {
                                            _loadExpiryDate();
                                          }
                                        }
                                      },
                                icon: isRedeeming
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.redeem_rounded, size: 16),
                                label: Text(
                                  isRedeeming
                                      ? ''
                                      : (LanguageNotifier.isIndonesian.value
                                          ? 'Tukarkan'
                                          : 'Redeem'),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGOUT CONFIRMATION
  // ═══════════════════════════════════════════════════════════════
  void _confirmLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 36, color: Color(0xFFE50914)),
              ),
              const SizedBox(height: 16),
              Text(
                LanguageNotifier.isIndonesian.value
                    ? 'Konfirmasi Keluar'
                    : 'Confirm Logout',
                style:
                    GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                LanguageNotifier.isIndonesian.value
                    ? 'Apakah Anda yakin ingin keluar dari akun ini?'
                    : 'Are you sure you want to log out of this account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(
                            color: isDark ? Colors.white30 : Colors.black26),
                      ),
                      child: Text(
                        LanguageNotifier.isIndonesian.value
                            ? 'Batal'
                            : 'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        LanguageNotifier.isIndonesian.value
                            ? 'Ya, Keluar'
                            : 'Yes, Logout',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD METHOD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expiryFormatted = _accessExpiryDate != null
        ? '${_accessExpiryDate!.day} ${_getIndonesianMonth(_accessExpiryDate!.month)} ${_accessExpiryDate!.year}'
        : '-';

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Gradient App Bar with Profile Header ──
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFE50914),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFF831010)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Row(
                          children: [
                            Text(
                              LanguageNotifier.tr('profile_settings'),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _contactAdminWhatsApp(),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chat_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Profile Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFE50914)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.username.isNotEmpty
                                        ? widget.username[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.username,
                                            style: GoogleFonts.inter(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified_rounded,
                                            color: Color(0xFF4FC3F7),
                                            size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${widget.username.toLowerCase()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _remainingDays > 0
                                            ? const Color(0xFF46D369)
                                                .withValues(alpha: 0.25)
                                            : Colors.redAccent
                                                .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _remainingDays > 0
                                              ? const Color(0xFF46D369)
                                                  .withValues(alpha: 0.5)
                                              : Colors.redAccent
                                                  .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: _remainingDays > 0
                                                  ? const Color(0xFF46D369)
                                                  : Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _remainingDays > 0
                                                ? (LanguageNotifier
                                                        .isIndonesian.value
                                                    ? 'Member VIP Aktif'
                                                    : 'Active VIP Member')
                                                : (LanguageNotifier
                                                        .isIndonesian.value
                                                    ? 'Member Free'
                                                    : 'Free Member'),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _remainingDays > 0
                                                  ? const Color(0xFF46D369)
                                                  : Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body Content ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 1. Subscription Expiry Card ───
                    _buildSubscriptionExpiryCard(isDark, expiryFormatted),
                    const SizedBox(height: 20),

                    // ─── 2. Help & Guide Section ───
                    _buildSectionHeader(
                      icon: Icons.menu_book_rounded,
                      title: LanguageNotifier.isIndonesian.value
                          ? 'PUSAT BANTUAN & PANDUAN'
                          : 'HELP & GUIDE CENTER',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      icon: Icons.auto_stories_rounded,
                      iconColor: Colors.blueAccent,
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Panduan Login Awal'
                          : 'Initial Login Guide',
                      subtitle: LanguageNotifier.isIndonesian.value
                          ? 'Buka kembali panduan pemakaian interaktif pertama kali'
                          : 'Reopen interactive first-time usage guide',
                      onTap: _openTutorial,
                      isDark: isDark,
                    ),
                    _buildMenuCard(
                      icon: Icons.card_giftcard_rounded,
                      iconColor: Colors.amber.shade700,
                      title: 'Redeem Voucher',
                      subtitle: LanguageNotifier.isIndonesian.value
                          ? 'Masukkan kode voucher untuk perpanjang durasi paket'
                          : 'Enter voucher code to extend package duration',
                      onTap: _showRedeemModal,
                      isDark: isDark,
                      badge: 'NEW',
                    ),
                    _buildMenuCard(
                      icon: Icons.dashboard_customize_rounded,
                      iconColor: const Color(0xFFE50914),
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Panduan Fitur Dashboard'
                          : 'Dashboard Feature Guide',
                      subtitle: LanguageNotifier.isIndonesian.value
                          ? 'Penjelasan lengkap fungsi tiap tombol di Beranda'
                          : 'Full explanation of each button function on Home',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const DashboardGuideScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildMenuCard(
                      icon: Icons.devices_rounded,
                      iconColor: Colors.deepPurpleAccent,
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Cara Login Perangkat'
                          : 'Device Login Guide',
                      subtitle: LanguageNotifier.isIndonesian.value
                          ? 'Petunjuk lengkap login di PC, HP, dan Smart TV'
                          : 'Full guide for login on PC, Phone, and Smart TV',
                      onTap: _showLoginGuidesModal,
                      isDark: isDark,
                    ),
                    _buildMenuCard(
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF25D366),
                      title: 'Customer Service WhatsApp',
                      subtitle: LanguageNotifier.isIndonesian.value
                          ? 'Hubungi admin 24/7 jika ada kendala akun'
                          : 'Contact admin 24/7 for account issues',
                      onTap: () => _contactAdminWhatsApp(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // ─── 3. Settings & Security Section ───
                    _buildSectionHeader(
                      icon: Icons.settings_rounded,
                      title: LanguageNotifier.isIndonesian.value
                          ? 'PENGATURAN & KEAMANAN'
                          : 'SETTINGS & SECURITY',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // Dark Mode Toggle
                    _buildDarkModeToggle(isDark),
                    _buildMenuCard(
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.orangeAccent,
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Ganti Kata Sandi'
                          : 'Change Password',
                      subtitle: LanguageNotifier.isIndonesian.value
                          ? 'Perbarui password login aplikasi Anda'
                          : 'Update your app login password',
                      onTap: _showChangePasswordModal,
                      isDark: isDark,
                    ),
                    _buildMenuCard(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.tealAccent.shade400,
                      title: LanguageNotifier.isIndonesian.value
                          ? 'Tentang Aplikasi'
                          : 'About App',
                      subtitle: _appVersion,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // ─── 4. Logout Button ───
                    _buildLogoutButton(isDark),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUBSCRIPTION EXPIRY CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSubscriptionExpiryCard(bool isDark, String expiryFormatted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAccessExpired
              ? Colors.redAccent.withValues(alpha: 0.25)
              : const Color(0xFF46D369).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isAccessExpired ? Colors.red : const Color(0xFF46D369))
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isAccessExpired
                      ? Icons.timer_off_outlined
                      : Icons.timer_outlined,
                  color: const Color(0xFFE50914),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Masa Aktif Paket'
                          : 'Package Validity',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Berlaku sampai: $expiryFormatted'
                          : 'Valid until: $expiryFormatted',
                      style:
                          GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Status Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isAccessExpired
                      ? Colors.redAccent.withValues(alpha: 0.12)
                      : const Color(0xFF46D369).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getRemainingTimeText(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isAccessExpired
                        ? Colors.redAccent
                        : const Color(0xFF46D369),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _expiryProgress,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              color: _isAccessExpired
                  ? Colors.redAccent
                  : (_remainingDays <= 5
                      ? Colors.orangeAccent
                      : const Color(0xFFE50914)),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactAdminWhatsApp(),
                  icon: const Icon(Icons.chat_rounded, size: 15),
                  label: Text(
                    LanguageNotifier.isIndonesian.value
                        ? 'Beli / Perpanjang'
                        : 'Buy / Extend',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRedeemModal,
                  icon: Icon(Icons.card_giftcard_rounded,
                      size: 15,
                      color: isDark ? Colors.white70 : Colors.black54),
                  label: Text(
                    'Redeem Voucher',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon,
            color: isDark ? Colors.white54 : Colors.black45, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MENU CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE50914),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? Colors.white30 : Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DARK MODE TOGGLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDarkModeToggle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          final isDarkActive = currentMode == ThemeMode.dark;
          return SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            secondary: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: (isDarkActive ? Colors.amber : Colors.orangeAccent)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDarkActive
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: isDarkActive ? Colors.amber : Colors.orangeAccent,
                size: 20,
              ),
            ),
            title: Text(
              LanguageNotifier.isIndonesian.value
                  ? 'Mode Gelap'
                  : 'Dark Theme',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isDarkActive
                  ? (LanguageNotifier.isIndonesian.value
                      ? 'Tema Gelap Aktif'
                      : 'Dark Theme Active')
                  : (LanguageNotifier.isIndonesian.value
                      ? 'Tema Terang Aktif'
                      : 'Light Theme Active'),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            value: isDarkActive,
            activeTrackColor: const Color(0xFFE50914),
            activeThumbColor: Colors.white,
            onChanged: (val) {
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGOUT BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _confirmLogout,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded,
                    color: Color(0xFFE50914), size: 18),
                const SizedBox(width: 8),
                Text(
                  LanguageNotifier.isIndonesian.value
                      ? 'Keluar dari Akun'
                      : 'Logout of Account',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFFE50914),
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

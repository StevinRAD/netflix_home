import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/language_notifier.dart';
import '../utils/user_notifier.dart';
import '../widgets/video_tutorial_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// Model for each login method guide
class _LoginMethod {
  final String id;
  final String titleId;
  final String titleEn;
  final String subtitleId;
  final String subtitleEn;
  final String badgeId;
  final String badgeEn;
  final IconData icon;
  final Color accentColor;
  final String? videoUrl;
  final List<_GuideStep> stepsId;
  final List<_GuideStep> stepsEn;
  final List<_TipItem> tipsId;
  final List<_TipItem> tipsEn;

  const _LoginMethod({
    required this.id,
    required this.titleId,
    required this.titleEn,
    required this.subtitleId,
    required this.subtitleEn,
    required this.badgeId,
    required this.badgeEn,
    required this.icon,
    required this.accentColor,
    this.videoUrl,
    required this.stepsId,
    required this.stepsEn,
    required this.tipsId,
    required this.tipsEn,
  });
}

class _GuideStep {
  final String title;
  final String description;
  final IconData icon;

  const _GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _TipItem {
  final String text;
  final IconData icon;

  const _TipItem({required this.text, required this.icon});
}

class _FAQItem {
  final String questionId;
  final String questionEn;
  final String answerId;
  final String answerEn;

  const _FAQItem({
    required this.questionId,
    required this.questionEn,
    required this.answerId,
    required this.answerEn,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC DATA
// ─────────────────────────────────────────────────────────────────────────────

const List<_LoginMethod> _loginMethods = [
  _LoginMethod(
    id: 'hp',
    titleId: 'Login via HP',
    titleEn: 'Login via Phone',
    subtitleId: 'Android & iOS — Auto Login Instan',
    subtitleEn: 'Android & iOS — Instant Auto Login',
    badgeId: 'PALING MUDAH',
    badgeEn: 'EASIEST',
    icon: Icons.smartphone_rounded,
    accentColor: Color(0xFF4CAF50),
    videoUrl: 'https://youtube.com/shorts/NUKerEzq7pA',
    stepsId: [
      _GuideStep(
        title: 'Pastikan Netflix Terinstal',
        description:
            'Download & instal aplikasi Netflix resmi dari Play Store (Android) atau App Store (iOS) terlebih dahulu.',
        icon: Icons.download_rounded,
      ),
      _GuideStep(
        title: 'Buka Daftar Akun',
        description:
            'Di halaman utama aplikasi ini, tap menu "Daftar Akun" pada navigasi bawah untuk melihat semua akun Netflix yang tersedia.',
        icon: Icons.list_alt_rounded,
      ),
      _GuideStep(
        title: 'Pilih Akun Netflix',
        description:
            'Tekan tombol "Gunakan Akun Ini" pada kartu akun yang ingin digunakan. Akan muncul pop-up pilihan perangkat.',
        icon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        title: 'Pilih Opsi "HP"',
        description:
            'Pada pop-up perangkat, tap opsi "Buka di HP". Sistem akan otomatis menyiapkan link login.',
        icon: Icons.phone_android_rounded,
      ),
      _GuideStep(
        title: 'Netflix Terbuka Otomatis',
        description:
            'Tekan tombol "Buka Netflix Sekarang". Aplikasi Netflix akan terbuka dan Anda langsung masuk tanpa perlu ketik email/password!',
        icon: Icons.launch_rounded,
      ),
    ],
    stepsEn: [
      _GuideStep(
        title: 'Ensure Netflix is Installed',
        description:
            'Download & install the official Netflix app from Play Store (Android) or App Store (iOS) first.',
        icon: Icons.download_rounded,
      ),
      _GuideStep(
        title: 'Open Account List',
        description:
            'On the main page of this app, tap "Account List" on the bottom navigation to see all available Netflix accounts.',
        icon: Icons.list_alt_rounded,
      ),
      _GuideStep(
        title: 'Choose a Netflix Account',
        description:
            'Tap "Use This Account" on the account card you want to use. A device selection popup will appear.',
        icon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        title: 'Select "Phone" Option',
        description:
            'In the device popup, tap "Open on Phone". The system will automatically prepare a login link.',
        icon: Icons.phone_android_rounded,
      ),
      _GuideStep(
        title: 'Netflix Opens Automatically',
        description:
            'Tap "Open Netflix Now". The Netflix app will open and you\'ll be logged in automatically — no email/password needed!',
        icon: Icons.launch_rounded,
      ),
    ],
    tipsId: [
      _TipItem(
        text: 'Pastikan koneksi internet stabil saat proses login otomatis.',
        icon: Icons.wifi_rounded,
      ),
      _TipItem(
        text: 'Jika gagal, coba akun lain. Akun mati otomatis dihapus sistem.',
        icon: Icons.refresh_rounded,
      ),
      _TipItem(
        text: 'Login otomatis bekerja dengan menggunakan cookie session.',
        icon: Icons.cookie_rounded,
      ),
    ],
    tipsEn: [
      _TipItem(
        text: 'Ensure stable internet connection during auto-login.',
        icon: Icons.wifi_rounded,
      ),
      _TipItem(
        text: 'If it fails, try another account. Dead accounts are auto-removed.',
        icon: Icons.refresh_rounded,
      ),
      _TipItem(
        text: 'Auto-login works using cookie sessions.',
        icon: Icons.cookie_rounded,
      ),
    ],
  ),
  _LoginMethod(
    id: 'pc',
    titleId: 'Login via Laptop / PC',
    titleEn: 'Login via Laptop / PC',
    subtitleId: 'Chrome / Edge — Via Link WhatsApp',
    subtitleEn: 'Chrome / Edge — Via WhatsApp Link',
    badgeId: 'POPULER',
    badgeEn: 'POPULAR',
    icon: Icons.laptop_mac_rounded,
    accentColor: Color(0xFF2196F3),
    videoUrl: 'https://youtube.com/shorts/LeNsXxqqrps',
    stepsId: [
      _GuideStep(
        title: 'Pilih Akun dari Daftar',
        description:
            'Buka menu "Daftar Akun" di navigasi bawah, lalu pilih akun Netflix yang ingin digunakan.',
        icon: Icons.list_alt_rounded,
      ),
      _GuideStep(
        title: 'Pilih Opsi "Laptop/PC"',
        description:
            'Pada pop-up perangkat, pilih opsi "Laptop / PC (Kirim via WA)". Link login akan dibuat otomatis.',
        icon: Icons.laptop_rounded,
      ),
      _GuideStep(
        title: 'Kirim Link ke WhatsApp',
        description:
            'Tekan tombol kirim dan link login akan dikirim ke chat WhatsApp Anda sendiri sebagai pesan.',
        icon: Icons.send_rounded,
      ),
      _GuideStep(
        title: 'Buka WhatsApp di Laptop',
        description:
            'Buka WhatsApp Web (web.whatsapp.com) di browser Chrome atau Edge pada laptop/komputer Anda.',
        icon: Icons.computer_rounded,
      ),
      _GuideStep(
        title: 'Klik Link untuk Login',
        description:
            'Klik link yang terkirim di WhatsApp Web. Netflix akan terbuka di tab baru dan sudah dalam kondisi login otomatis.',
        icon: Icons.open_in_new_rounded,
      ),
    ],
    stepsEn: [
      _GuideStep(
        title: 'Choose an Account',
        description:
            'Open the "Account List" menu on the bottom navigation, then select the Netflix account you want to use.',
        icon: Icons.list_alt_rounded,
      ),
      _GuideStep(
        title: 'Select "Laptop/PC" Option',
        description:
            'In the device popup, choose "Laptop / PC (Send via WA)". A login link will be generated automatically.',
        icon: Icons.laptop_rounded,
      ),
      _GuideStep(
        title: 'Send Link to WhatsApp',
        description:
            'Tap the send button and the login link will be sent to your own WhatsApp chat as a message.',
        icon: Icons.send_rounded,
      ),
      _GuideStep(
        title: 'Open WhatsApp on Laptop',
        description:
            'Open WhatsApp Web (web.whatsapp.com) in Chrome or Edge browser on your laptop/computer.',
        icon: Icons.computer_rounded,
      ),
      _GuideStep(
        title: 'Click the Link to Login',
        description:
            'Click the link sent on WhatsApp Web. Netflix will open in a new tab and you\'ll be automatically logged in.',
        icon: Icons.open_in_new_rounded,
      ),
    ],
    tipsId: [
      _TipItem(
        text: 'Gunakan browser Chrome atau Edge untuk hasil terbaik.',
        icon: Icons.web_rounded,
      ),
      _TipItem(
        text: 'Jangan gunakan mode Incognito/Private agar cookie tersimpan.',
        icon: Icons.security_rounded,
      ),
      _TipItem(
        text: 'Link login hanya berlaku 1 kali dan akan expired.',
        icon: Icons.timer_rounded,
      ),
    ],
    tipsEn: [
      _TipItem(
        text: 'Use Chrome or Edge browser for best results.',
        icon: Icons.web_rounded,
      ),
      _TipItem(
        text: 'Don\'t use Incognito/Private mode so cookies are saved.',
        icon: Icons.security_rounded,
      ),
      _TipItem(
        text: 'Login link is one-time use and will expire.',
        icon: Icons.timer_rounded,
      ),
    ],
  ),
  _LoginMethod(
    id: 'tv',
    titleId: 'Login via Smart TV',
    titleEn: 'Login via Smart TV',
    subtitleId: 'Kode 8 Digit — Aktivasi Mudah',
    subtitleEn: '8-Digit Code — Easy Activation',
    badgeId: 'LAYAR BESAR',
    badgeEn: 'BIG SCREEN',
    icon: Icons.tv_rounded,
    accentColor: Color(0xFFFF9800),
    videoUrl: 'https://youtube.com/shorts/xq4TDRb0hR0',
    stepsId: [
      _GuideStep(
        title: 'Buka Netflix di Smart TV',
        description:
            'Nyalakan Smart TV Anda dan buka aplikasi Netflix. Pilih opsi "Masuk dengan Kode" (Sign in with Code).',
        icon: Icons.tv_rounded,
      ),
      _GuideStep(
        title: 'Catat Kode 8 Digit',
        description:
            'Di layar TV akan muncul kode 8 digit unik. Catat atau ingat kode tersebut, kode ini berganti setiap beberapa menit.',
        icon: Icons.pin_rounded,
      ),
      _GuideStep(
        title: 'Pilih Akun & Opsi "Smart TV"',
        description:
            'Di aplikasi ini, buka Daftar Akun, pilih akun Netflix, lalu pada pop-up perangkat pilih opsi "Smart TV".',
        icon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        title: 'Masukkan Kode 8 Digit',
        description:
            'Halaman aktivasi Netflix akan terbuka. Masukkan 8 digit kode dari layar TV Anda, lalu tap "Lanjutkan".',
        icon: Icons.dialpad_rounded,
      ),
      _GuideStep(
        title: 'TV Login Otomatis',
        description:
            'Tunggu beberapa detik, Smart TV Anda akan otomatis masuk ke beranda Netflix. Selamat menonton di layar besar!',
        icon: Icons.celebration_rounded,
      ),
    ],
    stepsEn: [
      _GuideStep(
        title: 'Open Netflix on Smart TV',
        description:
            'Turn on your Smart TV and open the Netflix app. Select "Sign in with Code" option.',
        icon: Icons.tv_rounded,
      ),
      _GuideStep(
        title: 'Note the 8-Digit Code',
        description:
            'A unique 8-digit code will appear on your TV screen. Write it down or remember it — the code refreshes every few minutes.',
        icon: Icons.pin_rounded,
      ),
      _GuideStep(
        title: 'Choose Account & "Smart TV" Option',
        description:
            'In this app, open Account List, select a Netflix account, then choose "Smart TV" in the device popup.',
        icon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        title: 'Enter the 8-Digit Code',
        description:
            'The Netflix activation page will open. Enter the 8-digit code from your TV screen, then tap "Continue".',
        icon: Icons.dialpad_rounded,
      ),
      _GuideStep(
        title: 'TV Logs In Automatically',
        description:
            'Wait a few seconds, and your Smart TV will automatically enter the Netflix homepage. Enjoy watching on the big screen!',
        icon: Icons.celebration_rounded,
      ),
    ],
    tipsId: [
      _TipItem(
        text: 'Pastikan Smart TV terhubung ke internet Wi-Fi yang sama.',
        icon: Icons.wifi_rounded,
      ),
      _TipItem(
        text: 'Kode 8 digit berganti tiap 2-3 menit, jadi masukkan segera.',
        icon: Icons.access_time_rounded,
      ),
      _TipItem(
        text: 'Mendukung Samsung TV, LG TV, Android TV, Apple TV, dll.',
        icon: Icons.devices_rounded,
      ),
    ],
    tipsEn: [
      _TipItem(
        text: 'Make sure your Smart TV is connected to the same Wi-Fi.',
        icon: Icons.wifi_rounded,
      ),
      _TipItem(
        text: 'The 8-digit code refreshes every 2-3 minutes, so enter it quickly.',
        icon: Icons.access_time_rounded,
      ),
      _TipItem(
        text: 'Supports Samsung TV, LG TV, Android TV, Apple TV, etc.',
        icon: Icons.devices_rounded,
      ),
    ],
  ),
];

const List<_FAQItem> _faqItems = [
  _FAQItem(
    questionId: 'Kenapa akun Netflix gagal dibuka?',
    questionEn: 'Why did the Netflix account fail to open?',
    answerId:
        'Beberapa akun mungkin sudah expired atau sedang dalam proses refresh. Tutup pop-up dan coba pilih akun lain dari daftar. Sistem kami otomatis menghapus akun mati dari database.',
    answerEn:
        'Some accounts may have expired or are being refreshed. Close the popup and try another account from the list. Our system automatically removes dead accounts from the database.',
  ),
  _FAQItem(
    questionId: 'Apakah aman login dengan cara ini?',
    questionEn: 'Is it safe to login this way?',
    answerId:
        'Ya, 100% aman. Sistem kami menggunakan NFToken (cookie session) resmi Netflix. Tidak ada data pribadi Anda yang tersimpan di akun Netflix manapun.',
    answerEn:
        'Yes, 100% safe. Our system uses official Netflix NFToken (cookie session). None of your personal data is stored in any Netflix account.',
  ),
  _FAQItem(
    questionId: 'Bolehkah mengganti password atau profil Netflix?',
    questionEn: 'Can I change the Netflix password or profile?',
    answerId:
        'TIDAK BOLEH. Dilarang keras mengubah password, email, profil, atau pengaturan apapun pada akun Netflix. Pelanggaran akan menyebabkan akun Anda di-ban permanen.',
    answerEn:
        'ABSOLUTELY NOT. It is strictly forbidden to change passwords, emails, profiles, or any settings on the Netflix account. Violations will result in permanent account ban.',
  ),
  _FAQItem(
    questionId: 'Login otomatis tidak bekerja di HP, bagaimana?',
    questionEn: 'Auto-login doesn\'t work on my phone, what should I do?',
    answerId:
        'Pastikan: (1) Aplikasi Netflix sudah terinstal & terupdate, (2) Koneksi internet stabil, (3) Coba restart aplikasi Netflix terlebih dahulu, (4) Jika tetap gagal, coba akun lain atau hubungi CS kami.',
    answerEn:
        'Ensure: (1) Netflix app is installed & updated, (2) Stable internet connection, (3) Try restarting the Netflix app first, (4) If it still fails, try another account or contact our CS.',
  ),
  _FAQItem(
    questionId: 'Berapa lama sesi login aktif?',
    questionEn: 'How long does the login session last?',
    answerId:
        'Sesi login tergantung pada masa aktif akun Netflix-nya. Biasanya bertahan beberapa jam hingga beberapa hari. Jika sesi berakhir, cukup ulangi proses login dengan akun baru.',
    answerEn:
        'The login session depends on the Netflix account\'s active period. It usually lasts from several hours to a few days. If the session ends, simply repeat the login process with a new account.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class LoginHelpModal extends StatefulWidget {
  const LoginHelpModal({super.key});

  /// Helper to show this modal as a bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LoginHelpModal(),
    );
  }

  @override
  State<LoginHelpModal> createState() => _LoginHelpModalState();
}

class _LoginHelpModalState extends State<LoginHelpModal>
    with TickerProviderStateMixin {
  int _selectedMethodIndex = 0;
  int _expandedFAQIndex = -1;
  late final TabController _tabController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedMethodIndex = _tabController.index);
      }
    });
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _contactAdminWhatsApp() async {
    final username = UserNotifier.username.value.isNotEmpty
        ? UserNotifier.username.value
        : 'Pengguna';
    final text =
        'Halo CS Netflix Home, saya ($username). Saya butuh panduan lebih lanjut cara login Netflix di perangkat saya. Mohon bantuannya.';
    final waUrl = Uri.parse(
        'whatsapp://send?phone=6282268426070&text=${Uri.encodeComponent(text)}');
    final waWebUrl = Uri.parse(
        'https://wa.me/6282268426070?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIndo = LanguageNotifier.isIndonesian.value;
    final method = _loginMethods[_selectedMethodIndex];
    final bgColor = isDark ? const Color(0xFF111111) : Colors.white;
    final cardColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // ─── HEADER ───
            _buildHeader(isDark, isIndo, textPrimary, textSecondary),

            // ─── CONTENT ───
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Info Banner
                    _buildQuickInfoBanner(isDark, isIndo),
                    const SizedBox(height: 20),

                    // Device Tab Selector
                    _buildDeviceTabSelector(isDark, isIndo, method),
                    const SizedBox(height: 20),

                    // Active Method Card
                    _buildMethodDetailCard(
                        isDark, isIndo, method, cardColor, textPrimary, textSecondary),
                    const SizedBox(height: 16),

                    // Video Tutorial Card (YouTube Shorts)
                    if (method.videoUrl != null) ...[
                      _buildVideoTutorialCard(isDark, isIndo, method),
                      const SizedBox(height: 20),
                    ],

                    // Step-by-Step Guide
                    _buildStepByStepGuide(
                        isDark, isIndo, method, cardColor, textPrimary, textSecondary),
                    const SizedBox(height: 24),

                    // Tips Section
                    _buildTipsSection(
                        isDark, isIndo, method, cardColor, textPrimary, textSecondary),
                    const SizedBox(height: 28),

                    // FAQ Section
                    _buildFAQSection(isDark, isIndo, cardColor, textPrimary, textSecondary),
                    const SizedBox(height: 24),

                    // Important Rules Card
                    _buildRulesCard(isDark, isIndo, textPrimary),
                    const SizedBox(height: 24),

                    // WhatsApp Support Button
                    _buildWhatsAppButton(isDark, isIndo, textPrimary),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeader(
      bool isDark, bool isIndo, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF5F6F8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIndo
                          ? 'Panduan Login Netflix'
                          : 'Netflix Login Guide',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isIndo
                          ? 'Panduan lengkap login di semua perangkat'
                          : 'Complete guide to login on all devices',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey[400], size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── QUICK INFO BANNER ──────────────────────────────────────────────────
  Widget _buildQuickInfoBanner(bool isDark, bool isIndo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A2332),
                  const Color(0xFF162030),
                ]
              : [
                  const Color(0xFFE8F0FE),
                  const Color(0xFFD4E4FC),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_rounded,
                color: Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIndo ? 'Cara Kerja Sistem Kami' : 'How Our System Works',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isIndo
                      ? 'Aplikasi ini menggunakan teknologi NFToken untuk login otomatis ke Netflix tanpa perlu email & password Netflix. Pilih perangkat Anda di bawah.'
                      : 'This app uses NFToken technology for automatic Netflix login without needing Netflix email & password. Choose your device below.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DEVICE TAB SELECTOR ────────────────────────────────────────────────
  Widget _buildDeviceTabSelector(
      bool isDark, bool isIndo, _LoginMethod currentMethod) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isIndo ? 'Pilih Perangkat Anda:' : 'Choose Your Device:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_loginMethods.length, (index) {
            final m = _loginMethods[index];
            final isActive = index == _selectedMethodIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedMethodIndex = index);
                  _tabController.animateTo(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(
                    right: index < _loginMethods.length - 1 ? 8 : 0,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? m.accentColor.withValues(alpha: 0.15)
                        : (isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF0F1F3)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? m.accentColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.withValues(alpha: 0.2)),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: m.accentColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        m.icon,
                        size: 26,
                        color: isActive
                            ? m.accentColor
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.id == 'hp'
                            ? 'HP'
                            : m.id == 'pc'
                                ? 'PC'
                                : 'TV',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive
                              ? m.accentColor
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: m.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── METHOD DETAIL CARD ─────────────────────────────────────────────────
  Widget _buildMethodDetailCard(bool isDark, bool isIndo, _LoginMethod method,
      Color cardColor, Color textPrimary, Color textSecondary) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(method.id),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              method.accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
              method.accentColor.withValues(alpha: isDark ? 0.05 : 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: method.accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: method.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(method.icon, color: method.accentColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isIndo ? method.titleId : method.titleEn,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: method.accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isIndo ? method.badgeId : method.badgeEn,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isIndo ? method.subtitleId : method.subtitleEn,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── VIDEO TUTORIAL CARD ────────────────────────────────────────────────
  Widget _buildVideoTutorialCard(bool isDark, bool isIndo, _LoginMethod method) {
    if (method.videoUrl == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF280B0D), const Color(0xFF190608)]
              : [const Color(0xFFFFF0F0), const Color(0xFFFFE5E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withValues(alpha: isDark ? 0.15 : 0.08),
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
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
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
                            isIndo ? 'Video Tutorial Resmi' : 'Official Video Tutorial',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE50914), width: 0.8),
                          ),
                          child: Text(
                            'SHORTS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFE50914),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isIndo
                          ? 'Tonton panduan singkat vertikal langsung di YouTube'
                          : 'Watch short vertical guide directly on YouTube',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                VideoTutorialModal.show(
                  context,
                  videoUrl: method.videoUrl!,
                  title: isIndo
                      ? 'Tutorial ${method.id == 'hp' ? 'Login HP' : method.id == 'pc' ? 'Login PC' : 'Login TV'}'
                      : '${method.id == 'hp' ? 'Phone' : method.id == 'pc' ? 'PC' : 'TV'} Login Tutorial',
                );
              },
              icon: const Icon(Icons.smart_display_rounded, size: 18, color: Colors.white),
              label: Text(
                isIndo
                    ? 'Putar Video Tutorial ${method.id == 'hp' ? 'HP' : method.id == 'pc' ? 'PC' : 'TV'} (Shorts)'
                    : 'Play ${method.id == 'hp' ? 'Phone' : method.id == 'pc' ? 'PC' : 'TV'} Tutorial (Shorts)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP BY STEP GUIDE ─────────────────────────────────────────────────
  Widget _buildStepByStepGuide(bool isDark, bool isIndo, _LoginMethod method,
      Color cardColor, Color textPrimary, Color textSecondary) {
    final steps = isIndo ? method.stepsId : method.stepsEn;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('steps-${method.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: method.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.format_list_numbered_rounded,
                    color: method.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIndo ? 'Langkah-Langkah' : 'Step-by-Step',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    isIndo
                        ? '${steps.length} langkah mudah'
                        : '${steps.length} easy steps',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Steps List with Timeline
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Column
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        // Number Circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                method.accentColor,
                                method.accentColor.withValues(alpha: 0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    method.accentColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Connecting Line
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.5,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    method.accentColor.withValues(alpha: 0.5),
                                    method.accentColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Step Content
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  method.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(step.icon,
                                color: method.accentColor, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── TIPS SECTION ───────────────────────────────────────────────────────
  Widget _buildTipsSection(bool isDark, bool isIndo, _LoginMethod method,
      Color cardColor, Color textPrimary, Color textSecondary) {
    final tips = isIndo ? method.tipsId : method.tipsEn;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('tips-${method.id}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D12) : const Color(0xFFFFFCE5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFC107).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: Color(0xFFFFC107), size: 18),
                const SizedBox(width: 8),
                Text(
                  isIndo ? 'Tips & Catatan Penting' : 'Tips & Important Notes',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(tip.icon,
                          color: method.accentColor.withValues(alpha: 0.8),
                          size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip.text,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            height: 1.4,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ─── FAQ SECTION ────────────────────────────────────────────────────────
  Widget _buildFAQSection(bool isDark, bool isIndo, Color cardColor,
      Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.quiz_rounded,
                  color: Color(0xFFE50914), size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIndo
                      ? 'Pertanyaan Umum (FAQ)'
                      : 'Frequently Asked Questions',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  isIndo
                      ? '${_faqItems.length} pertanyaan populer'
                      : '${_faqItems.length} popular questions',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // FAQ Items
        ...List.generate(_faqItems.length, (index) {
          final faq = _faqItems[index];
          final isExpanded = _expandedFAQIndex == index;
          final question = isIndo ? faq.questionId : faq.questionEn;
          final answer = isIndo ? faq.answerId : faq.answerEn;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedFAQIndex = isExpanded ? -1 : index;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? (isDark
                            ? const Color(0xFF1F1215)
                            : const Color(0xFFFFF5F5))
                        : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpanded
                          ? const Color(0xFFE50914).withValues(alpha: 0.3)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_rounded,
                            color: isExpanded
                                ? const Color(0xFFE50914)
                                : textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isExpanded
                                    ? const Color(0xFFE50914)
                                    : textPrimary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isExpanded
                                  ? const Color(0xFFE50914)
                                  : textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 26),
                          child: Text(
                            answer,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              height: 1.5,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── RULES CARD ─────────────────────────────────────────────────────────
  Widget _buildRulesCard(bool isDark, bool isIndo, Color textPrimary) {
    final rules = isIndo
        ? [
            'Dilarang mengganti password, email, atau profil Netflix.',
            'Dilarang menambah/menghapus profil di akun Netflix.',
            'Dilarang mengunduh film ke perangkat dari akun Netflix.',
            'Jika sesi login berakhir, ulangi proses dengan akun baru.',
            'Pelanggaran aturan = akun Netflix Home Anda di-ban permanen.',
          ]
        : [
            'Do NOT change password, email, or Netflix profile.',
            'Do NOT add/delete profiles on the Netflix account.',
            'Do NOT download movies to your device from the Netflix account.',
            'If login session ends, repeat the process with a new account.',
            'Rule violation = permanent ban from Netflix Home.',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1215), const Color(0xFF1C0F10)]
              : [const Color(0xFFFFF0F0), const Color(0xFFFFE8E8)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: Color(0xFFE50914), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isIndo ? 'Peraturan Penting' : 'Important Rules',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE50914),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rules.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: entry.key == rules.length - 1
                            ? const Color(0xFFE50914)
                            : const Color(0xFFE50914).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        entry.key == rules.length - 1
                            ? Icons.warning_rounded
                            : Icons.close_rounded,
                        color: entry.key == rules.length - 1
                            ? Colors.white
                            : const Color(0xFFE50914),
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: entry.key == rules.length - 1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: entry.key == rules.length - 1
                              ? const Color(0xFFE50914)
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── WHATSAPP BUTTON ────────────────────────────────────────────────────
  Widget _buildWhatsAppButton(bool isDark, bool isIndo, Color textPrimary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _contactAdminWhatsApp,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIndo
                          ? 'Masih Butuh Bantuan?'
                          : 'Still Need Help?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isIndo
                          ? 'Chat langsung CS via WhatsApp'
                          : 'Chat CS directly on WhatsApp',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

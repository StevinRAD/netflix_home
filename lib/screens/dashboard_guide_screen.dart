import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/language_notifier.dart';

class DashboardGuideScreen extends StatefulWidget {
  const DashboardGuideScreen({super.key});

  @override
  State<DashboardGuideScreen> createState() => _DashboardGuideScreenState();
}

class _DashboardGuideScreenState extends State<DashboardGuideScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

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

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _fadeController.reset();
    _slideController.reset();

    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  List<_GuideStep> _getSteps(bool isDark) {
    return [
      // ── Step 1: Welcome & Overview ──
      _GuideStep(
        stepNumber: 1,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Selamat Datang di Netflix Home!'
            : 'Welcome to Netflix Home!',
        description: LanguageNotifier.isIndonesian.value
            ? 'Aplikasi Netflix Home adalah platform resmi untuk mengakses akun Netflix secara instan.\n\n'
                '📱 Fitur Utama:\n'
                '• Dashboard dengan info langganan real-time\n'
                '• Daftar akun Netflix siap pakai\n'
                '• Auto-login ke HP, PC, dan Smart TV\n'
                '• Customer Service 24/7 via WhatsApp\n\n'
                '🎯 Panduan ini akan membantu Anda memahami setiap fitur yang ada di halaman Dashboard (Beranda).\n\n'
                '⏱️ Estimasi waktu baca: ±2 menit'
            : 'Netflix Home is your official platform to access Netflix accounts instantly.\n\n'
                '📱 Key Features:\n'
                '• Dashboard with real-time subscription info\n'
                '• Ready-to-use Netflix account list\n'
                '• Auto-login on Phone, PC, and Smart TV\n'
                '• 24/7 Customer Service via WhatsApp\n\n'
                '🎯 This guide will help you understand each feature on the Dashboard (Home) page.\n\n'
                '⏱️ Estimated reading time: ±2 minutes',
        accentColor: const Color(0xFFE50914),
        icon: Icons.home_rounded,
        mockupWidget: _buildWelcomeMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👋 Geser untuk melihat panduan selanjutnya'
            : '👋 Swipe to see the next guide',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Anda bisa mengakses panduan ini kapan saja dari menu Profil.',
                'Geser kiri/kanan atau tekan tombol navigasi di bawah.',
              ]
            : [
                'You can access this guide anytime from the Profile menu.',
                'Swipe left/right or use the navigation buttons below.',
              ],
      ),

      // ── Step 2: Header & Welcome Card ──
      _GuideStep(
        stepNumber: 2,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Header & Kartu Selamat Datang'
            : 'Header & Welcome Card',
        description: LanguageNotifier.isIndonesian.value
            ? 'Di bagian paling atas Dashboard terdapat header dengan gradient merah Netflix yang berisi:\n\n'
                '🏠 Logo & Judul — Identitas \"NETFLIX HOME\" beserta label \"Dashboard Pelanggan\".\n\n'
                '👤 Kartu Selamat Datang — Menampilkan foto profil, nama Anda, sapaan waktu (Pagi/Siang/Sore/Malam), dan badge status langganan (Aktif/Tidak Aktif).\n\n'
                '📊 Mini Statistik — Angka ringkas Total akun dan akun Live di pojok kanan.\n\n'
                '🔧 Tombol Aksi — Dua ikon di pojok kanan atas:\n'
                '   • 🎧 Customer Service — Buka Pusat Bantuan\n'
                '   • 🔄 Sync — Perbarui data akun dari server'
            : 'At the very top of the Dashboard is a Netflix red gradient header containing:\n\n'
                '🏠 Logo & Title — "NETFLIX HOME" identity with "Customer Dashboard" label.\n\n'
                '👤 Welcome Card — Shows your profile photo, name, time greeting (Morning/Afternoon/Evening/Night), and subscription status badge (Active/Inactive).\n\n'
                '📊 Mini Stats — Quick Total accounts and Live accounts numbers on the right.\n\n'
                '🔧 Action Buttons — Two icons on the top right:\n'
                '   • 🎧 Customer Service — Open Help Center\n'
                '   • 🔄 Sync — Update account data from server',
        accentColor: const Color(0xFFE50914),
        icon: Icons.account_circle_rounded,
        mockupWidget: _buildHeaderMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Header ini selalu tampil di bagian atas'
            : '👆 This header always appears at the top',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Foto profil diambil dari Gravatar berdasarkan email Anda.',
                'Anda bisa mengubah nama tampilan di menu Profil.',
                'Badge hijau = paket aktif, orange = paket tidak aktif.',
              ]
            : [
                'Profile photo is fetched from Gravatar based on your email.',
                'You can change your display name in the Profile menu.',
                'Green badge = active package, orange = inactive package.',
              ],
      ),

      // ── Step 3: Subscription Status Card ──
      _GuideStep(
        stepNumber: 3,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Kartu Status Langganan'
            : 'Subscription Status Card',
        description: LanguageNotifier.isIndonesian.value
            ? 'Kartu ini adalah pusat informasi masa aktif paket Anda:\n\n'
                '🛡️ Status — Badge di kanan atas menunjukkan apakah paket Anda \"Aktif\" (hijau) atau \"Tidak Aktif\" (merah).\n\n'
                '📅 Tanggal Berlaku — Menampilkan batas akhir paket Anda (contoh: \"Berlaku s/d: 30 September 2026\").\n\n'
                '⏳ Countdown Timer — Menghitung mundur sisa waktu:\n'
                '   • Jika >24 jam: Tampil dalam format \"Masa Aktif: X Hari\"\n'
                '   • Jika <24 jam: Tampil dalam format \"X Jam Y Menit Z Detik\" (real-time)\n\n'
                '📊 Progress Bar — Visualisasi persentase sisa waktu paket.\n\n'
                '💬 Tombol WhatsApp — Tekan untuk menghubungi admin dan perpanjang/beli paket baru.'
            : 'This card is your package active period information center:\n\n'
                '🛡️ Status — Badge on the top right shows whether your package is "Active" (green) or "Inactive" (red).\n\n'
                '📅 Valid Date — Displays your package end date (e.g., "Valid until: September 30, 2026").\n\n'
                '⏳ Countdown Timer — Counts down remaining time:\n'
                '   • If >24h: Shows as "Active: X Days"\n'
                '   • If <24h: Shows as "Xh Ym Zs" (real-time)\n\n'
                '📊 Progress Bar — Visual percentage of remaining package time.\n\n'
                '💬 WhatsApp Button — Press to contact admin and extend/buy a new package.',
        accentColor: const Color(0xFF46D369),
        icon: Icons.timer_outlined,
        mockupWidget: _buildSubscriptionMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Kartu ini ada di paling atas Dashboard'
            : '👆 This card is at the top of the Dashboard',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Jika countdown menunjukkan kurang dari 5 hari, warna akan berubah orange sebagai peringatan.',
                'Tekan tombol hijau \"Perpanjang via WhatsApp\" untuk langsung chat admin.',
                'Setelah paket habis, Anda tidak bisa mengakses daftar akun Netflix.',
              ]
            : [
                'If countdown shows less than 5 days, color changes to orange as a warning.',
                'Press the green "Extend via WhatsApp" button to directly chat admin.',
                'After package expires, you cannot access the Netflix account list.',
              ],
      ),

      // ── Step 4: Server Status ──
      _GuideStep(
        stepNumber: 4,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Status Server Streaming'
            : 'Streaming Server Status',
        description: LanguageNotifier.isIndonesian.value
            ? 'Indikator hijau berkedip menunjukkan bahwa server streaming Netflix Home sedang online dan siap digunakan.\n\n'
                '✅ Hijau Berkedip — Server aktif, stabil, dan siap untuk auto-login akun Netflix.\n\n'
                '⚠️ Kuning/Merah — Jika terjadi gangguan server (maintenance), indikator akan berubah warna. Tunggu beberapa saat dan coba lagi.\n\n'
                'ℹ️ Server kami beroperasi 24/7 dengan uptime 99.9%. Gangguan sangat jarang terjadi dan biasanya selesai dalam hitungan menit.'
            : 'The blinking green indicator shows that the Netflix Home streaming server is online and ready to use.\n\n'
                '✅ Green Blinking — Server is active, stable, and ready for Netflix account auto-login.\n\n'
                '⚠️ Yellow/Red — If there is a server issue (maintenance), the indicator will change color. Wait a moment and try again.\n\n'
                'ℹ️ Our servers operate 24/7 with 99.9% uptime. Issues are very rare and usually resolve within minutes.',
        accentColor: const Color(0xFF46D369),
        icon: Icons.cloud_done_outlined,
        mockupWidget: _buildServerStatusMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Indikator ini ada di bawah banner langganan'
            : '👆 This indicator is below the subscription banner',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Jika server sedang maintenance, semua fitur auto-login akan ditunda sementara.',
                'Status server di-update secara real-time tanpa perlu refresh manual.',
              ]
            : [
                'If the server is under maintenance, all auto-login features will be temporarily delayed.',
                'Server status is updated in real-time without manual refresh.',
              ],
      ),

      // ── Step 5: Account Statistics ──
      _GuideStep(
        stepNumber: 5,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Statistik Total Akun'
            : 'Total Account Statistics',
        description: LanguageNotifier.isIndonesian.value
            ? 'Dua kartu statistik utama menampilkan informasi penting:\n\n'
                '📊 Total Ketersediaan Akun\n'
                'Menunjukkan jumlah seluruh akun Netflix yang terdaftar dalam sistem database kami. Termasuk akun aktif maupun yang sedang dalam proses validasi.\n\n'
                '✅ Akun Live (Aktif)\n'
                'Jumlah akun yang statusnya telah terverifikasi aktif dan bisa langsung digunakan untuk menonton Netflix. Ini adalah angka real dari akun yang siap pakai.\n\n'
                '🔄 Pembaruan Data\n'
                'Angka ini diperbarui secara otomatis setiap kali Anda:\n'
                '   • Membuka aplikasi / halaman Dashboard\n'
                '   • Menarik layar ke bawah (Pull-to-Refresh)\n'
                '   • Menekan tombol 🔄 Sync di header'
            : 'Two main statistics cards display important information:\n\n'
                '📊 Total Account Availability\n'
                'Shows the total number of Netflix accounts registered in our database system. Includes both active accounts and those being validated.\n\n'
                '✅ Live Accounts (Active)\n'
                'Number of accounts that have been verified active and can be directly used for Netflix streaming. This is the real number of ready-to-use accounts.\n\n'
                '🔄 Data Updates\n'
                'These numbers update automatically when you:\n'
                '   • Open the app / Dashboard page\n'
                '   • Pull down to refresh (Pull-to-Refresh)\n'
                '   • Press the 🔄 Sync button in the header',
        accentColor: Colors.blueAccent,
        icon: Icons.bar_chart_rounded,
        mockupWidget: _buildStatsMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Dua kartu ini ada di bagian \"Statistik Akun\"'
            : '👆 These two cards are in the "Account Statistics" section',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Angka \"Live\" selalu lebih kecil atau sama dengan \"Total\" karena sudah difilter validasi.',
                'Akun yang mati otomatis dihapus oleh sistem auto-clean kami.',
                'Semakin tinggi angka Live, semakin banyak pilihan akun untuk Anda.',
              ]
            : [
                '"Live" number is always less than or equal to "Total" as it is filtered by validation.',
                'Dead accounts are automatically removed by our auto-clean system.',
                'Higher Live numbers mean more account choices for you.',
              ],
      ),

      // ── Step 6: Package Availability Grid ──
      _GuideStep(
        stepNumber: 6,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Ketersediaan Paket Netflix'
            : 'Netflix Package Availability',
        description: LanguageNotifier.isIndonesian.value
            ? 'Grid 4 kartu paket menampilkan rincian akun per tipe langganan Netflix:\n\n'
                '🔵 Basic — Kualitas 720p HD\n'
                '   Resolusi standar, cocok untuk menonton di HP kecil.\n'
                '   Streaming: 1 perangkat bersamaan.\n\n'
                '🟢 Standard — Kualitas 1080p Full HD\n'
                '   Resolusi jernih dan tajam, ideal untuk laptop dan tablet.\n'
                '   Streaming: 2 perangkat bersamaan.\n\n'
                '🔴 Premium — Kualitas 4K Ultra HD + HDR\n'
                '   Resolusi terbaik, sempurna untuk Smart TV layar besar.\n'
                '   Streaming: 4 perangkat bersamaan.\n\n'
                '🟡 Mobile — Kualitas 480p SD\n'
                '   Hemat kuota data, khusus untuk HP saja.\n'
                '   Streaming: 1 perangkat (HP only).\n\n'
                '📌 Angka di pojok kanan atas setiap kartu menunjukkan jumlah akun yang tersedia untuk tipe tersebut.'
            : 'A grid of 4 package cards shows account breakdown by Netflix subscription type:\n\n'
                '🔵 Basic — 720p HD Quality\n'
                '   Standard resolution, suitable for small phone screens.\n'
                '   Streaming: 1 device simultaneously.\n\n'
                '🟢 Standard — 1080p Full HD Quality\n'
                '   Clear and sharp, ideal for laptops and tablets.\n'
                '   Streaming: 2 devices simultaneously.\n\n'
                '🔴 Premium — 4K Ultra HD + HDR Quality\n'
                '   Best resolution, perfect for big screen Smart TVs.\n'
                '   Streaming: 4 devices simultaneously.\n\n'
                '🟡 Mobile — 480p SD Quality\n'
                '   Data-saving, for mobile phones only.\n'
                '   Streaming: 1 device (phone only).\n\n'
                '📌 The number at the top-right of each card shows available accounts for that type.',
        accentColor: Colors.amber,
        icon: Icons.inventory_2_outlined,
        mockupWidget: _buildPackageGridMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Grid ini ada di bagian \"Ketersediaan Paket\"'
            : '👆 This grid is in the "Package Availability" section',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Akun Premium (4K) menghasilkan kualitas terbaik di Smart TV.',
                'Akun Mobile hanya bisa digunakan di HP, tidak bisa di TV/PC.',
                'Anda bebas memilih paket apapun sesuai perangkat Anda.',
              ]
            : [
                'Premium (4K) accounts provide the best quality on Smart TVs.',
                'Mobile accounts only work on phones, not on TV/PC.',
                'You can choose any package type for your device.',
              ],
      ),

      // ── Step 7: Rules & Start Watching ──
      _GuideStep(
        stepNumber: 7,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Panduan Menonton & Mulai Nonton'
            : 'Watching Guide & Start Watching',
        description: LanguageNotifier.isIndonesian.value
            ? '📋 Panduan Menonton (Aturan Penting)\n'
                'Kartu emas ini berisi 4 aturan wajib dipatuhi:\n\n'
                '1️⃣ Profil Baru — Boleh tambah profil jika ada slot kosong, TAPI dilarang keras menghapus profil yang sudah ada.\n\n'
                '2️⃣ Bahasa — Bebas ubah bahasa tampilan ke Bahasa Indonesia jika akun menggunakan bahasa asing.\n\n'
                '3️⃣ Limit Layar — Jika terkena limit nonton, JANGAN panik! Keluar Netflix lalu ambil akun baru di Netflix Home.\n\n'
                '4️⃣ Keamanan — Dilarang keras mengubah email atau password akun Netflix.\n\n'
                '───────────────────\n\n'
                '🎬 Tombol \"Mulai Nonton\"\n'
                'Tombol merah besar di bagian paling bawah Dashboard adalah SHORTCUT utama Anda untuk langsung pindah ke halaman \"Daftar Akun Netflix\".\n\n'
                '⚠️ Tombol ini hanya aktif jika paket Anda masih berlaku. Jika expired, tombol berwarna abu-abu.'
            : '📋 Watching Guide (Important Rules)\n'
                'This golden card contains 4 mandatory rules:\n\n'
                '1️⃣ New Profile — May add profile if empty slot exists, BUT strictly prohibited to delete existing profiles.\n\n'
                '2️⃣ Language — Free to change display language to your preferred language if the account uses a foreign language.\n\n'
                '3️⃣ Screen Limit — If screen limit reached, DON\'T panic! Log out Netflix and get a new account in Netflix Home.\n\n'
                '4️⃣ Security — Strictly prohibited to change email or password of the Netflix account.\n\n'
                '───────────────────\n\n'
                '🎬 "Start Watching" Button\n'
                'The large red button at the bottom of the Dashboard is your MAIN SHORTCUT to jump directly to the "Netflix Account List" page.\n\n'
                '⚠️ This button is only active if your package is valid. If expired, it will be grayed out.',
        accentColor: const Color(0xFFE50914),
        icon: Icons.play_circle_fill_rounded,
        mockupWidget: _buildRulesAndButtonMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Aturan wajib & tombol utama di bagian bawah'
            : '👆 Required rules & main button at the bottom',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Pelanggaran aturan (hapus profil / ubah password) dapat mengakibatkan pemblokiran akun Anda.',
                'Stok akun kami sangat banyak, jangan ragu untuk ganti akun jika limit layar.',
                'Tombol \"Mulai Nonton\" adalah cara tercepat menuju halaman akun.',
              ]
            : [
                'Violating rules (deleting profiles / changing passwords) may result in account suspension.',
                'We have plenty of account stock, don\'t hesitate to switch accounts if screen limit.',
                '"Start Watching" button is the fastest way to the account page.',
              ],
      ),

      // ── Step 8: Tips & Tricks + Pull-to-Refresh ──
      _GuideStep(
        stepNumber: 8,
        totalSteps: 8,
        title: LanguageNotifier.isIndonesian.value
            ? 'Tips, Trik & Fitur Tersembunyi'
            : 'Tips, Tricks & Hidden Features',
        description: LanguageNotifier.isIndonesian.value
            ? '🔄 Pull-to-Refresh (Tarik ke Bawah)\n'
                'Tarik layar Dashboard dari atas ke bawah untuk memperbarui semua data sekaligus — termasuk statistik akun, status langganan, dan daftar akun terbaru.\n\n'
                '🎧 Pusat Bantuan & CS\n'
                'Tekan ikon 🎧 di header untuk membuka Pusat Bantuan lengkap berisi FAQ dan panduan. Di sana juga ada tombol WhatsApp langsung ke Customer Service.\n\n'
                '👤 Menu Profil\n'
                'Di tab \"Profil\" (navigasi bawah), Anda bisa:\n'
                '   • Mengubah nama tampilan\n'
                '   • Mengubah foto profil\n'
                '   • Mengganti password akun Netflix Home\n'
                '   • Mengatur tema gelap/terang\n'
                '   • Mengubah bahasa (ID/EN)\n'
                '   • Menukarkan kode voucher\n'
                '   • Membuka kembali panduan ini\n\n'
                '🌙 Mode Gelap\n'
                'Aktifkan mode gelap di Profil → Pengaturan untuk pengalaman menonton malam yang nyaman.\n\n'
                '🌍 Bahasa\n'
                'Semua teks di aplikasi ini tersedia dalam Bahasa Indonesia dan English. Ganti kapan saja di Profil → Bahasa.'
            : '🔄 Pull-to-Refresh\n'
                'Pull the Dashboard screen from top to bottom to refresh all data simultaneously — including account statistics, subscription status, and latest account list.\n\n'
                '🎧 Help Center & CS\n'
                'Tap the 🎧 icon in the header to open the complete Help Center with FAQs and guides. There is also a direct WhatsApp button to Customer Service.\n\n'
                '👤 Profile Menu\n'
                'In the "Profile" tab (bottom navigation), you can:\n'
                '   • Change display name\n'
                '   • Change profile photo\n'
                '   • Change Netflix Home account password\n'
                '   • Toggle dark/light theme\n'
                '   • Change language (ID/EN)\n'
                '   • Redeem voucher codes\n'
                '   • Reopen this guide\n\n'
                '🌙 Dark Mode\n'
                'Enable dark mode in Profile → Settings for comfortable night viewing.\n\n'
                '🌍 Language\n'
                'All text in this app is available in Indonesian and English. Switch anytime in Profile → Language.',
        accentColor: Colors.deepPurpleAccent,
        icon: Icons.auto_awesome_rounded,
        mockupWidget: _buildTipsTricksMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '🎉 Anda siap menggunakan Netflix Home!'
            : '🎉 You\'re ready to use Netflix Home!',
        tips: LanguageNotifier.isIndonesian.value
            ? [
                'Pull-to-Refresh juga berfungsi di halaman Daftar Akun.',
                'Voucher perpanjangan bisa didapatkan dari Admin via WhatsApp.',
                'Panduan ini bisa diakses ulang dari Profil → Panduan Dashboard.',
              ]
            : [
                'Pull-to-Refresh also works on the Account List page.',
                'Extension vouchers can be obtained from Admin via WhatsApp.',
                'This guide can be re-accessed from Profile → Dashboard Guide.',
              ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _getSteps(isDark);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageNotifier.isIndonesian.value
                              ? 'Panduan Fitur Dashboard'
                              : 'Dashboard Features Guide',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          LanguageNotifier.isIndonesian.value
                              ? 'Panduan lengkap setiap fitur'
                              : 'Complete guide for every feature',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Step indicator chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: steps[_currentPage]
                          .accentColor
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: steps[_currentPage]
                            .accentColor
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${steps.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: steps[_currentPage].accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Step Dots ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(steps.length, (index) {
                  final isActive = index == _currentPage;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _animateToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: EdgeInsets.only(
                            right: index < steps.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? steps[_currentPage].accentColor
                              : (index < _currentPage
                                  ? steps[_currentPage]
                                      .accentColor
                                      .withValues(alpha: 0.4)
                                  : (isDark
                                      ? Colors.white12
                                      : Colors.black12)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // ── Page View ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  _fadeController.reset();
                  _slideController.reset();
                  _fadeController.forward();
                  _slideController.forward();
                },
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        step.accentColor,
                                        step.accentColor
                                            .withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: step.accentColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(step.icon,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LanguageNotifier.isIndonesian.value
                                            ? 'LANGKAH ${step.stepNumber} dari ${step.totalSteps}'
                                            : 'STEP ${step.stepNumber} of ${step.totalSteps}',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: step.accentColor,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        step.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Mockup Preview Container
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: step.accentColor
                                      .withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: step.accentColor
                                        .withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Preview label
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: step.accentColor
                                          .withValues(alpha: 0.08),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.preview_rounded,
                                            size: 14,
                                            color: step.accentColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          LanguageNotifier.isIndonesian.value
                                              ? 'PREVIEW TAMPILAN'
                                              : 'PREVIEW',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: step.accentColor,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: step.accentColor
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            LanguageNotifier.isIndonesian.value
                                                ? 'Contoh'
                                                : 'Sample',
                                            style: GoogleFonts.inter(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: step.accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Mockup content
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: step.mockupWidget,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Pointer label
                            Center(
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: step.accentColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        step.pointerLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: step.accentColor,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Description card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded,
                                          size: 16,
                                          color: step.accentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        LanguageNotifier.isIndonesian.value
                                            ? 'Penjelasan Lengkap'
                                            : 'Full Explanation',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: step.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    step.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tips card (if tips available)
                            if (step.tips.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.amber.withValues(alpha: 0.08)
                                      : Colors.amber.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Colors.amber.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.lightbulb_outline_rounded,
                                            size: 16,
                                            color: Colors.amber),
                                        const SizedBox(width: 6),
                                        Text(
                                          LanguageNotifier.isIndonesian.value
                                              ? 'Tips & Info'
                                              : 'Tips & Info',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...step.tips.map((tip) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('💡 ',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11)),
                                              Expanded(
                                                child: Text(
                                                  tip,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    height: 1.4,
                                                    color: isDark
                                                        ? Colors.white60
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Bottom Navigation ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skip button (only when not last page)
                  if (_currentPage < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          LanguageNotifier.isIndonesian.value
                              ? 'Lewati Panduan'
                              : 'Skip Guide',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      // Previous button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _animateToPage(_currentPage - 1),
                            icon: const Icon(Icons.arrow_back_rounded,
                                size: 16),
                            label: Text(
                              LanguageNotifier.isIndonesian.value
                                  ? 'Sebelumnya'
                                  : 'Previous',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12),
                            ),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                      const SizedBox(width: 10),
                      // Next / Done button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_currentPage < steps.length - 1) {
                              _animateToPage(_currentPage + 1);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          icon: Icon(
                            _currentPage < steps.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _currentPage < steps.length - 1
                                ? (LanguageNotifier.isIndonesian.value
                                    ? 'Selanjutnya'
                                    : 'Next')
                                : (LanguageNotifier.isIndonesian.value
                                    ? 'Selesai & Mulai!'
                                    : 'Done & Start!'),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                steps[_currentPage].accentColor,
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
  }

  // ═══════════════════════════════════════════════════════════════
  //  MOCKUP WIDGETS
  // ═══════════════════════════════════════════════════════════════

  // ── Welcome Mockup ──
  Widget _buildWelcomeMockup(bool isDark) {
    return Column(
      children: [
        // App icon mockup
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFF5C0009)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'NETFLIX HOME',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            LanguageNotifier.isIndonesian.value
                ? '✦ Panduan Interaktif Pelanggan'
                : '✦ Interactive Customer Guide',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE50914),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Feature chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureChip(Icons.dashboard_rounded,
                LanguageNotifier.isIndonesian.value ? 'Dashboard' : 'Dashboard',
                Colors.blueAccent, isDark),
            _buildFeatureChip(Icons.movie_filter_rounded,
                LanguageNotifier.isIndonesian.value ? 'Akun Netflix' : 'Netflix Accounts',
                const Color(0xFFE50914), isDark),
            _buildFeatureChip(Icons.support_agent_rounded,
                LanguageNotifier.isIndonesian.value ? 'CS 24/7' : 'CS 24/7',
                const Color(0xFF25D366), isDark),
            _buildFeatureChip(Icons.auto_awesome_rounded,
                LanguageNotifier.isIndonesian.value ? 'Auto-Login' : 'Auto-Login',
                Colors.amber, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(
      IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header Mockup ──
  Widget _buildHeaderMockup(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE50914), Color(0xFFB00710), Color(0xFF5C0009)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Top row with title and buttons
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NETFLIX HOME',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      LanguageNotifier.isIndonesian.value
                          ? '✦ Dashboard Pelanggan'
                          : '✦ Customer Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildMiniIconButton(Icons.support_agent_rounded),
              const SizedBox(width: 6),
              _buildMiniIconButton(Icons.sync_rounded),
            ],
          ),
          const SizedBox(height: 12),
          // Welcome card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.orangeAccent, Colors.pinkAccent],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFB00710),
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageNotifier.isIndonesian.value
                            ? 'Selamat Siang ☀️'
                            : 'Good Afternoon ☀️',
                        style: GoogleFonts.inter(
                            fontSize: 8, color: Colors.white60),
                      ),
                      Text(
                        'Username',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF46D369).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF46D369),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              LanguageNotifier.isIndonesian.value
                                  ? 'Pelanggan Aktif'
                                  : 'Active Subscriber',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF46D369),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildHeaderMiniStat('245', 'Total'),
                    const SizedBox(height: 4),
                    _buildHeaderMiniStat('200', 'Live'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }

  Widget _buildHeaderMiniStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(width: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 7, color: Colors.white54)),
        ],
      ),
    );
  }

  // ── Subscription Mockup ──
  Widget _buildSubscriptionMockup(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF46D369).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Color(0xFF46D369), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Status Langganan'
                          : 'Subscription Status',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Berlaku s/d: 30 September 2026'
                          : 'Valid until: September 30, 2026',
                      style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF46D369).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  LanguageNotifier.isIndonesian.value ? 'Aktif' : 'Active',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF46D369),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 14, color: Color(0xFF46D369)),
                const SizedBox(width: 8),
                Text(
                  LanguageNotifier.isIndonesian.value
                      ? 'Masa Aktif: 28 Hari'
                      : 'Active: 28 Days',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.93,
              backgroundColor: Colors.black12,
              color: Color(0xFF46D369),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  LanguageNotifier.isIndonesian.value
                      ? 'Perpanjang via WhatsApp'
                      : 'Extend via WhatsApp',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Server Status Mockup ──
  Widget _buildServerStatusMockup(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF46D369).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF46D369),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF46D369).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Icon(Icons.cloud_done_outlined,
              color: Color(0xFF46D369), size: 18),
          const SizedBox(width: 8),
          Text(
            LanguageNotifier.isIndonesian.value
                ? 'Server Streaming Aktif & Stabil'
                : 'Streaming Server Active & Stable',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF46D369),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Mockup ──
  Widget _buildStatsMockup(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            icon: Icons.storage_rounded,
            color: Colors.blueAccent,
            value: '245',
            unit: LanguageNotifier.isIndonesian.value ? 'Akun' : 'Accounts',
            label: 'Total',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniStatCard(
            icon: Icons.wifi_tethering,
            color: const Color(0xFF46D369),
            value: '200',
            unit: LanguageNotifier.isIndonesian.value ? 'Aktif' : 'Active',
            label: 'Live',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(label,
                  style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Package Grid Mockup ──
  Widget _buildPackageGridMockup(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMiniPlanCard('Basic', '52', '720p HD', '1 layar',
            Colors.blueAccent, Icons.sd_rounded, isDark),
        _buildMiniPlanCard('Standard', '85', '1080p FHD', '2 layar',
            const Color(0xFF46D369), Icons.hd_rounded, isDark),
        _buildMiniPlanCard('Premium', '63', '4K UHD', '4 layar',
            const Color(0xFFE50914), Icons.four_k_rounded, isDark),
        _buildMiniPlanCard('Mobile', '45', '480p SD', '1 layar',
            Colors.amber, Icons.phone_android_rounded, isDark),
      ],
    );
  }

  Widget _buildMiniPlanCard(String label, String count, String quality,
      String screens, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 12),
              ),
              const Spacer(),
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.bold)),
              Text('$quality • $screens',
                  style: GoogleFonts.inter(fontSize: 7, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Rules & Start Button Mockup ──
  Widget _buildRulesAndButtonMockup(bool isDark) {
    return Column(
      children: [
        // Rules mini card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    LanguageNotifier.isIndonesian.value
                        ? 'Panduan Menonton'
                        : 'Watching Guide',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMiniRule('1', LanguageNotifier.isIndonesian.value
                  ? 'Boleh tambah profil, dilarang hapus'
                  : 'May add profile, do not delete'),
              _buildMiniRule('2', LanguageNotifier.isIndonesian.value
                  ? 'Bebas ubah bahasa'
                  : 'Free to change language'),
              _buildMiniRule('3', LanguageNotifier.isIndonesian.value
                  ? 'Limit layar? Ganti akun baru'
                  : 'Screen limit? Switch account'),
              _buildMiniRule('4', LanguageNotifier.isIndonesian.value
                  ? 'Dilarang ubah email/password'
                  : 'Do not change email/password'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Start watching button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                LanguageNotifier.isIndonesian.value
                    ? 'Buka Daftar Akun & Mulai Nonton'
                    : 'Open Account List & Start Watching',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniRule(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 10, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tips & Tricks Mockup ──
  Widget _buildTipsTricksMockup(bool isDark) {
    return Column(
      children: [
        // Pull-to-refresh illustration
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTipIcon(Icons.refresh_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Pull Refresh' : 'Pull Refresh',
                      Colors.blueAccent, isDark),
                  _buildTipIcon(Icons.support_agent_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Pusat Bantuan' : 'Help Center',
                      const Color(0xFF25D366), isDark),
                  _buildTipIcon(Icons.person_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Profil' : 'Profile',
                      Colors.orangeAccent, isDark),
                  _buildTipIcon(Icons.dark_mode_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Mode Gelap' : 'Dark Mode',
                      Colors.deepPurpleAccent, isDark),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTipIcon(Icons.language_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Bahasa' : 'Language',
                      Colors.teal, isDark),
                  _buildTipIcon(Icons.card_giftcard_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Voucher' : 'Voucher',
                      Colors.pinkAccent, isDark),
                  _buildTipIcon(Icons.menu_book_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Panduan' : 'Guide',
                      Colors.amber, isDark),
                  _buildTipIcon(Icons.lock_rounded,
                      LanguageNotifier.isIndonesian.value ? 'Password' : 'Password',
                      Colors.redAccent, isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Completion badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurpleAccent.withValues(alpha: 0.15),
                Colors.blueAccent.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Panduan Selesai! 🎉'
                          : 'Guide Complete! 🎉',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Anda sekarang siap menggunakan Netflix Home.'
                          : 'You are now ready to use Netflix Home.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipIcon(
      IconData icon, String label, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════
class _GuideStep {
  final int stepNumber;
  final int totalSteps;
  final String title;
  final String description;
  final Color accentColor;
  final IconData icon;
  final Widget mockupWidget;
  final String pointerLabel;
  final List<String> tips;

  const _GuideStep({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.mockupWidget,
    required this.pointerLabel,
    this.tips = const [],
  });
}

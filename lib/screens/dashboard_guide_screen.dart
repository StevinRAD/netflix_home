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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
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
      _GuideStep(
        stepNumber: 1,
        totalSteps: 5,
        title: LanguageNotifier.isIndonesian.value
            ? 'Banner Info Langganan'
            : 'Subscription Info Banner',
        description: LanguageNotifier.isIndonesian.value
            ? 'Di bagian atas dashboard, Anda akan melihat kartu status langganan. Kartu ini menampilkan sisa masa aktif paket Anda secara real-time (hari, jam, menit, detik).\n\nJika paket sudah habis, badge akan berubah merah dan Anda tidak bisa mengakses daftar akun Netflix.\n\nTekan tombol hijau "Perpanjang via WhatsApp" untuk langsung menghubungi admin.'
            : 'At the top of the dashboard, you\'ll see the subscription status card. This card shows your remaining package time in real-time (days, hours, minutes, seconds).\n\nIf the package expires, the badge turns red and you cannot access the Netflix account list.\n\nPress the green "Extend via WhatsApp" button to contact admin directly.',
        accentColor: const Color(0xFFE50914),
        icon: Icons.timer_outlined,
        mockupWidget: _buildSubscriptionMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Kartu ini ada di paling atas Dashboard'
            : '👆 This card is at the top of the Dashboard',
      ),
      _GuideStep(
        stepNumber: 2,
        totalSteps: 5,
        title: LanguageNotifier.isIndonesian.value
            ? 'Status Server Streaming'
            : 'Streaming Server Status',
        description: LanguageNotifier.isIndonesian.value
            ? 'Indikator hijau berkedip menunjukkan bahwa server streaming Netflix Home sedang online dan siap digunakan.\n\nJika ada gangguan server, indikator akan berubah menjadi merah atau kuning. Saat itu, tunggu beberapa saat dan coba lagi.'
            : 'The blinking green indicator shows that the Netflix Home streaming server is online and ready to use.\n\nIf there is a server issue, the indicator will turn red or yellow. Wait a moment and try again.',
        accentColor: const Color(0xFF46D369),
        icon: Icons.cloud_done_outlined,
        mockupWidget: _buildServerStatusMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Indikator ini ada di bawah banner langganan'
            : '👆 This indicator is below the subscription banner',
      ),
      _GuideStep(
        stepNumber: 3,
        totalSteps: 5,
        title: LanguageNotifier.isIndonesian.value
            ? 'Statistik Total Akun'
            : 'Total Account Statistics',
        description: LanguageNotifier.isIndonesian.value
            ? 'Dua kartu statistik menampilkan:\n\n📊 Total Ketersediaan — Jumlah seluruh akun Netflix yang ada di sistem.\n\n✅ Akun Live — Jumlah akun yang statusnya aktif dan bisa langsung digunakan untuk menonton.\n\nAngka ini diperbarui otomatis setiap kali Anda membuka dashboard atau menarik layar ke bawah (refresh).'
            : 'Two statistics cards show:\n\n📊 Total Availability — Total Netflix accounts in the system.\n\n✅ Live Accounts — Accounts that are active and ready for streaming.\n\nThese numbers update automatically when you open the dashboard or pull down to refresh.',
        accentColor: Colors.blueAccent,
        icon: Icons.bar_chart_rounded,
        mockupWidget: _buildStatsMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Dua kartu ini ada di bagian "Statistik Akun"'
            : '👆 These two cards are in the "Account Statistics" section',
      ),
      _GuideStep(
        stepNumber: 4,
        totalSteps: 5,
        title: LanguageNotifier.isIndonesian.value
            ? 'Ketersediaan Paket'
            : 'Package Availability',
        description: LanguageNotifier.isIndonesian.value
            ? 'Grid 4 kartu paket menampilkan rincian akun per tipe langganan:\n\n🔵 Basic — Kualitas 720p HD\n🟢 Standard — Kualitas 1080p Full HD\n🔴 Premium — Kualitas 4K Ultra HD\n🟡 Mobile — Kualitas 480p SD\n\nAngka di pojok kanan atas setiap kartu menunjukkan jumlah akun yang tersedia untuk tipe tersebut.'
            : 'A grid of 4 package cards shows account breakdown by subscription type:\n\n🔵 Basic — 720p HD Quality\n🟢 Standard — 1080p Full HD Quality\n🔴 Premium — 4K Ultra HD Quality\n🟡 Mobile — 480p SD Quality\n\nThe number at the top-right of each card shows available accounts for that type.',
        accentColor: Colors.amber,
        icon: Icons.inventory_2_outlined,
        mockupWidget: _buildPackageGridMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Grid ini ada di bagian "Ketersediaan Paket"'
            : '👆 This grid is in the "Package Availability" section',
      ),
      _GuideStep(
        stepNumber: 5,
        totalSteps: 5,
        title: LanguageNotifier.isIndonesian.value
            ? 'Tombol Mulai Nonton'
            : 'Start Watching Button',
        description: LanguageNotifier.isIndonesian.value
            ? 'Tombol merah besar di bagian paling bawah dashboard adalah pintasan (shortcut) utama Anda.\n\nTekan tombol ini untuk langsung berpindah ke halaman "Daftar Akun Netflix" di mana Anda bisa:\n• Memilih akun Netflix\n• Mendapatkan link auto-login\n• Langsung menonton di HP, PC, atau Smart TV\n\n⚠️ Tombol ini hanya aktif jika paket Anda masih berlaku. Jika sudah expired, tombol akan berwarna abu-abu.'
            : 'The large red button at the very bottom of the dashboard is your main shortcut.\n\nPress this button to jump directly to the "Netflix Account List" page where you can:\n• Choose a Netflix account\n• Get auto-login links\n• Start watching on Phone, PC, or Smart TV\n\n⚠️ This button is only active if your package is valid. If expired, it will be grayed out.',
        accentColor: const Color(0xFFE50914),
        icon: Icons.play_circle_fill_rounded,
        mockupWidget: _buildStartButtonMockup(isDark),
        pointerLabel: LanguageNotifier.isIndonesian.value
            ? '👆 Tombol ini ada di bagian paling bawah Dashboard'
            : '👆 This button is at the very bottom of the Dashboard',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _getSteps(isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F7),
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
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
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
                              ? 'Panduan Interaktif'
                              : 'Interactive Guide',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          LanguageNotifier.isIndonesian.value
                              ? 'Kenali setiap fitur Dashboard'
                              : 'Learn each Dashboard feature',
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: steps[_currentPage].accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: steps[_currentPage].accentColor.withValues(alpha: 0.3),
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
                        margin: EdgeInsets.only(right: index < steps.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? steps[_currentPage].accentColor
                              : (isDark ? Colors.white12 : Colors.black12),
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
                                        step.accentColor.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: step.accentColor.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(step.icon, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Mockup Preview Container
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: step.accentColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: step.accentColor.withValues(alpha: 0.1),
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
                                      color: step.accentColor.withValues(alpha: 0.08),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.preview_rounded,
                                            size: 14, color: step.accentColor),
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
                                        color: step.accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
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
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                          size: 16, color: step.accentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        LanguageNotifier.isIndonesian.value
                                            ? 'Penjelasan'
                                            : 'Explanation',
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
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
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
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _animateToPage(_currentPage - 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(
                          LanguageNotifier.isIndonesian.value
                              ? 'Sebelumnya'
                              : 'Previous',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12),
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
                                ? 'Selesai'
                                : 'Done'),
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: steps[_currentPage].accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
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

  // ═══════════════════════════════════════════════════════════════
  //  MOCKUP WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSubscriptionMockup(bool isDark) {
    return Column(
      children: [
        // Subscription card mockup
        Container(
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
                          style: GoogleFonts.inter(
                              fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
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
                    const Icon(Icons.chat_rounded,
                        size: 13, color: Colors.white),
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
        ),
      ],
    );
  }

  Widget _buildServerStatusMockup(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF46D369).withValues(alpha: 0.3)),
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

  Widget _buildStatsMockup(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.storage_rounded,
                          color: Colors.blueAccent, size: 14),
                    ),
                    const Spacer(),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Total'
                          : 'Total',
                      style:
                          GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '245',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        LanguageNotifier.isIndonesian.value ? 'Akun' : 'Accounts',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.blueAccent.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF46D369).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF46D369).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.wifi_tethering,
                          color: Color(0xFF46D369), size: 14),
                    ),
                    const Spacer(),
                    Text('Live', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '200',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF46D369),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        LanguageNotifier.isIndonesian.value ? 'Aktif' : 'Active',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: const Color(0xFF46D369).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageGridMockup(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMiniPlanCard('Basic', '52', '720p HD', Colors.blueAccent,
            Icons.sd_rounded, isDark),
        _buildMiniPlanCard('Standard', '85', '1080p FHD',
            const Color(0xFF46D369), Icons.hd_rounded, isDark),
        _buildMiniPlanCard('Premium', '63', '4K UHD',
            const Color(0xFFE50914), Icons.four_k_rounded, isDark),
        _buildMiniPlanCard('Mobile', '45', '480p SD', Colors.amber,
            Icons.phone_android_rounded, isDark),
      ],
    );
  }

  Widget _buildMiniPlanCard(String label, String count, String quality,
      Color color, IconData icon, bool isDark) {
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
              Text(quality,
                  style: GoogleFonts.inter(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButtonMockup(bool isDark) {
    return Column(
      children: [
        // Active state
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Label for states
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF46D369).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF46D369).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 12, color: Color(0xFF46D369)),
                    const SizedBox(width: 4),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Aktif'
                          : 'Active',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF46D369),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Expired = Abu-abu'
                          : 'Expired = Gray',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  const _GuideStep({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.mockupWidget,
    required this.pointerLabel,
  });
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/account_model.dart';
import '../services/supabase_service.dart';
import '../utils/language_notifier.dart';
import 'dashboard_guide_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final VoidCallback? onNavigateToAccounts;

  const DashboardScreen({
    super.key,
    required this.username,
    this.onNavigateToAccounts,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<CookieAccount> _accounts = [];
  bool _isLoading = true;

  DateTime? _accessExpiryDate;
  // ignore: unused_field
  bool _isLoadingExpiry = true;

  bool get _isAccessExpired {
    if (_accessExpiryDate == null) return true;
    return DateTime.now().isAfter(_accessExpiryDate!);
  }

  int get _remainingDays {
    if (_accessExpiryDate == null) return 0;
    if (_isAccessExpired) return 0;
    return _accessExpiryDate!.difference(DateTime.now()).inDays + 1;
  }

  String _getIndonesianMonth(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  final GlobalKey _keyTopBanner = GlobalKey();
  final GlobalKey _keyStatCard = GlobalKey();
  final GlobalKey _keyPackageGrid = GlobalKey();
  final GlobalKey _keyStartButton = GlobalKey();

  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadAccounts();
    _loadExpiryDate();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeGuide();
    });
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
    _pulseController.dispose();
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
    }
  }

  Future<void> _checkFirstTimeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownGuide = prefs.getBool('dashboard_guide_shown') ?? false;
    if (!hasShownGuide && mounted) {
      // Tampilkan panduan interaktif hanya pada penggunaan pertama
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardGuideScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      await prefs.setBool('dashboard_guide_shown', true);
    }

    // Setelah guide selesai (atau jika sudah pernah ditampilkan), jalankan showcase
    if (mounted) {
      _checkShowcase();
    }
  }

  Future<void> _checkShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('dashboard_showcase_shown') ?? false;
    if (!hasShown) {
      if (mounted) {
        // ignore: deprecated_member_use
        ShowCaseWidget.of(context).startShowCase([
          _keyTopBanner,
          _keyStatCard,
          _keyPackageGrid,
          _keyStartButton,
        ]);
        await prefs.setBool('dashboard_showcase_shown', true);
      }
    }
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await SupabaseService.fetchCookieAccounts();
    await _loadExpiryDate();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _syncFromSupabaseStorage() async {
    setState(() => _isLoading = true);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(LanguageNotifier.isIndonesian.value
                    ? 'Memperbarui daftar akun...'
                    : 'Updating account list...'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: const Color(0xFF333333),
          ),
        );
      }

      final int successCount = await SupabaseService.syncTxtFilesFromStorage();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(LanguageNotifier.isIndonesian.value
                      ? 'Berhasil! $successCount data baru ditambahkan.'
                      : 'Success! $successCount new data added.'),
                ],
              ),
              backgroundColor: const Color(0xFF46D369),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(LanguageNotifier.isIndonesian.value
                        ? 'Daftar akun sudah versi terbaru.'
                        : 'Account list is already up to date.'),
                  ),
                ],
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      await _loadAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(LanguageNotifier.isIndonesian.value
                      ? 'Daftar akun sudah versi terbaru.'
                      : 'Account list is already up to date.'),
                ),
              ],
            ),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        await _loadAccounts();
      }
    }
  }

  Future<void> _contactAdminWhatsApp() async {
    final text =
        'Halo Admin Netflix Home, saya (${widget.username}) butuh bantuan perpanjangan paket / pembelian langganan.';
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

  String _getRemainingTimeText() {
    if (_accessExpiryDate == null || _isAccessExpired) {
      return LanguageNotifier.isIndonesian.value
          ? 'Paket Habis'
          : 'Package Expired';
    }

    final diff = _accessExpiryDate!.difference(DateTime.now());

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
          ? 'Masa Aktif: $days Hari'
          : 'Active: $days Days';
    }
  }

  double get _expiryProgress {
    if (_accessExpiryDate == null || _isAccessExpired) return 0.0;
    final diff = _accessExpiryDate!.difference(DateTime.now());
    return (diff.inDays / 30.0).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCount = _accounts.length;
    final liveCount = _accounts.where((a) => a.status == 'LIVE').length;
    final basicCount = _accounts
        .where((a) => a.planName.toLowerCase().contains('basic'))
        .length;
    final standardCount = _accounts
        .where((a) => a.planName.toLowerCase().contains('standard'))
        .length;
    final premiumCount = _accounts
        .where((a) => a.planName.toLowerCase().contains('premium'))
        .length;
    final mobileCount = _accounts
        .where((a) => a.planName.toLowerCase().contains('mobile'))
        .length;

    return Scaffold(
      body: _isLoading
          ? _buildShimmerLoading(isDark)
          : RefreshIndicator(
              color: const Color(0xFFE50914),
              onRefresh: _syncFromSupabaseStorage,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Premium Gradient App Bar ──
                  SliverAppBar(
                    expandedHeight: 190,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFFB00710),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          // Base gradient
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFE50914),
                                  Color(0xFFB00710),
                                  Color(0xFF5C0009),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Decorative glowing orbs
                          Positioned(
                            top: -40,
                            right: -30,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.12),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: -50,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.orangeAccent.withValues(alpha: 0.1),
                                    Colors.orangeAccent.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Subtle pattern overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DiagonalPatternPainter(),
                            ),
                          ),
                          // Content
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title Row with brand identity
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0.25),
                                              Colors.white.withValues(alpha: 0.1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: const Icon(Icons.play_arrow_rounded,
                                            color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'NETFLIX HOME',
                                            style: GoogleFonts.inter(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              LanguageNotifier.isIndonesian.value
                                                  ? '✦ Dashboard Pelanggan'
                                                  : '✦ Customer Dashboard',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(alpha: 0.85),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      // Sync button with glow
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _syncFromSupabaseStorage,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withValues(alpha: 0.2),
                                                  Colors.white.withValues(alpha: 0.08),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.15),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.sync_rounded,
                                                color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Welcome Card — Glassmorphism style
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar with gradient ring
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.orangeAccent,
                                                Colors.pinkAccent,
                                                Colors.purpleAccent,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orangeAccent.withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFFB00710),
                                            child: Text(
                                              widget.username.isNotEmpty
                                                  ? widget.username[0].toUpperCase()
                                                  : 'U',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getGreeting(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.white60,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                widget.username,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              // Status badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _isAccessExpired
                                                      ? Colors.orangeAccent.withValues(alpha: 0.25)
                                                      : const Color(0xFF46D369).withValues(alpha: 0.25),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: _isAccessExpired
                                                        ? Colors.orangeAccent.withValues(alpha: 0.4)
                                                        : const Color(0xFF46D369).withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: _isAccessExpired
                                                            ? Colors.orangeAccent
                                                            : const Color(0xFF46D369),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: (_isAccessExpired
                                                                    ? Colors.orangeAccent
                                                                    : const Color(0xFF46D369))
                                                                .withValues(alpha: 0.6),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      _isAccessExpired
                                                          ? (LanguageNotifier.isIndonesian.value
                                                              ? 'Paket Tidak Aktif'
                                                              : 'Package Inactive')
                                                          : (LanguageNotifier.isIndonesian.value
                                                              ? 'Pelanggan Aktif'
                                                              : 'Active Subscriber'),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: _isAccessExpired
                                                            ? Colors.orangeAccent
                                                            : const Color(0xFF46D369),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Mini stats column
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _buildMiniStat(
                                              Icons.storage_rounded,
                                              '$totalCount',
                                              LanguageNotifier.isIndonesian.value
                                                  ? 'Total'
                                                  : 'Total',
                                            ),
                                            const SizedBox(height: 6),
                                            _buildMiniStat(
                                              Icons.wifi_tethering,
                                              '$liveCount',
                                              'Live',
                                            ),
                                          ],
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
                    ),
                  ),

                  // ── Body Content ──
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── 1. Subscription Status Card ───
                          Showcase(
                            key: _keyTopBanner,
                            description: LanguageNotifier.isIndonesian.value
                                ? 'Info masa aktif langganan Anda & tombol untuk perpanjang paket.'
                                : 'Your subscription status & button to extend package.',
                            child: _buildSubscriptionCard(isDark),
                          ),

                          // ─── 2. Server Status ───
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1A2E1A)
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF46D369).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF46D369),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF46D369).withValues(alpha: 0.5),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.cloud_done_outlined,
                                        color: Color(0xFF46D369), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      LanguageNotifier.isIndonesian.value
                                          ? 'Server Streaming Aktif & Stabil'
                                          : 'Streaming Server Active & Stable',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF46D369),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ─── 3. Statistics Section ───
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.bar_chart_rounded,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                      size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    LanguageNotifier.isIndonesian.value
                                        ? 'STATISTIK AKUN'
                                        : 'ACCOUNT STATISTICS',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            Showcase(
                              key: _keyStatCard,
                              description: LanguageNotifier.isIndonesian.value
                                  ? 'Ringkasan total akun yang tersedia dan berstatus valid.'
                                  : 'Summary of total available and valid accounts.',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        title: LanguageNotifier.tr('total_availability'),
                                        value: '$totalCount',
                                        unit: LanguageNotifier.isIndonesian.value
                                            ? 'Akun'
                                            : 'Accounts',
                                        icon: Icons.storage_rounded,
                                        color: Colors.blueAccent,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        title: LanguageNotifier.tr('live_accounts'),
                                        value: '$liveCount',
                                        unit: LanguageNotifier.isIndonesian.value
                                            ? 'Aktif'
                                            : 'Active',
                                        icon: Icons.wifi_tethering,
                                        color: const Color(0xFF46D369),
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── 4. Package Availability Grid ───
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                      size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    LanguageNotifier.tr('package_availability').toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            Showcase(
                              key: _keyPackageGrid,
                              description: LanguageNotifier.isIndonesian.value
                                  ? 'Rincian jumlah akun berdasarkan tipe paket.'
                                  : 'Account breakdown by package type.',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.5,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildPlanCard(
                                      label: 'Basic',
                                      count: basicCount,
                                      subtitle: '720p HD',
                                      gradientColors: [Colors.blueAccent, Colors.blue.shade700],
                                      icon: Icons.sd_rounded,
                                      isDark: isDark,
                                    ),
                                    _buildPlanCard(
                                      label: 'Standard',
                                      count: standardCount,
                                      subtitle: '1080p FHD',
                                      gradientColors: [const Color(0xFF46D369), const Color(0xFF2E8B4A)],
                                      icon: Icons.hd_rounded,
                                      isDark: isDark,
                                    ),
                                    _buildPlanCard(
                                      label: 'Premium',
                                      count: premiumCount,
                                      subtitle: '4K Ultra HD',
                                      gradientColors: [const Color(0xFFE50914), const Color(0xFFB71C1C)],
                                      icon: Icons.four_k_rounded,
                                      isDark: isDark,
                                    ),
                                    _buildPlanCard(
                                      label: 'Mobile',
                                      count: mobileCount,
                                      subtitle: '480p SD',
                                      gradientColors: [Colors.amber, Colors.orange.shade700],
                                      icon: Icons.phone_android_rounded,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── 5. Customer Rules ───
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildRulesCard(isDark),
                            ),
                            const SizedBox(height: 20),

                            // ─── 6. Action Button ───
                            Showcase(
                              key: _keyStartButton,
                              description: LanguageNotifier.isIndonesian.value
                                  ? 'Tekan tombol ini untuk melihat daftar akun & mendapatkan link tontonan.'
                                  : 'Press this button to view account list & get streaming links.',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildStartWatchingButton(isDark),
                              ),
                            ),
                            const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUBSCRIPTION STATUS CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSubscriptionCard(bool isDark) {
    final expiryFormatted = _accessExpiryDate != null
        ? '${_accessExpiryDate!.day} ${_getIndonesianMonth(_accessExpiryDate!.month)} ${_accessExpiryDate!.year}'
        : '-';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAccessExpired
              ? Colors.redAccent.withValues(alpha: 0.3)
              : const Color(0xFF46D369).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _isAccessExpired
                ? Colors.red.withValues(alpha: 0.08)
                : const Color(0xFF46D369).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isAccessExpired
                          ? Colors.redAccent
                          : const Color(0xFFE50914))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isAccessExpired
                      ? Icons.lock_clock_rounded
                      : Icons.verified_user_rounded,
                  color: _isAccessExpired
                      ? Colors.redAccent
                      : const Color(0xFF46D369),
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
                          ? 'Status Langganan'
                          : 'Subscription Status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LanguageNotifier.isIndonesian.value
                          ? 'Berlaku s/d: $expiryFormatted'
                          : 'Valid until: $expiryFormatted',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isAccessExpired
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : const Color(0xFF46D369).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isAccessExpired
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : const Color(0xFF46D369).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _isAccessExpired
                      ? (LanguageNotifier.isIndonesian.value
                          ? 'Tidak Aktif'
                          : 'Inactive')
                      : (LanguageNotifier.isIndonesian.value
                          ? 'Aktif'
                          : 'Active'),
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

          // Countdown Timer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _isAccessExpired
                      ? Icons.timer_off_outlined
                      : Icons.hourglass_top_rounded,
                  size: 18,
                  color: _isAccessExpired
                      ? Colors.redAccent
                      : (_remainingDays <= 5
                          ? Colors.orangeAccent
                          : const Color(0xFF46D369)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getRemainingTimeText(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isAccessExpired
                          ? Colors.redAccent
                          : (_remainingDays <= 5
                              ? Colors.orangeAccent
                              : (isDark ? Colors.white : Colors.black87)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

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
                      : const Color(0xFF46D369)),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),

          // WhatsApp Extend Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _contactAdminWhatsApp,
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: Text(
                _isAccessExpired
                    ? (LanguageNotifier.isIndonesian.value
                        ? 'Beli Paket via WhatsApp'
                        : 'Buy Package via WhatsApp')
                    : (LanguageNotifier.isIndonesian.value
                        ? 'Perpanjang Paket via WhatsApp'
                        : 'Extend Package via WhatsApp'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAccessExpired
                    ? const Color(0xFF25D366)
                    : const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STAT CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  // ═══════════════════════════════════════════════════════════════
  //  PLAN CARD (Grid Item)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPlanCard({
    required String label,
    required int count,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
            ),
            // Gradient accent at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                ),
              ),
            ),
            // Decorative circle
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 60,
                color: gradientColors[0].withValues(alpha: 0.07),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                      const Spacer(),
                      Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: gradientColors[0],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.inter(fontSize: 10, color: Colors.grey),
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
  //  RULES CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRulesCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.06),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: Colors.amber, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                LanguageNotifier.isIndonesian.value
                    ? 'Panduan Menonton'
                    : 'Watching Guide',
                style:
                    GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRuleItem(
            icon: Icons.people_outline,
            text: LanguageNotifier.isIndonesian.value
                ? 'Gunakan profil yang sudah tersedia di akun.'
                : 'Use existing profiles in the account.',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildRuleItem(
            icon: Icons.flash_on_outlined,
            text: LanguageNotifier.isIndonesian.value
                ? 'Gunakan link otomatis untuk masuk tanpa perlu email dan sandi.'
                : 'Use auto-login link to sign in without email and password.',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildRuleItem(
            icon: Icons.do_not_disturb_on_outlined,
            text: LanguageNotifier.isIndonesian.value
                ? 'Jangan mengubah profil, email, atau sandi akun Netflix.'
                : 'Do not change the profile, email, or password of Netflix account.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
      {required IconData icon, required String text, required bool isDark}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  START WATCHING BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStartWatchingButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _isAccessExpired
            ? LinearGradient(
                colors: [Colors.grey.shade500, Colors.grey.shade600])
            : const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
              ),
        boxShadow: _isAccessExpired
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFE50914).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (_isAccessExpired) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(LanguageNotifier.isIndonesian.value
                            ? 'Paket Anda belum aktif atau sudah habis.'
                            : 'Your package is not active or has expired.'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }
            if (widget.onNavigateToAccounts != null) {
              widget.onNavigateToAccounts!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  LanguageNotifier.isIndonesian.value
                      ? 'Buka Daftar Akun & Mulai Nonton'
                      : 'Open Account List & Start Watching',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (LanguageNotifier.isIndonesian.value) {
      if (hour < 11) return 'Selamat Pagi 🌅';
      if (hour < 15) return 'Selamat Siang ☀️';
      if (hour < 18) return 'Selamat Sore 🌇';
      return 'Selamat Malam 🌙';
    } else {
      if (hour < 11) return 'Good Morning 🌅';
      if (hour < 15) return 'Good Afternoon ☀️';
      if (hour < 18) return 'Good Evening 🌇';
      return 'Good Night 🌙';
    }
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════
  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header shimmer
          _shimmerBox(width: double.infinity, height: 150, baseColor: baseColor,
              highlightColor: highlightColor, radius: 16),
          const SizedBox(height: 16),
          // Subscription card shimmer
          _shimmerBox(width: double.infinity, height: 180, baseColor: baseColor,
              highlightColor: highlightColor, radius: 16),
          const SizedBox(height: 16),
          // Server status shimmer
          _shimmerBox(width: double.infinity, height: 40, baseColor: baseColor,
              highlightColor: highlightColor, radius: 10),
          const SizedBox(height: 16),
          // Stat cards shimmer
          Row(
            children: [
              Expanded(
                child: _shimmerBox(height: 90, baseColor: baseColor,
                    highlightColor: highlightColor, radius: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _shimmerBox(height: 90, baseColor: baseColor,
                    highlightColor: highlightColor, radius: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid shimmer
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (_) => _shimmerBox(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  radius: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    double? width,
    double? height,
    required Color baseColor,
    required Color highlightColor,
    double radius = 8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                math.max(0, value - 0.3),
                value,
                math.min(1, value + 0.3)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DIAGONAL PATTERN PAINTER
// ═══════════════════════════════════════════════════════════════
class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 24.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

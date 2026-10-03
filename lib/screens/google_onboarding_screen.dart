import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'main_screen.dart';

class GoogleOnboardingScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String initialName;
  final String? avatarUrl;

  const GoogleOnboardingScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.initialName,
    this.avatarUrl,
  });

  @override
  State<GoogleOnboardingScreen> createState() => _GoogleOnboardingScreenState();
}

class _GoogleOnboardingScreenState extends State<GoogleOnboardingScreen> {
  int _currentStep = 0; // 0 = Profile Setup, 1 = Tutorial
  late final TextEditingController _usernameController;
  final PageController _tutorialPageController = PageController();
  int _currentTutorialPage = 0;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tutorialPageController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Harap tentukan nama pengguna atau nama toko Anda.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    await SupabaseService.completeGoogleOnboarding(
      userId: widget.userId,
      username: username,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _currentStep = 1; // Move to Tutorial
    });
  }

  void _finishOnboarding() {
    final finalUsername = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : widget.initialName;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreen(username: finalUsername),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Stack(
        children: [
          // Background Gradient effect
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    Color(0x33E50914),
                    Color(0xFF141414),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'NETFLIX',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 36,
                                color: const Color(0xFFE50914),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE50914).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE50914), width: 1),
                              ),
                              child: Text(
                                'HOME',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Step Indicator
                      _buildStepIndicator(),
                      const SizedBox(height: 24),

                      // Main Card
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 0
                            ? _buildProfileSetupCard()
                            : _buildTutorialCard(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(0, '1. Profil Akun', _currentStep == 0, _currentStep > 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(width: 24, height: 1.5, color: Colors.white24),
          ),
          _buildStepItem(1, '2. Panduan Singkat', _currentStep == 1, false),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, bool isActive, bool isDone) {
    Color color = Colors.white38;
    if (isActive) color = const Color(0xFFE50914);
    if (isDone) color = const Color(0xFF10B981);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 12, color: Color(0xFF10B981))
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1: PROFILE SETUP CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProfileSetupCard() {
    return Container(
      key: const ValueKey('step_profile'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.person_add_alt_1, color: Color(0xFFE50914), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendaftaran Lanjutan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Atur nama tampilan akun Anda',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Google Linked Account Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    ),
                  )
                else
                  _buildDefaultAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.email,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Terhubung via Akun Google',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF6B6B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Username Input Field
          Text(
            'Nama Pengguna / Nama Toko',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2B2B2B),
              hintText: 'Contoh: Budi Store / Netflix Premium',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white54, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nama ini akan tersimpan di database dan tampil di Dashboard monitoring Admin.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 20),

          // Security Info Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Akun Anda otomatis dilindungi oleh sistem keamanan Google. Tanpa perlu repot membuat sandi baru.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSaveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Simpan & Lanjut ke Panduan',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE50914),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2: TUTORIAL & APP GUIDE CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTutorialCard() {
    final List<Map<String, dynamic>> tutorialSteps = [
      {
        'title': 'Ambil & Gunakan Akun Netflix',
        'subtitle': 'Akses akun dengan satu sentuhan',
        'desc': 'Di menu "Akun", pilih salah satu akun Netflix aktif (Premium / Standard). Anda dapat langsung membuka Netflix tanpa harus mengetik email dan kata sandi.',
        'icon': Icons.movie_filter_outlined,
        'badgeColor': const Color(0xFFE50914),
      },
      {
        'title': 'Login ke TV & Komputer',
        'subtitle': 'QR Code & Link Login Sekali Klik',
        'desc': 'Ingin menonton di Smart TV atau Laptop? Gunakan fitur QR Code Scanner atau salin URL login langsung dari detail akun ke browser perangkat Anda.',
        'icon': Icons.qr_code_scanner,
        'badgeColor': const Color(0xFF38BDF8),
      },
      {
        'title': 'Masa Aktif & Penukaran Voucher',
        'subtitle': 'Pantau sisa masa aktif akun Anda',
        'desc': 'Lihat sisa hari masa aktif Anda di Beranda. Jika durasi habis, tukarkan Kode Voucher dari Admin untuk memperpanjang akses secara otomatis.',
        'icon': Icons.card_giftcard,
        'badgeColor': const Color(0xFF10B981),
      },
    ];

    final isLastPage = _currentTutorialPage == tutorialSteps.length - 1;

    return Container(
      key: const ValueKey('step_tutorial'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Panduan Penggunaan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_currentTutorialPage + 1} dari ${tutorialSteps.length}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tutorial Carousel
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _tutorialPageController,
              onPageChanged: (idx) => setState(() => _currentTutorialPage = idx),
              itemCount: tutorialSteps.length,
              itemBuilder: (ctx, idx) {
                final item = tutorialSteps[idx];
                final color = item['badgeColor'] as Color;
                return Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desc'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              tutorialSteps.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentTutorialPage == index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentTutorialPage == index
                      ? const Color(0xFFE50914)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (_currentTutorialPage > 0) ...[
                OutlinedButton(
                  onPressed: () {
                    _tutorialPageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Sebelumnya', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLastPage) {
                        _finishOnboarding();
                      } else {
                        _tutorialPageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastPage
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      isLastPage ? 'Mulai Gunakan Netflix Home 🎬' : 'Lanjut ➔',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

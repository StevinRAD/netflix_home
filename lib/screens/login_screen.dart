import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../utils/language_notifier.dart';
import '../utils/user_notifier.dart';
import 'google_onboarding_screen.dart';
import 'login_help_modal.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isRegistering = false;
  String _appVersion = 'v...';
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastEmail();
    _loadAppVersion();
    _setupAuthListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isGoogleLoading) {
      // If user came back from browser without completing auth, reset loading state
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _isGoogleLoading) {
          setState(() {
            _isLoading = false;
            _isGoogleLoading = false;
          });
        }
      });
    }
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        final isNewUser = await SupabaseService.handleOAuthSession(session);
        if (!mounted) return;
        if (isNewUser) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GoogleOnboardingScreen(
                userId: session.user.id,
                email: session.user.email ?? '',
                initialName: UserNotifier.username.value,
                avatarUrl: UserNotifier.avatarUrl.value,
              ),
            ),
          );
        } else {
          final displayName = UserNotifier.username.value.isNotEmpty
              ? UserNotifier.username.value
              : (session.user.email?.split('@').first ?? 'Pengguna');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen(username: displayName)),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    }
  }

  Future<void> _loadLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_email');
    if (lastEmail != null && lastEmail.isNotEmpty) {
      setState(() {
        _emailController.text = lastEmail;
      });
    }
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isRegistering && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageNotifier.tr('fill_fields')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = false;
    String? errorMessage;
    try {
      if (_isRegistering) {
        await SupabaseService.register(email, password, name);
        // Supabase sign-up doesn't auto login via this endpoint typically, 
        // but let's assume if it succeeds we can proceed or login right after.
        success = await SupabaseService.login(email, password);
      } else {
        success = await SupabaseService.login(email, password);
      }
    } catch (e) {
      success = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final displayName = UserNotifier.username.value.isNotEmpty
          ? UserNotifier.username.value
          : (_isRegistering ? name : (email.split('@').first));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(username: displayName)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? (_isRegistering ? LanguageNotifier.tr('register_failed') : LanguageNotifier.tr('login_failed'))),
          backgroundColor: const Color(0xFFE50914),
        ),
      );
    }
  }

  void _showHelpModal() {
    LoginHelpModal.show(context);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });
    try {
      final success = await SupabaseService.signInWithGoogle();
      if (!success && mounted) {
        setState(() {
          _isLoading = false;
          _isGoogleLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isGoogleLoading = false;
      });
      final errorStr = e.toString();
      if (errorStr.contains('provider is not enabled') ||
          errorStr.contains('validation_failed') ||
          errorStr.contains('Unsupported provider')) {
        _showGoogleProviderNoticeDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungkan ke Google: ${e.toString().replaceFirst("Exception: ", "").replaceFirst("AuthException: ", "")}'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  void _showGoogleProviderNoticeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFE50914), size: 24),
            const SizedBox(width: 10),
            Text(
              'Aktivasi Google Login',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Provider Google belum diaktifkan di Supabase Dashboard project Anda.\n\n'
          'Untuk mengaktifkannya:\n'
          '1. Buka Supabase Console > Authentication > Providers > Google.\n'
          '2. Masukkan Client ID & Client Secret dari Google Cloud Console.\n'
          '3. Aktifkan toggle Google Provider.\n\n'
          'Sementara waktu, Anda dapat mendaftar dan masuk menggunakan formulir Email & Password.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotPasswordSheet(
        initialEmail: _emailController.text.trim(),
        onSuccess: (newEmail) {
          setState(() {
            _emailController.text = newEmail;
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LanguageNotifier.tr('password_changed_success')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: LanguageNotifier.isIndonesian,
      builder: (context, isIndo, _) {
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                              fontSize: 42,
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
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Card Form
                    Container(
                      padding: const EdgeInsets.all(28),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageNotifier.tr(_isRegistering ? 'sign_up' : 'sign_in'),
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageNotifier.tr(_isRegistering ? 'register_desc' : 'login_desc'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name Input (Only for Register)
                          if (_isRegistering) ...[
                            Text(
                              LanguageNotifier.tr('username_label'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF2B2B2B),
                                hintText: LanguageNotifier.tr('username_hint'),
                                hintStyle: const TextStyle(color: Colors.white30),
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.white54, size: 20),
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
                            const SizedBox(height: 18),
                          ],

                          // Email Input
                          Text(
                            LanguageNotifier.tr('email'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF2B2B2B),
                              hintText: LanguageNotifier.tr('email_hint'),
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54, size: 20),
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
                          const SizedBox(height: 18),

                          // Password Input
                          Text(
                            LanguageNotifier.tr('password'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF2B2B2B),
                              hintText: '••••••••',
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
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
                          const SizedBox(height: 16),

                          // Checkbox & Help (Hanya saat Sign In)
                          if (!_isRegistering) ...[
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: const Color(0xFFE50914),
                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      LanguageNotifier.tr('remember_me'),
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: _showForgotPasswordDialog,
                                      child: Text(
                                        LanguageNotifier.tr('forgot_password'),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFE50914),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Text('•', style: TextStyle(color: Colors.white24, fontSize: 12)),
                                    TextButton(
                                      onPressed: _showHelpModal,
                                      child: Text(
                                        LanguageNotifier.tr('need_help'),
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ] else
                            const SizedBox(height: 10),

                          // Login/Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE50914),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      LanguageNotifier.tr(_isRegistering ? 'btn_register' : 'btn_signin'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider ATAU
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.white12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  LanguageNotifier.tr('or_divider'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white38,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Colors.white12)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                foregroundColor: Colors.white,
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const _GoogleLogoIcon(size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          LanguageNotifier.tr(_isRegistering ? 'google_signup' : 'google_signin'),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle Register/Login
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegistering = !_isRegistering;
                                  if (_isRegistering) {
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _nameController.clear();
                                  } else {
                                    _passwordController.clear();
                                    _loadLastEmail();
                                  }
                                });
                              },
                              child: Text(
                                LanguageNotifier.tr(_isRegistering ? 'toggle_login' : 'toggle_register'),
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Netflix Home $_appVersion Edition',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Language Toggle Button
          Positioned(
            top: 48,
            right: 24,
            child: InkWell(
              onTap: () {
                LanguageNotifier.isIndonesian.value = !LanguageNotifier.isIndonesian.value;
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      LanguageNotifier.isIndonesian.value ? 'ID' : 'EN',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD BOTTOM SHEET WITH OTP & NEW PASSWORD
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final ValueChanged<String> onSuccess;

  const _ForgotPasswordSheet({
    required this.initialEmail,
    required this.onSuccess,
  });

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  int _step = 0; // 0 = Enter Email, 1 = Enter OTP & New Password
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  String _cleanError(dynamic error) {
    final str = error.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
    if (str.contains('rate limit') || str.contains('over_email_send_rate_limit')) {
      return 'Terlalu sering meminta OTP. Harap tunggu beberapa saat sebelum mencoba lagi.';
    }
    if (str.contains('otp_expired') || str.contains('Token has expired') || str.contains('invalid')) {
      return 'Kode OTP tidak valid atau sudah kadaluarsa. Silakan periksa kembali.';
    }
    if (str.contains('User not found')) {
      return 'Email akun tidak ditemukan.';
    }
    return str;
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Masukkan alamat email yang valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.sendPasswordResetOtp(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 1;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  Future<void> _handleVerifyAndUpdate() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode OTP verifikasi.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Kata sandi baru minimal 6 karakter.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verified = await SupabaseService.verifyPasswordResetOtp(email, otp);
      if (!verified) {
        throw Exception('Kode OTP tidak valid atau telah kadaluarsa.');
      }

      await SupabaseService.updatePassword(newPass);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess(email);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  Future<void> _contactAdminWhatsApp() async {
    final email = _emailController.text.trim();
    final message = 'Halo Admin, saya mengalami kendala lupa kata sandi akun Netflix Tools (Email: ${email.isNotEmpty ? email : "-"}). Mohon bantuannya.';
    final url = Uri.parse('https://wa.me/6282268426070?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFFE50914), width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: bottomInset + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _step == 0
                          ? const Color(0xFFE50914).withValues(alpha: 0.15)
                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _step == 0 ? const Color(0xFFE50914) : const Color(0xFF10B981),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _step == 0 ? Icons.lock_reset : Icons.mark_email_read_outlined,
                      color: _step == 0 ? const Color(0xFFE50914) : const Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0
                              ? LanguageNotifier.tr('reset_password')
                              : 'Verifikasi OTP & Sandi Baru',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _step == 0
                              ? 'Kirim kode OTP pemulihan ke email'
                              : 'Masukkan 6 digit kode dari email Anda',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error Banner
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // STEP 0: Input Email
              if (_step == 0) ...[
                Text(
                  LanguageNotifier.tr('enter_email_for_otp'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  LanguageNotifier.tr('email'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    hintText: LanguageNotifier.tr('email_hint'),
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54, size: 20),
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
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            LanguageNotifier.tr('send_otp'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],

              // STEP 1: Enter OTP & New Password
              if (_step == 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${LanguageNotifier.tr('otp_sent_to')} ${_emailController.text.trim()}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _step = 0),
                        child: Text(
                          'Ubah',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFE50914),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // OTP Field
                Text(
                  'Kode OTP (6 Digit)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.firaCode(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    hintText: '••••••',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // New Password Field
                Text(
                  LanguageNotifier.tr('new_password'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    hintText: 'Minimal 6 karakter',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
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
                const SizedBox(height: 14),

                // Confirm Password Field
                Text(
                  LanguageNotifier.tr('confirm_password'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    hintText: 'Ulangi kata sandi baru',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
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
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyAndUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            LanguageNotifier.tr('save_new_password'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend OTP Row
                Center(
                  child: _resendCooldown > 0
                      ? Text(
                          'Kirim ulang kode dalam ${_resendCooldown}s',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        )
                      : TextButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
                          child: Text(
                            'Belum menerima kode? Kirim Ulang',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFE50914),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),

              // WhatsApp Support Fallback
              Center(
                child: TextButton.icon(
                  onPressed: _contactAdminWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 16),
                  label: Text(
                    'Kendala email? Hubungi Admin via WhatsApp',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF25D366),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRISP MULTI-COLOR GOOGLE LOGO ICON
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogoIcon extends StatelessWidget {
  final double size;
  const _GoogleLogoIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: CustomPaint(
        size: Size(size - 4, size - 4),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = radius * 0.42;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Red (top arc)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -3.14159 * 0.75, 3.14159 * 0.5, false, paint);

    // Yellow (left-bottom arc)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.14159 * 1.25, 3.14159 * 0.5, false, paint);

    // Green (bottom arc)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.14159 * 0.25, 3.14159 * 0.5, false, paint);

    // Blue (right arc)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -3.14159 * 0.25, 3.14159 * 0.5, false, paint);

    // Horizontal bar of G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w / 2, h / 2 - strokeWidth / 2, radius, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



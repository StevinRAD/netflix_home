import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/supabase_service.dart';
import '../utils/language_notifier.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isRegistering = false;
  String _appVersion = 'v...';

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
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
      final displayName = _isRegistering ? name : (email.split('@').first);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFFE50914), size: 24),
            const SizedBox(width: 10),
            Text(
              LanguageNotifier.tr('help_center'),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageNotifier.tr('customer_service'),
                        style: GoogleFonts.inter(color: const Color(0xFF46D369), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LanguageNotifier.tr('help_desc'),
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final text = 'Halo Admin Netflix Home, saya butuh bantuan login';
                          final waUrl = Uri.parse('https://wa.me/6282268426070?text=${Uri.encodeComponent(text)}');
                          final waAppUrl = Uri.parse('whatsapp://send?phone=6282268426070&text=${Uri.encodeComponent(text)}');
                          try {
                            if (await canLaunchUrl(waAppUrl)) {
                              await launchUrl(waAppUrl, mode: LaunchMode.externalApplication);
                            } else {
                              await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                            }
                          } catch (_) {
                            await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: Text(LanguageNotifier.tr('contact_admin')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(LanguageNotifier.tr('login_guide_title'), style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(LanguageNotifier.tr('login_guide_1'), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                Text(LanguageNotifier.tr('login_guide_2'), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                Text(LanguageNotifier.tr('login_guide_3'), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageNotifier.tr('close'), style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
        ],
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
                                TextButton(
                                  onPressed: _showHelpModal,
                                  child: Text(
                                    LanguageNotifier.tr('need_help'),
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                                  ),
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


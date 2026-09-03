import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _checkFirstTimeAndNavigate();
  }

  Future<void> _checkFirstTimeAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      _navigate(const OnboardingScreen());
      return;
    }

    final sessionEmail = prefs.getString('session_email');
    if (sessionEmail != null) {
      final isValid = await SupabaseService.validateSession();
      if (!mounted) return;
      
      if (isValid) {
        final displayName = sessionEmail.split('@').first;
        _navigate(MainScreen(username: displayName));
      } else {
        await SupabaseService.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi telah berakhir atau Anda login di perangkat lain.'),
            backgroundColor: Colors.orange,
          ),
        );
        _navigate(const LoginScreen());
      }
    } else {
      _navigate(const LoginScreen());
    }
  }

  void _navigate(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Icon/Logo
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE50914).withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'N',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 85,
                            color: const Color(0xFFE50914),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Title
                    Text(
                      'NETFLIX HOME',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 38,
                        color: const Color(0xFFE50914),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Netflix Account Login Manager',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFF2B2B2B),
                        color: Color(0xFFE50914),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

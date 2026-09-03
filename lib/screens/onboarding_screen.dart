import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../utils/language_notifier.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isViewOnly;
  const OnboardingScreen({super.key, this.isViewOnly = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> get _onboardingData => LanguageNotifier.isIndonesian.value
      ? [
          {
            "title": "Selamat Datang di Netflix Home",
            "desc": "Kelola semua akun Netflix Anda dengan mudah dalam satu aplikasi yang praktis dan elegan.",
            "icon": "devices"
          },
          {
            "title": "Cek Keaktifan Otomatis",
            "desc": "Ketahui status akun Anda, periksa paket, dan buat link login ke berbagai device hanya dengan satu klik.",
            "icon": "check_circle"
          },
          {
            "title": "Login Mudah & Cepat",
            "desc": "Gunakan QR Code atau buka langsung di browser Anda untuk masuk ke Netflix tanpa ribet.",
            "icon": "qr_code_scanner"
          },
        ]
      : [
          {
            "title": "Welcome to Netflix Home",
            "desc": "Manage all your Netflix accounts easily in one practical and elegant app.",
            "icon": "devices"
          },
          {
            "title": "Auto Status Check",
            "desc": "Know your account status, check plans, and create login links to various devices with just one click.",
            "icon": "check_circle"
          },
          {
            "title": "Easy & Fast Login",
            "desc": "Use QR Code or open directly in your browser to log into Netflix without hassle.",
            "icon": "qr_code_scanner"
          },
        ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (!mounted) return;
    if (widget.isViewOnly) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'devices':
        return Icons.devices;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'qr_code_scanner':
        return Icons.qr_code_scanner;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIcon(_onboardingData[index]['icon']!),
                          size: 120,
                          color: const Color(0xFFE50914),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _onboardingData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _onboardingData[index]['desc']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFE50914)
                              : (isDark ? Colors.grey[800] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? (LanguageNotifier.isIndonesian.value ? 'Mulai Gunakan' : 'Get Started')
                            : (LanguageNotifier.isIndonesian.value ? 'Selanjutnya' : 'Next'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage != _onboardingData.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        LanguageNotifier.isIndonesian.value ? 'Lewati' : 'Skip',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Spacer to match height
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

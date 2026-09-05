import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import '../utils/language_notifier.dart';
import 'accounts_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: LanguageNotifier.isIndonesian,
      builder: (context, isIndo, _) {
        return ShowCaseWidget(
          builder: (context) => PopScope(
            canPop: _currentIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_currentIndex != 0) {
                setState(() => _currentIndex = 0);
              }
            },
            child: Scaffold(
              body: [
                DashboardScreen(
                  username: widget.username,
                  onNavigateToAccounts: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
                AccountsScreen(
                  username: widget.username,
                  onBack: () {
                    setState(() => _currentIndex = 0);
                  },
                ),
                ProfileScreen(username: widget.username),
              ][_currentIndex],
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey[900]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                  selectedItemColor: const Color(0xFFE50914),
                  unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
                  selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home),
                      label: LanguageNotifier.tr('home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.movie_filter_outlined),
                      activeIcon: const Icon(Icons.movie_filter),
                      label: LanguageNotifier.tr('account_list'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person),
                      label: LanguageNotifier.tr('profile_settings').split(' ')[0],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


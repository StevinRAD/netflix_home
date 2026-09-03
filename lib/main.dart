import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetflixHomeApp());
}

class NetflixHomeApp extends StatelessWidget {
  const NetflixHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Netflix Home',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF141414),
            primaryColor: const Color(0xFFE50914),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE50914),
              secondary: Color(0xFFE50914),
              surface: Color(0xFF1F1F1F),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1F1F1F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            useMaterial3: true,
          ),
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F5F7),
            primaryColor: const Color(0xFFE50914),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE50914),
              secondary: Color(0xFFE50914),
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: IconThemeData(color: Colors.black87),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

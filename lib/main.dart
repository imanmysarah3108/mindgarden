import 'package:flutter/material.dart';
import 'package:mindgarden/screens/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_page.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mjldmelaqwluohwgzfbu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1qbGRtZWxhcXdsdW9od2d6ZmJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA0Mzc1ODEsImV4cCI6MjA2NjAxMzU4MX0.y1RLbT61jnf9RswXrfD_ebVnVWU3mAFeZ7XSYdsAjw4',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme pastelColorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFADD8E6),
      onPrimary: Colors.black87,
      primaryContainer: Color(0xFFC2E3EF),
      onPrimaryContainer: Colors.black87,
      secondary: Color(0xFFFFC0CB),
      onSecondary: Colors.black87,
      secondaryContainer: Color(0xFFF0D9E0),
      onSecondaryContainer: Colors.black87,
      tertiary: Color(0xFFDDA0DD),
      onTertiary: Colors.black87,
      tertiaryContainer: Color(0xFFE9C5E9),
      onTertiaryContainer: Colors.black87,
      error: Color(0xFFFF7F7F),
      onError: Colors.white,
      errorContainer: Color(0xFFFFE0E0),
      onErrorContainer: Colors.black87,
      background: Color(0xFFF5F5DC),
      onBackground: Colors.black87,
      surface: Color(0xFFFFFFFF),
      onSurface: Colors.black87,
      surfaceVariant: Color(0xFFE0E0E0),
      onSurfaceVariant: Colors.black87,
      outline: Color(0xFFA0A0A0),
      shadow: Colors.black12,
      inverseSurface: Color(0xFF303030),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF6B9EA8),
      surfaceTint: Color(0xFFADD8E6),
    );

    return MaterialApp(
      title: 'Daily Diary',
      theme: ThemeData(
        colorScheme: pastelColorScheme,
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: pastelColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: pastelColorScheme.primaryContainer,
          elevation: 1,
          iconTheme: IconThemeData(color: pastelColorScheme.onPrimaryContainer),
          titleTextStyle: GoogleFonts.poppins(
            color: pastelColorScheme.onPrimaryContainer,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pastelColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pastelColorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pastelColorScheme.primary, width: 2),
          ),
        ),
      ),
      home: StreamBuilder(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
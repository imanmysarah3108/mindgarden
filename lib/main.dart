import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'screens/home_page.dart';
import 'screens/login_page.dart';

// Entry point for the Mind Garden app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase initialization
  await Supabase.initialize(
    url: 'https://mjldmelaqwluohwgzfbu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1qbGRtZWxhcXdsdW9od2d6ZmJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA0Mzc1ODEsImV4cCI6MjA2NjAxMzU4MX0.y1RLbT61jnf9RswXrfD_ebVnVWU3mAFeZ7XSYdsAjw4',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  runApp(const MyApp());
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

// Main app widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// State class for MyApp, manages theme and authentication state
class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  // Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // Toggle theme mode and save to SharedPreferences
  void _toggleTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }
// Build method for MyApp
  @override
  Widget build(BuildContext context) {
    // Define light color scheme
    final ColorScheme pastelColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF2E7D32), 
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFA5D6A7),
      onPrimaryContainer: const Color(0xFF1B5E20),
      secondary: const Color(0xFFFFD600),
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFFFFECB3),
      onSecondaryContainer: const Color(0xFF795900),
      tertiary: const Color(0xFF66BB6A),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFC8E6C9),
      onTertiaryContainer: const Color(0xFF2E7D32),
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFCDD2),
      onErrorContainer: const Color(0xFFB71C1C),
      background: const Color(0xFFF5F5F5),
      onBackground: const Color(0xFF333333),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF333333),
      surfaceVariant: const Color(0xFFEEEEEE),
      onSurfaceVariant: const Color(0xFF666666),
      outline: const Color(0xFFCCCCCC),
      shadow: Colors.black12,
      inverseSurface: const Color(0xFF121212),
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFA5D6A7),
      surfaceTint: const Color(0xFF2E7D32),
    );

    // Define dark color scheme
    final ColorScheme darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFFA5D6A7), 
      onPrimary: const Color(0xFF1B5E20),
      primaryContainer: const Color(0xFF388E3C),
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFFFFF176),
      onSecondary: const Color(0xFF3E3E00),
      secondaryContainer: const Color(0xFFBFAF60),
      onSecondaryContainer: Colors.black,
      tertiary: const Color(0xFFB2DFDB),
      onTertiary: const Color(0xFF004D40),
      tertiaryContainer: const Color(0xFF4DB6AC),
      onTertiaryContainer: Colors.white,
      error: const Color(0xFFE57373),
      onError: Colors.black,
      errorContainer: const Color.fromARGB(255, 155, 26, 119),
      onErrorContainer: Colors.white,
      background: const Color(0xFF1A1A1A),
      onBackground: const Color(0xFFE0E0E0),
      surface: const Color(0xFF242424),
      onSurface: const Color(0xFFE0E0E0),
      surfaceVariant: const Color(0xFF3A3A3A),
      onSurfaceVariant: const Color(0xFFBDBDBD),
      outline: const Color(0xFF707070),
      shadow: Colors.black54,
      inverseSurface: const Color(0xFFEAEAEA),
      onInverseSurface: const Color(0xFF1A1A1A),
      inversePrimary: const Color(0xFF66BB6A),
      surfaceTint: const Color(0xFFA5D6A7),
    );

    // Main MaterialApp
    return MaterialApp(
      title: 'Mind Garden',
      themeMode: _themeMode, // Use the current theme mode
      theme: ThemeData(
        colorScheme: pastelColorScheme, // Use pastelColorScheme here
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
            borderSide: BorderSide(color: pastelColorScheme.outline.withOpacity(0.8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pastelColorScheme.outline.withOpacity(0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pastelColorScheme.primary, width: 2),
          ),
        ),
        cardColor: pastelColorScheme.surface,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: darkColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primaryContainer,
          elevation: 1,
          iconTheme: IconThemeData(color: darkColorScheme.onPrimaryContainer),
          titleTextStyle: GoogleFonts.poppins(
            color: darkColorScheme.onPrimaryContainer,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.outline.withOpacity(0.8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.outline.withOpacity(0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
          ),
        ),
        cardColor: darkColorScheme.surface,
      ),
      // Use StreamBuilder to listen for authentication state changes
      home: StreamBuilder(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, authSnapshot) {
          if (authSnapshot.hasData && supabase.auth.currentSession != null) {
            return HomePage(toggleTheme: _toggleTheme);
          }
          return const LoginPage(); // Always start with LoginPage if not authenticated
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

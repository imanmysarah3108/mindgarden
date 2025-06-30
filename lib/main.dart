import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme pastelColorScheme = ColorScheme(
          brightness: Brightness.light,
          // Primary Greens
          primary: const Color(0xFF2E7D32),       // Dark Green (Logo)
          onPrimary: Colors.white,                // White text/icons
          primaryContainer: const Color(0xFFA5D6A7), // Light Green
          onPrimaryContainer: const Color(0xFF1B5E20), // Dark Green text

          // Secondary Yellows
          secondary: const Color(0xFFFFD600),     // Vibrant Yellow (Logo)
          onSecondary: Colors.black,              // Black text
          secondaryContainer: const Color(0xFFFFECB3), // Light Yellow
          onSecondaryContainer: const Color(0xFF795900), // Dark Yellow text

          // Tertiary Greens
          tertiary: const Color(0xFF66BB6A),      // Mid Green (Logo)
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFC8E6C9),
          onTertiaryContainer: const Color(0xFF2E7D32),

          // Error States
          error: const Color(0xFFD32F2F),         // Standard Red
          onError: Colors.white,
          errorContainer: const Color(0xFFFFCDD2),
          onErrorContainer: const Color(0xFFB71C1C),

          // Background/Surface - Adjusted for better differentiation
          background: const Color.fromARGB(255, 255, 231, 231),               // Slightly off-white background
          onBackground: const Color(0xFF333333), // Dark Gray text
          surface: const Color(0xFFFFFFFF), // Pure white for cards/surfaces to stand out
          onSurface: const Color(0xFF333333),
          surfaceVariant: const Color(0xFFEEEEEE), // Light Gray for subtle variations
          onSurfaceVariant: const Color(0xFF666666),

          // Other
          outline: const Color(0xFFCCCCCC),       // Borders
          shadow: Colors.black12,
          inverseSurface: const Color(0xFF121212),
          onInverseSurface: Colors.white,
          inversePrimary: const Color(0xFFA5D6A7),
          surfaceTint: const Color(0xFF2E7D32),
        );

    return MaterialApp(
      title: 'Mind Garden',
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
        // Explicitly set cardColor to ensure it uses the desired surface color
        cardColor: pastelColorScheme.surface,
      ),
      home: StreamBuilder(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.hasData && supabase.auth.currentSession != null) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

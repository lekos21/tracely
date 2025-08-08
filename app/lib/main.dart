import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TraceLyApp());
}

class TraceLyApp extends StatelessWidget {
  const TraceLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracely - Relationship Intelligence',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B73FF), // Modern purple-blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700, // Bold for large displays
            color: const Color(0xFF1A1A1A), // Dark gray instead of black
          ),
          displayMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w600, // Semi-bold
            color: const Color(0xFF1A1A1A),
          ),
          displaySmall: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
          headlineLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
          headlineMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
          headlineSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2A2A2A),
          ),
          titleLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
          titleMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w500, // Medium weight
            color: const Color(0xFF2A2A2A),
          ),
          titleSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2A2A),
          ),
          bodyLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w500, // Medium weight for body
            color: const Color(0xFF2A2A2A),
          ),
          bodyMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w400, // Regular weight
            color: const Color(0xFF3A3A3A),
          ),
          bodySmall: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4A4A4A),
          ),
          labelLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2A2A),
          ),
          labelMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3A3A3A),
          ),
          labelSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}



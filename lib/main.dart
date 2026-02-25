import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.initialize();
  } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, InventoryProvider>(
          create: (_) => InventoryProvider(),
          update: (_, auth, inventory) {
            inventory?.setUserId(auth.currentUser?.id);
            return inventory!;
          },
        ),
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  static ThemeData _buildTheme({required bool dark}) {
    const primary = Color(0xFF1152D4);
    final surface = dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = dark ? const Color(0xFF1E293B) : Colors.white;
    final brightness = dark ? Brightness.dark : Brightness.light;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: surface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.interTextTheme(
          dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: dark ? Colors.white : const Color(0xFF0D1B3E),
        ),
        iconTheme: IconThemeData(
            color: dark ? Colors.white : const Color(0xFF0D1B3E)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
              color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
              color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(
            color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        hintStyle: TextStyle(
            color: dark ? const Color(0xFF64748B) : const Color(0xFFADB5C7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(dark: false),
      darkTheme: _buildTheme(dark: true),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated) {
      return const MainScreen();
    }

    if (auth.hasExistingUsers) {
      return const LoginScreen();
    }

    return const WelcomeScreen();
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1152D4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
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

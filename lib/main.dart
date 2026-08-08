// lib/main.dart
import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

// APIs
import 'api/client.dart';
import 'api/auth_api.dart';
import 'api/auth_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
  final api = ApiClient.dev();
  final auth = AuthApi(api);
  final storage = api.storage;

  
 
  Widget start;
  final hasStoredSession = await _hasStoredSession(storage);
  if (!hasStoredSession) {
    start = const OnboardingScreen();
  } else {
    try {
      await auth.getMe();
      start = const HomeScreen();
    } catch (_) {
      final stillSignedIn = await _hasStoredSession(storage);
      start = stillSignedIn ? const HomeScreen() : const OnboardingScreen();
    }
  }

  runApp(MyApp(start: start));
}

Future<bool> _hasStoredSession(AuthStorage storage) async {
  final access = await storage.access;
  final refresh = await storage.refresh;
  return (access != null && access.isNotEmpty) ||
      (refresh != null && refresh.isNotEmpty);
}

class MyApp extends StatelessWidget {
  final Widget start;
  const MyApp({super.key, required this.start});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        useMaterial3: true,
      ),
      home: start,
    );
  }
}

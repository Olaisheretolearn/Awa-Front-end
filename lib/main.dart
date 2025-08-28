// lib/main.dart
import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

// APIs
import 'api/client.dart';
import 'api/auth_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
  final api = ApiClient.dev();
  final auth = AuthApi(api);

  
 
  Widget start;
  try {
    await auth.getMe();
    start = const HomeScreen();
  } catch (_) {
    start = const OnboardingScreen();
  }

  runApp(MyApp(start: start));
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

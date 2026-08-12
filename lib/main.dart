// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';

import 'api/session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.primaryBlue,
        ),
        useMaterial3: true,
      ),
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  final _session = SessionController.instance;

  @override
  void initState() {
    super.initState();
    _session.addListener(_handleSessionChange);
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    _session.removeListener(_handleSessionChange);
    super.dispose();
  }

  void _handleSessionChange() {
    if (!mounted) return;
    final wasInvalidated = _session.takeInvalidation();
    setState(() {});
    if (!wasInvalidated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    });
  }

  Future<void> _restoreSession() async {
    try {
      await _session.restore();
    } catch (_) {
      // Secure storage must never prevent the app from opening.
      if (mounted) {
        await _session.markSignedOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = _session.hasStoredSession;
    if (hasSession == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return hasSession ? const HomeScreen() : const OnboardingScreen();
  }
}

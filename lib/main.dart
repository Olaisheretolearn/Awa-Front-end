import 'dart:async';

import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'navigation/room_required_route.dart';
import 'screens/create_join_flat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pick_avatar_screen.dart';
import 'state/app_flow_controller.dart';
import 'state/app_flow_state.dart';
import 'state/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.controller});

  final AppFlowController? controller;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppFlowController _controller;
  late final bool _ownsController;
  late _RootDestination _lastDestination;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppFlowController();
    _lastDestination = _destinationFor(_controller.status);
    _controller.addListener(_handleFlowChange);
    unawaited(_controller.bootstrap());
  }

  @override
  void dispose() {
    _controller.removeListener(_handleFlowChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleFlowChange() {
    final nextDestination = _destinationFor(_controller.status);
    if (nextDestination == _lastDestination) return;
    _lastDestination = nextDestination;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
        home: const _AppFlowGate(),
      ),
    );
  }
}

enum _RootDestination {
  loading,
  signedOut,
  profileSetup,
  roomSetup,
  room,
  error
}

_RootDestination _destinationFor(AppFlowStatus status) {
  switch (status) {
    case AppFlowStatus.initializing:
    case AppFlowStatus.resolving:
      return _RootDestination.loading;
    case AppFlowStatus.signedOut:
      return _RootDestination.signedOut;
    case AppFlowStatus.profileSetupRequired:
      return _RootDestination.profileSetup;
    case AppFlowStatus.roomSetupRequired:
      return _RootDestination.roomSetup;
    case AppFlowStatus.roomReady:
      return _RootDestination.room;
    case AppFlowStatus.error:
      return _RootDestination.error;
  }
}

class _AppFlowGate extends StatelessWidget {
  const _AppFlowGate();

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.watch(context);
    switch (flow.status) {
      case AppFlowStatus.initializing:
      case AppFlowStatus.resolving:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AppFlowStatus.signedOut:
        return const OnboardingScreen();
      case AppFlowStatus.profileSetupRequired:
        return const AvatarSelectionScreen();
      case AppFlowStatus.roomSetupRequired:
        return const CreateJoinFlatScreen();
      case AppFlowStatus.roomReady:
        return RoomRequired(
          builder: (_, roomSession) => HomeScreen(roomSession: roomSession),
        );
      case AppFlowStatus.error:
        return const _StartupErrorScreen();
    }
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen();

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We could not load your account right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: flow.resolveAuthenticatedState,
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: flow.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

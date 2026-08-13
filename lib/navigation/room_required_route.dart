import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../state/app_flow_state.dart';
import '../state/app_scope.dart';

typedef RoomWidgetBuilder = Widget Function(
  BuildContext context,
  RoomSession roomSession,
);

class RoomRequired extends StatelessWidget {
  const RoomRequired({super.key, required this.builder});

  final RoomWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.watch(context);
    final roomSession = flow.roomSession;
    if (roomSession != null) {
      return builder(context, roomSession);
    }

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
                  'Create or join a room to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Go to room setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoomRequiredRoute {
  const RoomRequiredRoute._();

  static Route<T> build<T>(RoomWidgetBuilder builder) {
    return MaterialPageRoute<T>(
      builder: (context) => RoomRequired(builder: builder),
    );
  }
}

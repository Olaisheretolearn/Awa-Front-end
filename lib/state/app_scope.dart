import 'package:flutter/widgets.dart';

import 'app_flow_controller.dart';

class AppScope extends InheritedNotifier<AppFlowController> {
  const AppScope({
    super.key,
    required AppFlowController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppFlowController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this context.');
    return scope!.notifier!;
  }

  static AppFlowController read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'No AppScope found above this context.');
    return scope!.notifier!;
  }
}

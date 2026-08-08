// lib/utils/ui_helpers.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../api/app_error.dart';

const defaultErrorMessage = 'Looks like something happened. Please try again.';

void showSnack(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

String extractMsg(Object err) {
  if (err is DioException) {
    return friendlyMessage(mapDioError(err));
  }
  return defaultErrorMessage;
}

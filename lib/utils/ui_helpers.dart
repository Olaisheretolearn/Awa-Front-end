// lib/utils/ui_helpers.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void showSnack(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

String extractMsg(DioException e) {
  try {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'];
    }
  } catch (_) {}
  return e.message ?? 'Network error';
}

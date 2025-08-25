import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CurrencyStore {
  static final ValueNotifier<String> symbol = ValueNotifier<String>('\$');

  static const _kKey = 'currency_symbol';

  static Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    symbol.value = sp.getString(_kKey) ?? '\$';
  }

  static Future<void> set(String s) async {
    symbol.value = s;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, s);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage(this._preferences);

  static Future<AppStorage> create() async {
    return AppStorage(await SharedPreferences.getInstance());
  }

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _cartKey = 'cart.items';

  final SharedPreferences _preferences;

  String? get accessToken => _preferences.getString(_accessTokenKey);
  String? get refreshToken => _preferences.getString(_refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _preferences.setString(_accessTokenKey, accessToken);
    await _preferences.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearSession() async {
    await _preferences.remove(_accessTokenKey);
    await _preferences.remove(_refreshTokenKey);
  }

  List<Map<String, dynamic>> readCart() {
    final rawCart = _preferences.getString(_cartKey);
    if (rawCart == null) return const [];
    try {
      final decoded = jsonDecode(rawCart);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCart(List<Map<String, dynamic>> items) async {
    await _preferences.setString(_cartKey, jsonEncode(items));
  }
}

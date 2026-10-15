import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  AppStorage(this._preferences);

  static Future<AppStorage> create() async {
    return AppStorage(await SharedPreferences.getInstance());
  }

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _userKey = 'auth.user';
  static const _cartKey = 'cart.items';
  static const _menuCacheKey = 'menu.cache';
  static const _themeModeKey = 'settings.theme_mode';
  static const _privacyConsentKey = 'privacy.consent_accepted';

  final SharedPreferences _preferences;
  static const _secureStorage = FlutterSecureStorage();
  static const _savedEmailKey = 'auth.saved_email';
  static const _savedPasswordKey = 'auth.saved_password';

  Future<Map<String, String>?> readSavedCredentials() async {
    final email = await _secureStorage.read(key: _savedEmailKey);
    final password = await _secureStorage.read(key: _savedPasswordKey);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  Future<void> saveCredentials(
      {required String email, required String password}) async {
    await _secureStorage.write(key: _savedEmailKey, value: email.trim());
    await _secureStorage.write(key: _savedPasswordKey, value: password);
  }

  Future<void> clearSavedCredentials() async {
    await _secureStorage.delete(key: _savedEmailKey);
    await _secureStorage.delete(key: _savedPasswordKey);
  }

  String? get accessToken => _preferences.getString(_accessTokenKey);
  String? get refreshToken => _preferences.getString(_refreshTokenKey);
  Map<String, dynamic>? get cachedUser {
    final rawUser = _preferences.getString(_userKey);
    if (rawUser == null) return null;
    try {
      final decoded = jsonDecode(rawUser);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String? get themeMode => _preferences.getString(_themeModeKey);
  bool get privacyConsentAccepted =>
      _preferences.getBool(_privacyConsentKey) ?? false;

  Future<void> saveThemeMode(String mode) async {
    await _preferences.setString(_themeModeKey, mode);
  }

  Future<void> savePrivacyConsentAccepted() async {
    await _preferences.setBool(_privacyConsentKey, true);
  }

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    await _preferences.setString(_accessTokenKey, accessToken);
    await _preferences.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _preferences.setString(_userKey, jsonEncode(user));
  }

  Future<void> clearSession() async {
    await _preferences.remove(_accessTokenKey);
    await _preferences.remove(_refreshTokenKey);
    await _preferences.remove(_userKey);
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

  Map<String, dynamic>? readMenuCache() {
    final rawCache = _preferences.getString(_menuCacheKey);
    if (rawCache == null) return null;
    try {
      final decoded = jsonDecode(rawCache);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMenuCache({
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> products,
  }) async {
    await _preferences.setString(
      _menuCacheKey,
      jsonEncode({'categories': categories, 'products': products}),
    );
  }
}

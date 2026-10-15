import 'package:flutter/material.dart';

import '../storage/app_storage.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._storage);

  static const timezone = 'America/Sao_Paulo';

  final AppStorage _storage;
  ThemeMode themeMode = ThemeMode.system;
  bool privacyConsentAccepted = false;

  Future<void> initialize() async {
    final storedTheme = _storage.themeMode;
    themeMode = switch (storedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    privacyConsentAccepted = _storage.privacyConsentAccepted;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _storage.saveThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }

  Future<void> acceptPrivacyConsent() async {
    privacyConsentAccepted = true;
    await _storage.savePrivacyConsentAccepted();
    notifyListeners();
  }
}

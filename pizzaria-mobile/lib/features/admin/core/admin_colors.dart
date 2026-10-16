import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

abstract final class AdminColors {
  static const primary = AppTheme.primary;
  static const primaryPressed = AppTheme.primaryPressed;
  static const accent = AppTheme.accent;
  static const surface = AppTheme.surface;
  static const cardSurface = AppTheme.cardSurface;
  static const textPrimary = AppTheme.textPrimary;
  static const textSecondary = AppTheme.textSecondary;

  static const success = Color(0xFF147D4F);
  static const successSurface = Color(0xFFE8F6EF);
  static const info = Color(0xFF1769AA);
  static const infoSurface = Color(0xFFE8F1FB);
  static const warning = Color(0xFF9A5B00);
  static const warningSurface = Color(0xFFFFF3D6);
  static const danger = Color(0xFFB3261E);
  static const dangerSurface = Color(0xFFFDE9E7);
  static const neutral = Color(0xFF5F6368);
  static const neutralSurface = Color(0xFFF0F1F2);
}

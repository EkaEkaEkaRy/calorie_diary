import 'package:flutter/material.dart';

final ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.light,

  /// Основной цвет — Green 500
  primary: const Color(0xFF4CAF50),
  onPrimary: const Color(0xFFFFFFFF),

  primaryContainer: const Color(0xFFC8E6C9),
  onPrimaryContainer: const Color(0xFF002105),

  /// Второстепенный цвет — Amber (из вашего secondary)
  secondary: const Color(0xFFFFC107),
  onSecondary: const Color(0xFF000000),

  secondaryContainer: const Color(0xFFFFECB3),
  onSecondaryContainer: const Color(0xFF261900),

  /// Акцентный/нейтральный
  tertiary: const Color(0xFF386567),
  onTertiary: const Color(0xFFFFFFFF),
  tertiaryContainer: const Color(0xFFBCEBEB),
  onTertiaryContainer: const Color(0xFF002021),

  /// Ошибки
  error: const Color(0xFFBA1A1A),
  onError: const Color(0xFFFFFFFF),
  errorContainer: const Color(0xFFFFDAD6),
  onErrorContainer: const Color(0xFF410002),

  /// Цвет фона / поверхности
  surface: const Color(0xFFF1F8E9), // Ваш background
  onSurface: const Color(0xFF191D17), // Выбранный fontColor (почти черный)
  onSurfaceVariant: const Color(0xFF74796D), // Выбранный fontHidden

  surfaceContainer: const Color(0xFFFFFFFF),
  surfaceContainerHighest: const Color(0xFFE1EADD),
);

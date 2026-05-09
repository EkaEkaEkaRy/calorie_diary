import 'package:flutter/material.dart';

abstract class AppTextStyle {
  static const String fontFamily = 'Lato';

  // Базовые стили (константы)
  static const TextStyle style40w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style36w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style32w600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle style32w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style28w800 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle style28w600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle style28w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style24w700 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle style24w600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle style24w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style20w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style20w600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle style18w700 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle style18w600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle style18w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style16w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style16w600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle style14w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle style12w400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Метод адаптации
  static TextStyle _apply(TextStyle style, BuildContext context) {
    // Ваша логика scaleFactor
    double width = MediaQuery.of(context).size.width;
    double scaleFactor = width < 600 ? 0.8 : (width < 1200 ? 1.0 : 1.2);

    final textScaler = MediaQuery.of(context).textScaler;
    final scaledSize = textScaler.scale(style.fontSize! * scaleFactor);

    return style.copyWith(
      fontSize: scaledSize.clamp(style.fontSize! * 0.8, style.fontSize! * 1.6),
    );
  }
}

// РАСШИРЕНИЕ: Вот это позволит писать context.style40w400
extension AppThemeExtension on BuildContext {
  TextStyle get style40w400 =>
      AppTextStyle._apply(AppTextStyle.style40w400, this);
  TextStyle get style36w400 =>
      AppTextStyle._apply(AppTextStyle.style36w400, this);
  TextStyle get style32w600 =>
      AppTextStyle._apply(AppTextStyle.style32w600, this);
  TextStyle get style32w400 =>
      AppTextStyle._apply(AppTextStyle.style32w400, this);
  TextStyle get style28w800 =>
      AppTextStyle._apply(AppTextStyle.style28w800, this);
  TextStyle get style28w600 =>
      AppTextStyle._apply(AppTextStyle.style28w600, this);
  TextStyle get style28w400 =>
      AppTextStyle._apply(AppTextStyle.style28w400, this);
  TextStyle get style24w700 =>
      AppTextStyle._apply(AppTextStyle.style24w700, this);
  TextStyle get style24w600 =>
      AppTextStyle._apply(AppTextStyle.style24w600, this);
  TextStyle get style24w400 =>
      AppTextStyle._apply(AppTextStyle.style24w400, this);
  TextStyle get style20w400 =>
      AppTextStyle._apply(AppTextStyle.style20w400, this);
  TextStyle get style20w600 =>
      AppTextStyle._apply(AppTextStyle.style20w600, this);
  TextStyle get style18w400 =>
      AppTextStyle._apply(AppTextStyle.style18w400, this);
  TextStyle get style18w700 =>
      AppTextStyle._apply(AppTextStyle.style18w700, this);
  TextStyle get style18w600 =>
      AppTextStyle._apply(AppTextStyle.style18w600, this);
  TextStyle get style16w400 =>
      AppTextStyle._apply(AppTextStyle.style16w400, this);
  TextStyle get style16w600 =>
      AppTextStyle._apply(AppTextStyle.style16w600, this);
  TextStyle get style14w400 =>
      AppTextStyle._apply(AppTextStyle.style14w400, this);
  TextStyle get style12w400 =>
      AppTextStyle._apply(AppTextStyle.style12w400, this);
}

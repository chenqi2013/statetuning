import 'package:flutter/material.dart';

/// Picks app [Locale] from the OS: English, Simplified Chinese, or Traditional Chinese.
/// Any other language falls back to English.
Locale resolveAppLocale(Locale? device) {
  if (device == null) return const Locale('en', 'US');
  final lang = device.languageCode.toLowerCase();
  if (lang != 'zh') return const Locale('en', 'US');

  final country = device.countryCode?.toUpperCase() ?? '';
  if (country == 'TW' || country == 'HK' || country == 'MO') {
    return const Locale('zh', 'TW');
  }
  final script = device.scriptCode;
  if (script == 'Hant') return const Locale('zh', 'TW');

  return const Locale('zh', 'CN');
}

/// Locales with full UI strings in [AppTranslations].
const List<Locale> kAppSupportedLocales = [
  Locale('en', 'US'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];

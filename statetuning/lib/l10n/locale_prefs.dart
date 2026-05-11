import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

class LocalePrefs {
  static const String _key = 'app_locale';

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _localeTag(locale));
  }

  static Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeTag = prefs.getString(_key);
    if (localeTag == null || localeTag.isEmpty) return null;

    final parts = localeTag.split('_');
    final saved = parts.length > 1
        ? Locale(parts[0], parts[1])
        : Locale(parts[0]);

    for (final supported in kAppSupportedLocales) {
      if (_sameLocale(saved, supported)) return supported;
    }
    return null;
  }

  static String _localeTag(Locale locale) =>
      '${locale.languageCode}_${locale.countryCode ?? ''}';

  static bool _sameLocale(Locale a, Locale b) =>
      a.languageCode == b.languageCode &&
      (a.countryCode ?? '') == (b.countryCode ?? '');
}

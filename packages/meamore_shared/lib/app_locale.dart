import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale {
  AppLocale._();

  static const supported = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  static const _prefsKey = 'app_locale_language_code';

  static final ValueNotifier<Locale> overrideLocale = ValueNotifier<Locale>(const Locale('en'));

  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_prefsKey);

    if (code == 'he') {
      overrideLocale.value = const Locale('he');
    } else {
      overrideLocale.value = const Locale('en');
    }
  }

  static Future<void> setEnglish() =>
      setLocale(const Locale('en'));

  static Future<void> setHebrew() =>
      setLocale(const Locale('he'));

  static Future<void> toggle() async {
    final current =
        overrideLocale.value?.languageCode ?? 'en';
    await setLocale(
      current == 'he' ? const Locale('en') : const Locale('he'),
    );
  }

  static Future<void> setLocale(Locale value) async {
    if (value.languageCode != 'en' &&
        value.languageCode != 'he') {
      value = const Locale('en');
    }

    overrideLocale.value = value;

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefsKey, value.languageCode);
  }
}

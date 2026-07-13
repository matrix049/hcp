import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages the app supports.
enum AppLanguage {
  fr,
  ar;

  String get code => name;
  Locale get locale => Locale(code);
  bool get isRtl => this == AppLanguage.ar;

  static AppLanguage fromCode(String? code) =>
      code == 'ar' ? AppLanguage.ar : AppLanguage.fr;
}

/// Holds the selected UI language and persists it locally (survives restarts
/// and logout). Defaults to French; loads the saved choice on startup.
class LocaleController extends Notifier<AppLanguage> {
  static const _prefsKey = 'app_language';

  @override
  AppLanguage build() {
    _load();
    return AppLanguage.fr;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null) state = AppLanguage.fromCode(code);
    } catch (_) {
      // No prefs available (e.g. in tests) — keep the default.
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (_) {
      // Persisting failed — the in-memory choice still applies this session.
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLanguage>(LocaleController.new);

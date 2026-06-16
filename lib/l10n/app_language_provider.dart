import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageProvider extends ChangeNotifier {
  static const _prefsKey = 'edunest_language_code';
  static const vietnamese = Locale('vi');
  static const english = Locale('en');
  static const supportedLocales = [vietnamese, english];

  final SharedPreferences _prefs;
  Locale _locale;

  AppLanguageProvider({required SharedPreferences prefs})
      : _prefs = prefs,
        _locale = Locale(_normalize(prefs.getString(_prefsKey)));

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isVietnamese => languageCode == 'vi';

  Future<void> setLanguageCode(String languageCode) async {
    final normalized = _normalize(languageCode);
    if (_locale.languageCode == normalized) return;

    _locale = Locale(normalized);
    notifyListeners();
    await _prefs.setString(_prefsKey, normalized);
  }

  Future<void> toggleLanguage() {
    return setLanguageCode(isVietnamese ? 'en' : 'vi');
  }

  static String _normalize(String? languageCode) {
    return languageCode == 'en' ? 'en' : 'vi';
  }
}

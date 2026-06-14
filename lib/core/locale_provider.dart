import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama dilini yönetir ve cihazda persist eder.
///
/// `locale == null` → cihazın sistem dili kullanılır (MaterialApp,
/// `supportedLocales` listesine göre çözer).
class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'app_locale';

  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
  ];

  Locale? _locale;
  Locale? get locale => _locale;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale? newLocale) async {
    if (_locale?.languageCode == newLocale?.languageCode) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, newLocale.languageCode);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isBengali = false;
  static const String _languageKey = 'language_is_bengali';

  bool get isBengali => _isBengali;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBengali = prefs.getBool(_languageKey) ?? false;
      notifyListeners();
    } catch (e) {
      // If there's an error loading preferences, default to English
      _isBengali = false;
    }
  }

  Future<void> _saveLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_languageKey, _isBengali);
    } catch (e) {
      // Handle error silently - preference won't be saved but app will continue
    }
  }

  Future<void> setBengali() async {
    if (_isBengali != true) {
      _isBengali = true;
      notifyListeners();
      await _saveLanguagePreference();
    }
  }

  Future<void> setEnglish() async {
    if (_isBengali != false) {
      _isBengali = false;
      notifyListeners();
      await _saveLanguagePreference();
    }
  }

  Future<void> toggleLanguage() async {
    _isBengali = !_isBengali;
    notifyListeners();
    await _saveLanguagePreference();
  }
}
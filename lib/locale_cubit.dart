import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en')) {
    // Load saved language preference when initialized
    _loadSavedLanguage();
  }

  // Load the saved language preference from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isArabic = prefs.getBool('isArabic') ?? false;
      
      // Emit the saved locale
      if (isArabic) {
        emit(const Locale('ar'));
      } else {
        emit(const Locale('en'));
      }
    } catch (e) {
      // If there's an error, default to English
      emit(const Locale('en'));
    }
  }

  // Save language preference and emit new locale
  Future<void> _saveLanguagePreference(bool isArabic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isArabic', isArabic);
    } catch (e) {
      // Handle error silently
      print('Error saving language preference: $e');
    }
  }

  // Switch to English
  Future<void> switchToEnglish() async {
    await _saveLanguagePreference(false);
    emit(const Locale('en'));
  }

  // Switch to Arabic
  Future<void> switchToArabic() async {
    await _saveLanguagePreference(true);
    emit(const Locale('ar'));
  }
}

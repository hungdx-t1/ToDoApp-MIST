import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = false; // def: sáng

  // Getter
  bool get isDarkMode => _isDarkMode;

  // key để lưu trong SharedPreferences
  static const String _themeKey = "is_dark_mode";

  ThemeViewModel() {
    _loadThemeFromPrefs(); // load cài đặt ngay khi khởi tạo
  }

  // func đổi giao diện (được gọi từ nút switch)
  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners(); // Báo cho toàn bộ app biết để vẽ lại màu

    final prefs = await SharedPreferences.getInstance(); // lưu lại vào máy
    await prefs.setBool(_themeKey, isOn);
  }

  // func load cài đặt cũ
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false; // def false nếu chưa lưu
    notifyListeners();
  }
}
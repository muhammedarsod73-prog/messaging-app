import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage;

  bool _isDarkMode = true;
  late ChatWallpaperStyle _wallpaperStyle;
  late bool _isPasscodeEnabled;
  late String _passcode;
  late bool _isStealthMode;
  late int _notificationMode;

  ThemeProvider(this._storage) {
    _wallpaperStyle = _storage.getWallpaperStyle();
    _isPasscodeEnabled = _storage.isPasscodeEnabled();
    _passcode = _storage.getPasscode();
    _isStealthMode = _storage.isStealthMode();
    _notificationMode = _storage.getNotificationMode();
  }

  bool get isDarkMode => _isDarkMode;
  ChatWallpaperStyle get wallpaperStyle => _wallpaperStyle;
  bool get isPasscodeEnabled => _isPasscodeEnabled;
  String get passcode => _passcode;
  bool get isStealthMode => _isStealthMode;
  int get notificationMode => _notificationMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> setWallpaperStyle(ChatWallpaperStyle style) async {
    _wallpaperStyle = style;
    await _storage.setWallpaperStyle(style);
    notifyListeners();
  }

  Future<void> setPasscodeEnabled(bool enabled) async {
    _isPasscodeEnabled = enabled;
    await _storage.setPasscodeEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPasscode(String newPasscode) async {
    _passcode = newPasscode;
    await _storage.setPasscode(newPasscode);
    notifyListeners();
  }

  Future<void> setStealthMode(bool enabled) async {
    _isStealthMode = enabled;
    await _storage.setStealthMode(enabled);
    notifyListeners();
  }

  Future<void> setNotificationMode(int mode) async {
    _notificationMode = mode;
    await _storage.setNotificationMode(mode);
    notifyListeners();
  }
}

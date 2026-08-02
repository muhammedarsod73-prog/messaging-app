import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class LocalStorageService {
  static const String _keyCurrentUserId = 'current_user_id';
  static const String _keyPairCode = 'pair_code';
  static const String _keyPartnerName = 'partner_name';
  static const String _keyWallpaperStyle = 'wallpaper_style';
  static const String _keyPasscode = 'app_passcode';
  static const String _keyPasscodeEnabled = 'app_passcode_enabled';
  static const String _keyStealthMode = 'stealth_mode';
  static const String _keyMessagesCache = 'messages_cache';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // User & Pair Code
  String getCurrentUserId() => _prefs.getString(_keyCurrentUserId) ?? 'user_a';
  Future<void> setCurrentUserId(String id) async => await _prefs.setString(_keyCurrentUserId, id);

  String getPairCode() => _prefs.getString(_keyPairCode) ?? 'DUO2026';
  Future<void> setPairCode(String code) async => await _prefs.setString(_keyPairCode, code);

  String getPartnerName() => _prefs.getString(_keyPartnerName) ?? 'My Favorite Person';
  Future<void> setPartnerName(String name) async => await _prefs.setString(_keyPartnerName, name);

  // Wallpaper
  ChatWallpaperStyle getWallpaperStyle() {
    final index = _prefs.getInt(_keyWallpaperStyle) ?? ChatWallpaperStyle.whatsappDark.index;
    return ChatWallpaperStyle.values[index.clamp(0, ChatWallpaperStyle.values.length - 1)];
  }

  Future<void> setWallpaperStyle(ChatWallpaperStyle style) async {
    await _prefs.setInt(_keyWallpaperStyle, style.index);
  }

  // Passcode Security
  bool isPasscodeEnabled() => _prefs.getBool(_keyPasscodeEnabled) ?? false;
  Future<void> setPasscodeEnabled(bool enabled) async => await _prefs.setBool(_keyPasscodeEnabled, enabled);

  String getPasscode() => _prefs.getString(_keyPasscode) ?? '1234';
  Future<void> setPasscode(String code) async => await _prefs.setString(_keyPasscode, code);

  // Stealth & Notification Mode
  bool isStealthMode() => _prefs.getBool(_keyStealthMode) ?? true;
  Future<void> setStealthMode(bool enabled) async => await _prefs.setBool(_keyStealthMode, enabled);

  // 0 = Discrete ("💬 New message"), 1 = Full Text, 2 = Off
  int getNotificationMode() => _prefs.getInt('notification_mode') ?? 0;
  Future<void> setNotificationMode(int mode) async => await _prefs.setInt('notification_mode', mode);

  // Cache Messages locally for offline speed
  List<MessageModel> getCachedMessages() {
    final raw = _prefs.getString(_keyMessagesCache);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedMessages(List<MessageModel> messages) async {
    final rawList = messages.map((m) => m.toJson()).toList();
    await _prefs.setString(_keyMessagesCache, jsonEncode(rawList));
  }
}

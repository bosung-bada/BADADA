import 'package:shared_preferences/shared_preferences.dart';

class SafetySettingsService {
  static const String _autoSosEnabledKey = 'auto_sos_enabled';

  static Future<bool> isAutoSosEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSosEnabledKey) ?? true;
  }

  static Future<void> setAutoSosEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSosEnabledKey, enabled);
  }
}
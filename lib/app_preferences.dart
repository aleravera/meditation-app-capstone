import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralizes the three persistent settings required by the storage lab.
class AppPreferences {
  static const themeModeKey = 'themeMode';
  static const notificationsEnabledKey = 'notificationsEnabled';
  static const reminderTimeKey = 'reminderTime';

  static const defaultThemeMode = 'Light';
  static const defaultNotificationsEnabled = true;
  static const defaultReminderTime = '08:00';

  static Future<void> saveThemeMode(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(themeModeKey, value);
  }

  static Future<String> readThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(themeModeKey) ?? defaultThemeMode;
  }

  static Future<ThemeMode> readFlutterThemeMode() async {
    return await readThemeMode() == 'Dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> saveNotificationsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(notificationsEnabledKey, value);
  }

  static Future<bool> readNotificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(notificationsEnabledKey) ??
        defaultNotificationsEnabled;
  }

  static Future<void> saveReminderTime(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(reminderTimeKey, value);
  }

  static Future<String> readReminderTime() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(reminderTimeKey) ?? defaultReminderTime;
  }

  AppPreferences._();
}

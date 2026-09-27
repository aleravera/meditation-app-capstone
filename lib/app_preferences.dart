import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralizes the persistent settings required by the storage labs.
class AppPreferences {
  static const themeModeKey = 'themeMode';
  static const notificationsEnabledKey = 'notificationsEnabled';
  static const reminderTimeKey = 'reminderTime';
  static const onboardingCompletedKey = 'onboardingCompleted';

  static const defaultThemeMode = 'Light';
  static const defaultNotificationsEnabled = true;
  static const defaultReminderTime = '08:00';
  static const defaultOnboardingCompleted = false;

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

  static Future<void> saveOnboardingCompleted(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(onboardingCompletedKey, value);
  }

  static Future<bool> readOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(onboardingCompletedKey) ??
        defaultOnboardingCompleted;
  }

  AppPreferences._();
}

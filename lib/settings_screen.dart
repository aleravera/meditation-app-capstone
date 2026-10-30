import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'personal_info_screen.dart';
import 'preferences_form.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeModeChanged});

  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = AppPreferences.defaultThemeMode;
  bool _notificationsEnabled = AppPreferences.defaultNotificationsEnabled;
  String _reminderTime = AppPreferences.defaultReminderTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Restores every setting from SharedPreferences when this screen opens.
  Future<void> _loadSettings() async {
    final themeMode = await AppPreferences.readThemeMode();
    final notificationsEnabled =
        await AppPreferences.readNotificationsEnabled();
    final reminderTime = await AppPreferences.readReminderTime();

    if (!mounted) return;
    setState(() {
      _themeMode = themeMode;
      _notificationsEnabled = notificationsEnabled;
      _reminderTime = reminderTime;
      _isLoading = false;
    });
  }

  Future<void> _changeTheme(String? value) async {
    if (value == null) return;
    setState(() => _themeMode = value);
    await AppPreferences.saveThemeMode(value);
    widget.onThemeModeChanged(
      value == 'Dark' ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> _changeNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await AppPreferences.saveNotificationsEnabled(value);
  }

  Future<void> _selectReminderTime() async {
    final selectedTime = await pickReminderTime(context, _reminderTime);
    if (selectedTime == null || !mounted) return;
    setState(() => _reminderTime = selectedTime);
    await AppPreferences.saveReminderTime(selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('settingsScreen'),
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const Key('personalInfoSettingsTile'),
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Personal Info'),
                    subtitle: const Text('Update your profile information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your choices are saved locally on this device.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                PreferencesForm(
                  keyPrefix: 'settings',
                  themeMode: _themeMode,
                  notificationsEnabled: _notificationsEnabled,
                  reminderTime: _reminderTime,
                  onThemeChanged: _changeTheme,
                  onNotificationsChanged: _changeNotifications,
                  onReminderTimeTap: _selectReminderTime,
                ),
              ],
            ),
    );
  }
}

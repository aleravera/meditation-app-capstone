import 'package:flutter/material.dart';

import 'app_preferences.dart';

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
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime == null || !mounted) return;

    final formattedTime =
        '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';
    setState(() => _reminderTime = formattedTime);
    await AppPreferences.saveReminderTime(formattedTime);
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      key: const Key('themeModeDropdown'),
                      initialValue: _themeMode,
                      decoration: const InputDecoration(
                        labelText: 'Theme Mode',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Light', child: Text('Light')),
                        DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                      ],
                      onChanged: _changeTheme,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    key: const Key('notificationsSwitch'),
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    subtitle: Text(
                      _notificationsEnabled ? 'Enabled' : 'Disabled',
                    ),
                    value: _notificationsEnabled,
                    onChanged: _changeNotifications,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const Key('reminderTimeTile'),
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Reminder Time'),
                    subtitle: const Text('Daily meditation reminder'),
                    trailing: Text(
                      _reminderTime,
                      key: const Key('reminderTimeValue'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: _selectReminderTime,
                  ),
                ),
              ],
            ),
    );
  }
}

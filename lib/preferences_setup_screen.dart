import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'preferences_form.dart';

class PreferencesSetupScreen extends StatefulWidget {
  const PreferencesSetupScreen({super.key, required this.onThemeModeChanged});

  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<PreferencesSetupScreen> createState() => _PreferencesSetupScreenState();
}

class _PreferencesSetupScreenState extends State<PreferencesSetupScreen> {
  String _themeMode = AppPreferences.defaultThemeMode;
  bool _notificationsEnabled = AppPreferences.defaultNotificationsEnabled;
  String _reminderTime = AppPreferences.defaultReminderTime;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Existing values become the initial choices if they were set previously.
  Future<void> _loadPreferences() async {
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

  Future<void> _selectReminderTime() async {
    final selectedTime = await pickReminderTime(context, _reminderTime);
    if (selectedTime == null || !mounted) return;
    setState(() => _reminderTime = selectedTime);
  }

  Future<void> _confirmPreferences() async {
    setState(() => _isSaving = true);

    await AppPreferences.saveThemeMode(_themeMode);
    await AppPreferences.saveNotificationsEnabled(_notificationsEnabled);
    await AppPreferences.saveReminderTime(_reminderTime);
    await AppPreferences.saveOnboardingCompleted(true);

    if (!mounted) return;
    widget.onThemeModeChanged(
      _themeMode == 'Dark' ? ThemeMode.dark : ThemeMode.light,
    );
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('preferencesSetupScreen'),
      appBar: AppBar(title: const Text('Set Up Preferences')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 58,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Make the app yours',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your initial meditation preferences.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                PreferencesForm(
                  keyPrefix: 'setup',
                  themeMode: _themeMode,
                  notificationsEnabled: _notificationsEnabled,
                  reminderTime: _reminderTime,
                  onThemeChanged: (value) {
                    if (value != null) setState(() => _themeMode = value);
                  },
                  onNotificationsChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  onReminderTimeTap: _selectReminderTime,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('confirmPreferencesButton'),
                  onPressed: _isSaving ? null : _confirmPreferences,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save and Continue'),
                ),
              ],
            ),
    );
  }
}

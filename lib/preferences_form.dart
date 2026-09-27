import 'package:flutter/material.dart';

/// Shared preference controls used by both onboarding and Settings.
class PreferencesForm extends StatelessWidget {
  const PreferencesForm({
    super.key,
    required this.keyPrefix,
    required this.themeMode,
    required this.notificationsEnabled,
    required this.reminderTime,
    required this.onThemeChanged,
    required this.onNotificationsChanged,
    required this.onReminderTimeTap,
  });

  final String keyPrefix;
  final String themeMode;
  final bool notificationsEnabled;
  final String reminderTime;
  final ValueChanged<String?> onThemeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onReminderTimeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              key: Key('${keyPrefix}ThemeModeDropdown'),
              initialValue: themeMode,
              decoration: const InputDecoration(
                labelText: 'Theme Mode',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Light', child: Text('Light')),
                DropdownMenuItem(value: 'Dark', child: Text('Dark')),
              ],
              onChanged: onThemeChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            key: Key('${keyPrefix}NotificationsSwitch'),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: Text(notificationsEnabled ? 'Enabled' : 'Disabled'),
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            key: Key('${keyPrefix}ReminderTimeTile'),
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Reminder Time'),
            subtitle: const Text('Daily meditation reminder'),
            trailing: Text(
              reminderTime,
              key: Key('${keyPrefix}ReminderTimeValue'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onReminderTimeTap,
          ),
        ),
      ],
    );
  }
}

/// Opens the same time picker from onboarding and Settings.
Future<String?> pickReminderTime(
  BuildContext context,
  String currentValue,
) async {
  final parts = currentValue.split(':');
  final initialTime = TimeOfDay(
    hour: int.tryParse(parts.first) ?? 8,
    minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
  final selectedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );
  if (selectedTime == null) return null;

  return '${selectedTime.hour.toString().padLeft(2, '0')}:'
      '${selectedTime.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'browser_notification_service_stub.dart'
    if (dart.library.js_interop) 'browser_notification_service_web.dart';
import 'preferences_form.dart';

typedef TestNotificationSender = Future<BrowserNotificationResult> Function();

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.testNotificationSender});

  final TestNotificationSender? testNotificationSender;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _meditations = [
    'Mindful Breathing',
    'Body Scan Meditation',
    'Deep Focus',
  ];
  static const _times = ['Morning', 'Afternoon', 'Evening'];

  final _selectedMeditations = <String>{};
  final _selectedTimes = <String>{};
  bool _notificationsEnabled = AppPreferences.defaultNotificationsEnabled;
  String _reminderTime = AppPreferences.defaultReminderTime;
  bool _isLoading = true;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final notificationsEnabled =
        await AppPreferences.readNotificationsEnabled();
    final selectedMeditations =
        await AppPreferences.readNotificationMeditations();
    final selectedTimes = await AppPreferences.readNotificationTimes();
    final reminderTime = await AppPreferences.readReminderTime();

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _selectedMeditations
        ..clear()
        ..addAll(selectedMeditations.where(_meditations.contains));
      _selectedTimes
        ..clear()
        ..addAll(selectedTimes.where(_times.contains));
      _reminderTime = reminderTime;
      _isLoading = false;
    });
  }

  Future<void> _saveNotificationSettings({bool showFeedback = true}) async {
    await AppPreferences.saveNotificationsEnabled(_notificationsEnabled);
    await AppPreferences.saveNotificationMeditations(
      _meditations.where(_selectedMeditations.contains).toList(),
    );
    await AppPreferences.saveNotificationTimes(
      _times.where(_selectedTimes.contains).toList(),
    );

    if (!mounted || !showFeedback) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings saved')),
    );
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _saveNotificationSettings();
  }

  Future<void> _toggleMeditation(String meditation, bool selected) async {
    setState(() {
      selected
          ? _selectedMeditations.add(meditation)
          : _selectedMeditations.remove(meditation);
    });
    await _saveNotificationSettings();
  }

  Future<void> _toggleTime(String time, bool selected) async {
    setState(() {
      selected ? _selectedTimes.add(time) : _selectedTimes.remove(time);
    });
    await _saveNotificationSettings();
  }

  Future<void> _selectReminderTime() async {
    final selectedTime = await pickReminderTime(context, _reminderTime);
    if (selectedTime == null || !mounted) return;

    await AppPreferences.saveReminderTime(selectedTime);
    if (!mounted) return;
    setState(() => _reminderTime = selectedTime);
    _showFeedback('Reminder time updated');
  }

  Future<void> _sendTestNotification() async {
    if (!_notificationsEnabled) {
      _showFeedback('Enable notifications first');
      return;
    }

    setState(() => _isSendingTest = true);
    final result =
        await (widget.testNotificationSender ??
            BrowserNotificationService().sendTestNotification)();
    if (!mounted) return;
    setState(() => _isSendingTest = false);

    switch (result) {
      case BrowserNotificationResult.sent:
        _showFeedback('Test notification sent');
        break;
      case BrowserNotificationResult.denied:
        _showFeedback('Notifications permission denied');
        break;
      case BrowserNotificationResult.unsupported:
        _showFeedback('Browser notifications are not supported');
        break;
      case BrowserNotificationResult.failed:
        _showFeedback('Unable to send test notification');
        break;
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('notificationsScreen'),
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: SwitchListTile(
                              key: const Key('enableNotificationsSwitch'),
                              secondary: const Icon(
                                Icons.notifications_active_outlined,
                              ),
                              title: const Text('Enable Notifications'),
                              subtitle: Text(
                                _notificationsEnabled
                                    ? 'Notifications are enabled'
                                    : 'Notifications are disabled',
                              ),
                              value: _notificationsEnabled,
                              onChanged: _setNotificationsEnabled,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Select Meditations for Notification',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _meditations
                                .map(
                                  (meditation) => FilterChip(
                                    key: Key(
                                      'notificationMeditation-$meditation',
                                    ),
                                    label: Text(meditation),
                                    selected: _selectedMeditations.contains(
                                      meditation,
                                    ),
                                    onSelected: (selected) =>
                                        _toggleMeditation(meditation, selected),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Select Times for Notification',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _times
                                .map(
                                  (time) => FilterChip(
                                    key: Key('notificationTime-$time'),
                                    label: Text(time),
                                    selected: _selectedTimes.contains(time),
                                    onSelected: (selected) =>
                                        _toggleTime(time, selected),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            child: ListTile(
                              key: const Key('notificationsReminderTimeTile'),
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('Daily Reminder Time'),
                              subtitle: const Text(
                                'Tap to change reminder time',
                              ),
                              trailing: Text(
                                _reminderTime,
                                key: const Key(
                                  'notificationsReminderTimeValue',
                                ),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              onTap: _selectReminderTime,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            key: const Key('sendTestNotificationButton'),
                            onPressed: _isSendingTest
                                ? null
                                : _sendTestNotification,
                            icon: _isSendingTest
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: const Text('Send Test Notification'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

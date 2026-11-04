import 'dart:async';
import 'dart:convert';

import 'package:capstone_auth_app/app_preferences.dart';
import 'package:capstone_auth_app/browser_notification_service_stub.dart';
import 'package:capstone_auth_app/country_list.dart';
import 'package:capstone_auth_app/main.dart';
import 'package:capstone_auth_app/notifications_screen.dart';
import 'package:capstone_auth_app/personal_info_screen.dart';
import 'package:capstone_auth_app/settings_screen.dart';
import 'package:capstone_auth_app/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> _loadTestCountries() async => ['France', 'Italy'];

Future<void> _selectTimeFromPicker(
  WidgetTester tester, {
  required Finder tile,
  required String currentMinute,
  required String hour,
  required String minute,
  required String period,
}) async {
  await Scrollable.ensureVisible(
    tester.element(tile),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();

  final timeFields = find.byType(TextField);
  final currentValues = tester
      .widgetList<TextField>(timeFields)
      .map((field) => field.controller?.text)
      .toList();
  final minuteIndex = currentValues.indexOf(currentMinute);
  expect(minuteIndex, isNot(-1));
  final hourIndex = minuteIndex == 0 ? 1 : 0;

  await tester.enterText(timeFields.at(hourIndex), hour);
  await tester.pump();
  await tester.enterText(timeFields.at(minuteIndex), minute);
  await tester.pump();
  expect(
    tester.widget<TextField>(timeFields.at(hourIndex)).controller?.text,
    hour,
  );
  expect(
    tester.widget<TextField>(timeFields.at(minuteIndex)).controller?.text,
    minute,
  );
  await tester.tap(find.text(period));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  expect(find.byType(TimePickerDialog), findsNothing);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Settings use defaults and persist all preference values', () async {
    expect(await AppPreferences.readThemeMode(), 'Light');
    expect(await AppPreferences.readNotificationsEnabled(), isTrue);
    expect(await AppPreferences.readReminderTime(), '08:00');
    expect(await AppPreferences.readOnboardingCompleted(), isFalse);
    expect(await AppPreferences.readNotificationMeditations(), isEmpty);
    expect(await AppPreferences.readNotificationTimes(), isEmpty);

    await AppPreferences.saveThemeMode('Dark');
    await AppPreferences.saveNotificationsEnabled(false);
    await AppPreferences.saveReminderTime('21:30');
    await AppPreferences.saveOnboardingCompleted(true);
    await AppPreferences.saveNotificationMeditations(['Deep Focus']);
    await AppPreferences.saveNotificationTimes(['Morning', 'Evening']);

    expect(await AppPreferences.readThemeMode(), 'Dark');
    expect(await AppPreferences.readFlutterThemeMode(), ThemeMode.dark);
    expect(await AppPreferences.readNotificationsEnabled(), isFalse);
    expect(await AppPreferences.readReminderTime(), '21:30');
    expect(await AppPreferences.readOnboardingCompleted(), isTrue);
    expect(await AppPreferences.readNotificationMeditations(), ['Deep Focus']);
    expect(await AppPreferences.readNotificationTimes(), [
      'Morning',
      'Evening',
    ]);
  });

  test('CountryService parses, deduplicates and sorts valid names', () async {
    final client = MockClient((request) async {
      expect(request.url.path, CountryService.endpoint.path);
      expect(request.url.queryParameters['response_fields'], 'names.common');
      expect(request.url.queryParameters['limit'], '100');
      expect(request.url.queryParameters['offset'], '0');
      expect(request.headers['Authorization'], 'Bearer test-key');
      return http.Response(
        jsonEncode({
          'data': {
            'objects': [
              {
                'names': {'common': 'Italy'},
              },
              {
                'names': {'common': 'France'},
              },
              {
                'names': {'common': 'Italy'},
              },
              {
                'names': {'common': null},
              },
              {'invalid': true},
            ],
            'meta': {'more': false},
          },
        }),
        200,
      );
    });

    final countries = await CountryService(
      client: client,
      apiKeyOverride: 'test-key',
    ).fetchCountries();
    expect(countries, ['France', 'Italy']);
  });

  test('CountryService rejects a missing API key before requesting', () async {
    final client = MockClient((_) async {
      fail('No request should be made without an API key');
    });

    expect(
      CountryService(client: client, apiKeyOverride: '').fetchCountries(),
      throwsA(isA<CountryServiceException>()),
    );
  });

  test('CountryService reports non-success status codes', () async {
    final client = MockClient((_) async => http.Response('Unavailable', 503));

    expect(
      CountryService(
        client: client,
        apiKeyOverride: 'test-key',
      ).fetchCountries(),
      throwsA(isA<CountryServiceException>()),
    );
  });

  testWidgets('Login is the initial screen and links to signup', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CapstoneAuthApp(countryLoader: _loadTestCountries),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('loginEmail')), findsOneWidget);
    expect(find.byKey(const Key('loginPassword')), findsOneWidget);

    await tester.tap(find.byKey(const Key('goToSignup')));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('goToLogin')));
    await tester.tap(find.byKey(const Key('goToLogin')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Signup rejects empty fields', (tester) async {
    await tester.pumpWidget(
      const CapstoneAuthApp(countryLoader: _loadTestCountries),
    );
    await tester.tap(find.byKey(const Key('goToSignup')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('signupButton')));
    await tester.tap(find.byKey(const Key('signupButton')));
    await tester.pump();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Country is required'), findsOneWidget);
  });

  testWidgets('Signup saves user and returns to login', (tester) async {
    await tester.pumpWidget(
      const CapstoneAuthApp(countryLoader: _loadTestCountries),
    );
    await tester.tap(find.byKey(const Key('goToSignup')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signupUsername')), 'Student');
    await tester.tap(find.byKey(const Key('signupCountry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italy').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signupEmail')),
      'student@example.com',
    );
    await tester.enterText(find.byKey(const Key('signupPassword')), 'secret');
    await tester.ensureVisible(find.byKey(const Key('signupButton')));
    await tester.tap(find.byKey(const Key('signupButton')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('username'), 'Student');
    expect(preferences.getString('email'), 'student@example.com');
    expect(preferences.getString('password'), 'secret');
    expect(preferences.getString('country'), 'Italy');
    expect(preferences.getBool(AppPreferences.onboardingCompletedKey), isFalse);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Signup shows country loading and handles API errors', (
    tester,
  ) async {
    final pendingCountries = Completer<List<String>>();
    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(countryLoader: () => pendingCountries.future),
      ),
    );
    await tester.pump();
    expect(find.text('Loading countries...'), findsOneWidget);

    pendingCountries.complete(['Italy']);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signupCountry')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(
          key: UniqueKey(),
          countryLoader: () async => throw Exception('network error'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load countries'), findsOneWidget);
    expect(find.byKey(const Key('retryCountriesButton')), findsOneWidget);
  });

  testWidgets('First login completes preferences onboarding before Home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'Student',
      'email': 'student@example.com',
      'password': 'secret',
    });
    await tester.pumpWidget(const CapstoneAuthApp());

    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'student@example.com',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('preferencesSetupScreen')), findsOneWidget);
    expect(find.text('Make the app yours'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('setupThemeModeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setupNotificationsSwitch')));
    await tester.tap(find.byKey(const Key('confirmPreferencesButton')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppPreferences.themeModeKey), 'Dark');
    expect(
      preferences.getBool(AppPreferences.notificationsEnabledKey),
      isFalse,
    );
    expect(preferences.getString(AppPreferences.reminderTimeKey), '08:00');
    expect(preferences.getBool(AppPreferences.onboardingCompletedKey), isTrue);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.byKey(const Key('homeAppLogo')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byKey(const Key('homeScreen')))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('Login opens Home with content, Detail, Drawer and logout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'Student',
      'email': 'student@example.com',
      'password': 'secret',
      AppPreferences.onboardingCompletedKey: true,
    });
    await tester.pumpWidget(const CapstoneAuthApp());

    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'student@example.com',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.text('Hello, Student!'), findsOneWidget);
    expect(find.text('Find your perfect meditation'), findsOneWidget);
    expect(find.text('Popular Meditations'), findsOneWidget);
    expect(find.text('Daily Meditation'), findsOneWidget);
    expect(find.text('Mindful Breathing'), findsOneWidget);
    expect(find.text('Body Scan Meditation'), findsOneWidget);
    expect(find.text('Deep Focus'), findsOneWidget);
    expect(find.byKey(const Key('homeFab')), findsOneWidget);
    expect(find.byKey(const Key('homeAppLogo')), findsOneWidget);
    final homeLogo = tester.widget<Image>(find.byKey(const Key('homeAppLogo')));
    expect(homeLogo.width, 36);
    expect(homeLogo.height, 36);
    expect(
      (homeLogo.image as AssetImage).assetName,
      'assets/images/app_logo.png',
    );
    expect(find.byKey(const Key('loginError')), findsNothing);

    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('meditation-Mindful Breathing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detailTitle')), findsOneWidget);
    expect(find.text('Mindful Breathing'), findsOneWidget);
    expect(find.text('Relaxation'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.byKey(const Key('detailDescription')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeDrawer')), findsOneWidget);
    expect(find.text('Hello, Student!'), findsWidgets);
    expect(find.byKey(const Key('drawerEmail')), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.byKey(const Key('drawerAccountSettingsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawerNotificationsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notificationsScreen')), findsOneWidget);
    expect(find.text('Enable Notifications'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawerReportsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reportsScreen')), findsOneWidget);
    expect(find.text('Reports coming soon'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawerAboutButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aboutScreen')), findsOneWidget);
    expect(find.text('About Mindful Moments'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOutButton')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('homeScreen')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'student@example.com',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
  });

  testWidgets('Login rejects incorrect credentials', (tester) async {
    SharedPreferences.setMockInitialValues({
      'email': 'student@example.com',
      'password': 'secret',
    });
    await tester.pumpWidget(const CapstoneAuthApp());

    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'wrong@example.com',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'wrong');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginError')), findsOneWidget);
    expect(find.text('Incorrect email or password'), findsWidgets);
  });

  testWidgets('Settings restore values and update theme and notifications', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'Student',
      'email': 'student@example.com',
      'password': 'secret',
      AppPreferences.themeModeKey: 'Dark',
      AppPreferences.notificationsEnabledKey: false,
      AppPreferences.reminderTimeKey: '21:30',
      AppPreferences.onboardingCompletedKey: true,
    });
    await tester.pumpWidget(
      const CapstoneAuthApp(initialThemeMode: ThemeMode.dark),
    );

    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'student@example.com',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    expect(find.byKey(const Key('personalInfoSettingsTile')), findsOneWidget);
    expect(find.text('21:30'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('settingsNotificationsSwitch')),
          )
          .value,
      isFalse,
    );
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settingsScreen'))),
      ).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const Key('personalInfoSettingsTile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personalInfoScreen')), findsOneWidget);
    expect(find.text('Personal Info'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settingsNotificationsSwitch')));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppPreferences.notificationsEnabledKey), isTrue);

    await tester.tap(find.byKey(const Key('settingsThemeModeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();
    expect(preferences.getString(AppPreferences.themeModeKey), 'Light');
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settingsScreen'))),
      ).brightness,
      Brightness.light,
    );
  });

  testWidgets('Personal Info loads, saves, and reloads all profile data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'name': 'Existing Name',
      'username': 'Student',
      'age': 31.0,
      'country': 'Italy',
    });

    await tester.pumpWidget(
      MaterialApp(home: PersonalInfoScreen(countryLoader: _loadTestCountries)),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('personalInfoName')))
          .controller
          ?.text,
      'Existing Name',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('personalInfoUsername')))
          .controller
          ?.text,
      'Student',
    );
    expect(find.text('Age: 31'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('personalInfoCountry')),
          )
          .initialValue,
      'Italy',
    );

    await tester.enterText(
      find.byKey(const Key('personalInfoName')),
      'Updated Name',
    );
    await tester.enterText(
      find.byKey(const Key('personalInfoUsername')),
      'UpdatedUser',
    );
    tester
        .widget<Slider>(find.byKey(const Key('personalInfoAgeSlider')))
        .onChanged
        ?.call(42);
    await tester.pump();
    await tester.tap(find.byKey(const Key('personalInfoCountry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('France').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('savePersonalInfoButton')));
    await tester.tap(find.byKey(const Key('savePersonalInfoButton')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('name'), 'Updated Name');
    expect(preferences.getString('username'), 'UpdatedUser');
    expect(preferences.getDouble('age'), 42);
    expect(preferences.getString('country'), 'France');
    expect(find.text('Profile updated successfully'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: PersonalInfoScreen(
          key: UniqueKey(),
          countryLoader: _loadTestCountries,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('personalInfoName')))
          .controller
          ?.text,
      'Updated Name',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('personalInfoUsername')))
          .controller
          ?.text,
      'UpdatedUser',
    );
    expect(find.text('Age: 42'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('personalInfoCountry')),
          )
          .initialValue,
      'France',
    );
  });

  testWidgets('Personal Info retries country loading after an API error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'country': 'Italy'});
    var attempts = 0;

    Future<List<String>> retryingCountryLoader() async {
      attempts++;
      if (attempts == 1) throw Exception('temporary API error');
      return ['France', 'Italy'];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: PersonalInfoScreen(countryLoader: retryingCountryLoader),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('personalInfoCountryError')), findsOneWidget);
    expect(find.text('Current country: Italy'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.byKey(const Key('retryPersonalInfoCountriesButton')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const Key('personalInfoCountry')), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('personalInfoCountry')),
          )
          .initialValue,
      'Italy',
    );
  });

  testWidgets('Notifications persist selections and handle test sending', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.notificationsEnabledKey: false,
      AppPreferences.reminderTimeKey: '07:30',
    });
    var sentNotifications = 0;

    Future<BrowserNotificationResult> sendTestNotification() async {
      sentNotifications++;
      return BrowserNotificationResult.sent;
    }

    Future<void> reveal(Finder finder) async {
      await Scrollable.ensureVisible(
        tester.element(finder),
        alignment: 0.5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(testNotificationSender: sendTestNotification),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('enableNotificationsSwitch')),
          )
          .value,
      isFalse,
    );
    expect(find.text('07:30'), findsOneWidget);

    await reveal(find.byKey(const Key('sendTestNotificationButton')));
    await tester.tap(find.byKey(const Key('sendTestNotificationButton')));
    await tester.pump();
    expect(find.text('Enable notifications first'), findsOneWidget);
    expect(sentNotifications, 0);

    await reveal(find.byKey(const Key('enableNotificationsSwitch')));
    await tester.tap(find.byKey(const Key('enableNotificationsSwitch')));
    await tester.pumpAndSettle();
    await reveal(
      find.byKey(const Key('notificationMeditation-Mindful Breathing')),
    );
    await tester.tap(
      find.byKey(const Key('notificationMeditation-Mindful Breathing')),
    );
    await tester.pumpAndSettle();
    await reveal(find.byKey(const Key('notificationMeditation-Deep Focus')));
    await tester.tap(
      find.byKey(const Key('notificationMeditation-Deep Focus')),
    );
    await tester.pumpAndSettle();
    await reveal(find.byKey(const Key('notificationTime-Morning')));
    await tester.tap(find.byKey(const Key('notificationTime-Morning')));
    await tester.pumpAndSettle();
    await reveal(find.byKey(const Key('notificationTime-Evening')));
    await tester.tap(find.byKey(const Key('notificationTime-Evening')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppPreferences.notificationsEnabledKey), isTrue);
    expect(
      preferences.getStringList(AppPreferences.notificationMeditationsKey),
      ['Mindful Breathing', 'Deep Focus'],
    );
    expect(preferences.getStringList(AppPreferences.notificationTimesKey), [
      'Morning',
      'Evening',
    ]);

    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('notificationsScreen'))),
    ).clearSnackBars();
    await reveal(find.byKey(const Key('sendTestNotificationButton')));
    await tester.tap(find.byKey(const Key('sendTestNotificationButton')));
    await tester.pumpAndSettle();
    expect(sentNotifications, 1);
    expect(find.text('Test notification sent'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          key: UniqueKey(),
          testNotificationSender: sendTestNotification,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('enableNotificationsSwitch')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const Key('notificationMeditation-Mindful Breathing')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const Key('notificationMeditation-Deep Focus')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('notificationTime-Morning')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('notificationTime-Evening')))
          .selected,
      isTrue,
    );

    await reveal(find.byKey(const Key('enableNotificationsSwitch')));
    await tester.tap(find.byKey(const Key('enableNotificationsSwitch')));
    await tester.pumpAndSettle();
    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('notificationsScreen'))),
    ).clearSnackBars();
    await reveal(find.byKey(const Key('sendTestNotificationButton')));
    await tester.tap(find.byKey(const Key('sendTestNotificationButton')));
    await tester.pump();
    expect(find.text('Enable notifications first'), findsOneWidget);
    expect(sentNotifications, 1);
  });

  testWidgets(
    'Reminder time stays synchronized between Notifications and Settings',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.reminderTimeKey: '07:30',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: true),
            child: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _selectTimeFromPicker(
        tester,
        tile: find.byKey(const Key('notificationsReminderTimeTile')),
        currentMinute: '30',
        hour: '6',
        minute: '30',
        period: 'PM',
      );

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(AppPreferences.reminderTimeKey), '18:30');
      expect(
        find.descendant(
          of: find.byKey(const Key('notificationsReminderTimeTile')),
          matching: find.text('18:30'),
        ),
        findsOneWidget,
      );
      expect(find.text('Reminder time updated'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: SettingsScreen(onThemeModeChanged: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('settingsReminderTimeTile')),
          matching: find.text('18:30'),
        ),
        findsOneWidget,
      );

      await _selectTimeFromPicker(
        tester,
        tile: find.byKey(const Key('settingsReminderTimeTile')),
        currentMinute: '30',
        hour: '9',
        minute: '00',
        period: 'PM',
      );
      expect(preferences.getString(AppPreferences.reminderTimeKey), '21:00');

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: NotificationsScreen(key: UniqueKey()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('notificationsReminderTimeTile')),
          matching: find.text('21:00'),
        ),
        findsOneWidget,
      );
    },
  );
}

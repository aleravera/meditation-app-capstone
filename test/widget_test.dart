import 'dart:async';
import 'dart:convert';

import 'package:capstone_auth_app/app_preferences.dart';
import 'package:capstone_auth_app/country_list.dart';
import 'package:capstone_auth_app/main.dart';
import 'package:capstone_auth_app/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> _loadTestCountries() async => ['France', 'Italy'];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Settings use defaults and persist all three values', () async {
    expect(await AppPreferences.readThemeMode(), 'Light');
    expect(await AppPreferences.readNotificationsEnabled(), isTrue);
    expect(await AppPreferences.readReminderTime(), '08:00');
    expect(await AppPreferences.readOnboardingCompleted(), isFalse);

    await AppPreferences.saveThemeMode('Dark');
    await AppPreferences.saveNotificationsEnabled(false);
    await AppPreferences.saveReminderTime('21:30');
    await AppPreferences.saveOnboardingCompleted(true);

    expect(await AppPreferences.readThemeMode(), 'Dark');
    expect(await AppPreferences.readFlutterThemeMode(), ThemeMode.dark);
    expect(await AppPreferences.readNotificationsEnabled(), isFalse);
    expect(await AppPreferences.readReminderTime(), '21:30');
    expect(await AppPreferences.readOnboardingCompleted(), isTrue);
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
    expect(find.byKey(const Key('loginError')), findsNothing);

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
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signOutButton')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
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
}

import 'package:capstone_auth_app/app_preferences.dart';
import 'package:capstone_auth_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Settings use defaults and persist all three values', () async {
    expect(await AppPreferences.readThemeMode(), 'Light');
    expect(await AppPreferences.readNotificationsEnabled(), isTrue);
    expect(await AppPreferences.readReminderTime(), '08:00');

    await AppPreferences.saveThemeMode('Dark');
    await AppPreferences.saveNotificationsEnabled(false);
    await AppPreferences.saveReminderTime('21:30');

    expect(await AppPreferences.readThemeMode(), 'Dark');
    expect(await AppPreferences.readFlutterThemeMode(), ThemeMode.dark);
    expect(await AppPreferences.readNotificationsEnabled(), isFalse);
    expect(await AppPreferences.readReminderTime(), '21:30');
  });

  testWidgets('Login is the initial screen and links to signup', (
    tester,
  ) async {
    await tester.pumpWidget(const CapstoneAuthApp());

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
    await tester.pumpWidget(const CapstoneAuthApp());
    await tester.tap(find.byKey(const Key('goToSignup')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signupButton')));
    await tester.pump();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Signup saves user and returns to login', (tester) async {
    await tester.pumpWidget(const CapstoneAuthApp());
    await tester.tap(find.byKey(const Key('goToSignup')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signupUsername')), 'Student');
    await tester.enterText(
      find.byKey(const Key('signupEmail')),
      'student@example.com',
    );
    await tester.enterText(find.byKey(const Key('signupPassword')), 'secret');
    await tester.tap(find.byKey(const Key('signupButton')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('username'), 'Student');
    expect(preferences.getString('email'), 'student@example.com');
    expect(preferences.getString('password'), 'secret');
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Login opens Home with content, Detail, Drawer and logout', (
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
          .widget<SwitchListTile>(find.byKey(const Key('notificationsSwitch')))
          .value,
      isFalse,
    );
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settingsScreen'))),
      ).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const Key('notificationsSwitch')));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppPreferences.notificationsEnabledKey), isTrue);

    await tester.tap(find.byKey(const Key('themeModeDropdown')));
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

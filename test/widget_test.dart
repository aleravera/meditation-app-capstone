import 'package:capstone_auth_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
}

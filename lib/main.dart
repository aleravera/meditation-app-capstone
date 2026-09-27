import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'preferences_setup_screen.dart';
import 'signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AppPreferences.readFlutterThemeMode();
  runApp(CapstoneAuthApp(initialThemeMode: savedThemeMode));
}

class CapstoneAuthApp extends StatefulWidget {
  const CapstoneAuthApp({super.key, this.initialThemeMode = ThemeMode.light});

  final ThemeMode initialThemeMode;

  @override
  State<CapstoneAuthApp> createState() => _CapstoneAuthAppState();
}

class _CapstoneAuthAppState extends State<CapstoneAuthApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _setThemeMode(ThemeMode themeMode) {
    setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Capstone Auth',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/preferences-setup': (_) =>
            PreferencesSetupScreen(onThemeModeChanged: _setThemeMode),
        '/home': (_) => HomeScreen(onThemeModeChanged: _setThemeMode),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';
import 'country_list.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.countryLoader});

  final CountryLoader? countryLoader;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  List<String> _countries = const [];
  String? _selectedCountry;
  String? _countryLoadError;
  bool _isLoadingCountries = true;
  bool _isLoading = false;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  // Loads real country names from REST Countries when Signup opens.
  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _countryLoadError = null;
    });

    try {
      final loader = widget.countryLoader ?? CountryService().fetchCountries;
      final countries = await loader();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
    } catch (_) {
      // Keep Signup usable and offer Retry instead of crashing on API errors.
      if (!mounted) return;
      setState(() {
        _countryLoadError = 'Unable to load countries';
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the highlighted fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('username', _usernameController.text.trim());
    await preferences.setString('email', _emailController.text.trim());
    await preferences.setString('password', _passwordController.text);
    await preferences.setString('country', _selectedCountry!);
    // A newly registered local account must complete first-access onboarding.
    await AppPreferences.saveOnboardingCompleted(false);

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created. You can now log in.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 54,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the fields below to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          key: const Key('signupUsername'),
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              _validateRequired(value, 'Username'),
                        ),
                        const SizedBox(height: 16),
                        _buildCountryField(),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('signupEmail'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('signupPassword'),
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) =>
                              _validateRequired(value, 'Password'),
                          onFieldSubmitted: (_) => _signUp(),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          key: const Key('signupButton'),
                          onPressed: _isLoading || _isLoadingCountries
                              ? null
                              : _signUp,
                          child: _isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign Up'),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              key: const Key('goToLogin'),
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryField() {
    if (_isLoadingCountries) {
      return Container(
        key: const Key('countryLoading'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 14),
            Expanded(child: Text('Loading countries...')),
          ],
        ),
      );
    }

    if (_countryLoadError != null) {
      return Container(
        key: const Key('countryError'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _countryLoadError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              key: const Key('retryCountriesButton'),
              onPressed: _loadCountries,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      key: const Key('signupCountry'),
      initialValue: _selectedCountry,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public),
      ),
      hint: const Text('Select your country'),
      items: _countries
          .map(
            (country) => DropdownMenuItem<String>(
              value: country,
              child: Text(country, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
      validator: (value) => value == null ? 'Country is required' : null,
    );
  }
}

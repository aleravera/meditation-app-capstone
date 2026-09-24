import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _loginError;
  bool _isLoading = false;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loginError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final preferences = await SharedPreferences.getInstance();
    final savedEmail = preferences.getString('email');
    final savedPassword = preferences.getString('password');

    if (!mounted) return;
    setState(() => _isLoading = false);

    final credentialsMatch =
        _emailController.text.trim() == savedEmail &&
        _passwordController.text == savedPassword;

    if (credentialsMatch) {
      // A valid login starts a fresh navigation stack on the Home screen.
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      setState(() => _loginError = 'Incorrect email or password');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
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
                          Icons.lock_outline_rounded,
                          size: 54,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your details to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF666B7A)),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          key: const Key('loginEmail'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('loginPassword'),
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        if (_loginError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            key: const Key('loginError'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _loginError!,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton(
                          key: const Key('loginButton'),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              key: const Key('goToSignup'),
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                              ),
                              child: const Text('Sign Up'),
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
}

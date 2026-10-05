import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/wording.dart';
import '../../widgets/logo.dart';
import 'sign_in_screen.dart';

/// Create an account (S11). The email address is not verified yet; that is future scope.
/// Closes itself once the account exists; the first-run acknowledgement (S8) is shown next.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.fromSignIn = false});

  /// True when opened from the sign-in screen, so "I already have an account" goes back instead of stacking.
  final bool fromSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).signIn(_email.text.trim(), _password.text, register: true);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSignIn() async {
    final navigator = Navigator.of(context);
    if (widget.fromSignIn) return navigator.pop();
    final signedIn = await navigator.push(MaterialPageRoute<bool>(builder: (_) => const SignInScreen(fromSignUp: true)));
    if (signedIn == true && mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget toggle() => IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          tooltip: _showPassword ? 'Hide password' : 'Show password',
          onPressed: () => setState(() => _showPassword = !_showPassword),
        );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(alignment: Alignment.centerLeft, child: AppLogo(size: 56, badge: true)),
                const SizedBox(height: 16),
                Text('Create account', style: text.headlineSmall),
                const SizedBox(height: 16),
                Text(recordsPrivate, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter your email address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 8 characters',
                    border: const OutlineInputBorder(),
                    suffixIcon: toggle(),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _again,
                  obscureText: !_showPassword,
                  decoration: const InputDecoration(labelText: 'Password again', border: OutlineInputBorder()),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : _submit, child: const Text('Create account')),
                const SizedBox(height: 8),
                TextButton(onPressed: _busy ? null : _openSignIn, child: const Text('I already have an account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/wording.dart';
import '../../widgets/logo.dart';
import 'sign_up_screen.dart';

/// Sign in to an existing account. Opened only when the visitor asks for it or starts
/// something that needs to know who they are (S11). Closes itself once signed in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.fromSignUp = false});

  /// True when opened from the sign-up screen, so "Create account" goes back instead of stacking.
  final bool fromSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).signIn(_email.text.trim(), _password.text, register: false);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSignUp() async {
    final navigator = Navigator.of(context);
    if (widget.fromSignUp) return navigator.pop();
    final created = await navigator.push(MaterialPageRoute<bool>(builder: (_) => const SignUpScreen(fromSignIn: true)));
    if (created == true && mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
                Text('Sign in', style: text.headlineSmall),
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
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      tooltip: _showPassword ? 'Hide password' : 'Show password',
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : _submit, child: const Text('Sign in')),
                const SizedBox(height: 8),
                TextButton(onPressed: _busy ? null : _openSignUp, child: const Text('Create account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

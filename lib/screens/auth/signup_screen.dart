import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../profile/legal_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService().register(
        firstName: _firstCtrl.text,
        lastName: _lastCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      await context.read<AppProvider>().setUser(user);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/goals', (_) => false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Takes 30 seconds. Then we build your plan.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              if (_error != null) ErrorBanner(_error!),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstCtrl,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'First name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastCtrl,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'Last name'),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    hintText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: (v) {
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '');
                  return ok ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _signup(),
                decoration: InputDecoration(
                  hintText: 'Password (8+ characters)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _signup,
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Create account'),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('By continuing you agree to our ', style: TextStyle(fontSize: 12, color: c.textMuted)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen.terms())),
              child: const Text('Terms', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
            ),
            Text(' and ', style: TextStyle(fontSize: 12, color: c.textMuted)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen.privacy())),
              child: const Text('Privacy Policy',
                  style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Already have an account?', style: TextStyle(color: c.textMuted)),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Sign in'),
          ),
        ]),
      ],
    );
  }
}

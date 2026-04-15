import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../splash_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  int  _step      = 0;
  bool _obscure   = true;
  bool _obscure2  = true;
  bool _agreed    = false;
  bool _loading   = false;
  String? _error;

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    final first = _firstCtrl.text.trim();
    final last  = _lastCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _step = 1; _error = null; });
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    final conf  = _confirmCtrl.text;

    if (email.isEmpty || pass.isEmpty || conf.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (pass != conf) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (!_agreed) {
      setState(() => _error = 'Please agree to the Terms and Conditions');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService().register(
        firstName: _firstCtrl.text.trim(),
        lastName:  _lastCtrl.text.trim(),
        email:     email,
        password:  pass,
      );
      if (!mounted) return;
      context.read<AppProvider>().setUser(user);
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) { nav.pop(); }
      else { nav.pushReplacementNamed('/home'); }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ── Back + Logo ──
              Row(children: [
                if (_step == 1)
                  GestureDetector(
                    onTap: () => setState(() { _step = 0; _error = null; }),
                    child: const Icon(Icons.arrow_back, color: kDark),
                  )
                else
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: kDark),
                  ),
              ]),
              const SizedBox(height: 32),
              const Center(child: GrubOutLogo()),
              const SizedBox(height: 36),

              Text(
                _step == 0 ? "Let's Get Started" : 'Last step!',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: kDark),
              ),
              const SizedBox(height: 24),

              if (_step == 0) ..._step0() else ..._step1(),

              // ── Error ──
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),

              // ── CTA button ──
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_step == 0 ? _nextStep : _register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_step == 0 ? 'Next' : 'Sign up',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Login link ──
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Login',
                      style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _step0() => [
        _Label('First Name'),
        const SizedBox(height: 6),
        TextField(
            controller: _firstCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your first name')),
        const SizedBox(height: 14),
        _Label('Last Name'),
        const SizedBox(height: 6),
        TextField(
            controller: _lastCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your last name')),
      ];

  List<Widget> _step1() => [
        _Label('Email'),
        const SizedBox(height: 6),
        TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Your email')),
        const SizedBox(height: 14),
        _Label('Password'),
        const SizedBox(height: 6),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'Your password',
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: kGrey, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Label('Re-type Password'),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscure2,
          decoration: InputDecoration(
            hintText: 'Re-type your password',
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure2 ? Icons.visibility_off : Icons.visibility,
                  color: kGrey, size: 20),
              onPressed: () => setState(() => _obscure2 = !_obscure2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Checkbox(
            value: _agreed,
            activeColor: kPrimary,
            onChanged: (v) => setState(() => _agreed = v ?? false),
          ),
          const Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree with the ',
                style: TextStyle(fontSize: 13, color: kGrey),
                children: [
                  TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                          color: kPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ]),
      ];
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: kDark));
}

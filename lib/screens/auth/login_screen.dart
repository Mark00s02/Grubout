import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService().login(email: email, password: pass);
      if (!mounted) return;
      context.read<AppProvider>().setUser(user);
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) { nav.pop(); }
      else { nav.pushReplacementNamed('/home'); }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _goSignup() => Navigator.pushNamed(context, '/signup');

  void _doItLater() {
    context.read<AppProvider>().setUser(null);
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) { nav.pop(); }
    else { nav.pushReplacementNamed('/home'); }
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
              const SizedBox(height: 48),

              // ── Logo ──
              const Center(child: GrubOutLogo()),
              const SizedBox(height: 48),

              // ── Title ──
              const Text('Welcome Back!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kDark)),
              const SizedBox(height: 24),

              // ── Email ──
              _Label('Email'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Your email'),
              ),
              const SizedBox(height: 14),

              // ── Password ──
              _Label('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
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

              // ── Forgot password ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?',
                      style: TextStyle(color: kPrimary, fontSize: 13)),
                ),
              ),

              // ── Error ──
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red.shade700,
                          fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 4),

              // ── Login button ──
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
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
                      : const Text('Login',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Or divider ──
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: Colors.grey.shade400)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),

              // ── Social buttons (placeholder) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialBtn(label: 'f', color: const Color(0xFF1877F2)),
                  const SizedBox(width: 16),
                  _SocialBtn(label: 'G', color: const Color(0xFFDB4437)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sign up link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  GestureDetector(
                    onTap: _goSignup,
                    child: const Text('Sign up',
                        style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Do it later ──
              Center(
                child: TextButton(
                  onPressed: _doItLater,
                  child: const Text('Do it later',
                      style: TextStyle(color: kPrimary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: kDark));
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _SocialBtn({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kLightGrey)),
      child: Center(
          child: Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 18))),
    );
  }
}

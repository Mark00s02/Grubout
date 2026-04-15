import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final auth = AuthService();
    final seen = await auth.hasSeenOnboarding();
    if (!mounted) return;

    if (!seen) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      final user = await auth.getSessionUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, user != null ? '/home' : '/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: const Center(child: _GrubOutLogo(size: 1.8)),
      ),
    );
  }
}

// ── GrubOut logo widget (reusable) ───────────────────────────────────────────
class _GrubOutLogo extends StatelessWidget {
  final double size;
  const _GrubOutLogo({this.size = 1.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Leaf icon
        Container(
          width: 64 * size,
          height: 64 * size,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(16 * size),
          ),
          child: Center(
            child: Text('🌿',
                style: TextStyle(fontSize: 36 * size)),
          ),
        ),
        SizedBox(height: 14 * size),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 34 * size,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                  text: 'grub',
                  style: TextStyle(color: kPrimary, fontSize: 34 * size)),
              TextSpan(
                  text: 'Out',
                  style: TextStyle(
                      color: kPrimary,
                      fontSize: 34 * size,
                      fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        SizedBox(height: 6 * size),
        Text(
          'Eat Smart. Live Better.',
          style: TextStyle(
              color: kGrey, fontSize: 13 * size, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

// Make it accessible from other files
class GrubOutLogo extends StatelessWidget {
  final double size;
  const GrubOutLogo({super.key, this.size = 1.0});

  @override
  Widget build(BuildContext context) => _GrubOutLogo(size: size);
}

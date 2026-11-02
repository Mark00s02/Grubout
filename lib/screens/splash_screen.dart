import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final auth = AuthService();
    final provider = context.read<AppProvider>();
    final results = await Future.wait([
      auth.hasSeenOnboarding(),
      auth.getSessionUser(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    final seen = results[0] as bool;
    final user = results[1] as AppUser?;

    String route;
    if (user != null) {
      await provider.setUser(user);
      route = provider.user!.onboarded ? '/home' : '/goals';
    } else {
      route = seen ? '/login' : '/onboarding';
    }
    if (mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0)
                .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)),
            child: const GrubOutLogo(size: 1.2),
          ),
        ),
      ),
    );
  }
}

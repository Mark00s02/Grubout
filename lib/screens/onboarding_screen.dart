import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Slide(this.icon, this.color, this.title, this.body);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(Icons.track_changes_rounded, kPrimary, 'Hit your goals,\nyour way',
        'A personal calorie and macro plan built from your body, activity and goal.'),
    _Slide(Icons.qr_code_scanner_rounded, kProteinColor, 'Log food in\nseconds',
        'Scan barcodes, search thousands of foods — including Filipino favourites like adobo and sinigang.'),
    _Slide(Icons.insights_rounded, kCarbsColor, 'See real\nprogress',
        'Streaks, weight trends, water, exercise and smart insights that keep you on track.'),
    _Slide(Icons.restaurant_menu_rounded, kFatColor, 'Eat well,\nnever guess',
        'Healthy recipes, diet plans and fasting timers — all in one beautiful app.'),
  ];

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _ctrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _finish({String route = '/signup'}) async {
    await AuthService().markOnboardingSeen();
    if (mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _finish(route: '/login'),
              child: const Text('I have an account'),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          s.color.withValues(alpha: 0.28),
                          s.color.withValues(alpha: 0.04),
                        ]),
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(color: s.color.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12)),
                            ],
                          ),
                          child: Icon(s.icon, color: Colors.white, size: 60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(s.title,
                        textAlign: TextAlign.center,
                        style: context.text.headlineMedium?.copyWith(height: 1.15)),
                    const SizedBox(height: 16),
                    Text(s.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: c.textMuted, height: 1.5)),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? kPrimary : c.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Get started' : 'Continue'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/diary/diary_screen.dart';
import 'screens/discover/discover_screen.dart';
import 'screens/goals/goal_setup_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/quick_log_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.loadPreferences();

  final purchases = PurchaseService()..onPremiumGranted = () => provider.setPremium(true);
  purchases.init();
  NotificationService().restore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: purchases),
      ],
      child: const GrubOutApp(),
    ),
  );
}

class GrubOutApp extends StatelessWidget {
  const GrubOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppProvider, ThemeMode>((p) => p.themeMode);
    return MaterialApp(
      title: 'GrubOut',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash':     (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login':      (_) => const LoginScreen(),
        '/signup':     (_) => const SignupScreen(),
        '/goals':      (_) => const GoalSetupScreen(),
        '/home':       (_) => const MainNav(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main navigation: Today · Diary · (+) · Progress · Discover
// ─────────────────────────────────────────────────────────────────────────────
class MainNav extends StatefulWidget {
  const MainNav({super.key});

  /// Lets any descendant switch tabs (e.g. "View diary" on the dashboard).
  static void goToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_MainNavState>()?._select(index);

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;
  DateTime? _lastBackPress;

  static const _pages = [
    DashboardScreen(),
    DiaryScreen(),
    ProgressScreen(),
    DiscoverScreen(),
  ];

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _onBack() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)));
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: _BottomBar(
          index: _index,
          onSelect: _select,
          onAdd: () => showQuickLogSheet(context),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  const _BottomBar({required this.index, required this.onSelect, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _NavItem(Icons.home_outlined, Icons.home_rounded, 'Today', index == 0, () => onSelect(0)),
            _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Diary', index == 1, () => onSelect(1)),
            Expanded(
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Quick log',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAdd();
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimaryLight, kPrimary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: kPrimary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
            _NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Progress', index == 2, () => onSelect(2)),
            _NavItem(Icons.explore_outlined, Icons.explore_rounded, 'Discover', index == 3, () => onSelect(3)),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.activeIcon, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : context.colors.textMuted;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active ? activeIcon : icon, color: color, size: 25),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

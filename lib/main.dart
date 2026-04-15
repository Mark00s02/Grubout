import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tracker/tracker_screen.dart';
import 'screens/diet_plan_screen.dart';
import 'screens/profile/user_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.loadPreferences();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
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
      title: 'grubOut',
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
        '/home':       (_) => const MainNav(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Navigation (4 tabs)
// ─────────────────────────────────────────────────────────────────────────────
class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Double-back-to-exit state
  DateTime? _lastBackPress;

  List<Widget> get _tabs => [
    _TabRoot(key: PageStorageKey('home'),    navigatorKey: _navKeys[0], child: const HomeScreen()),
    _TabRoot(key: PageStorageKey('tracker'), navigatorKey: _navKeys[1], child: const TrackerScreen()),
    _TabRoot(key: PageStorageKey('diet'),    navigatorKey: _navKeys[2], child: const DietPlanScreen()),
    _TabRoot(key: PageStorageKey('profile'), navigatorKey: _navKeys[3], child: const UserScreen()),
  ];

  // Returns true if we should let the OS handle the pop (i.e. exit the app).
  bool _handleBackPress() {
    final nav = _navKeys[_index].currentState;

    // If the current tab has pages to pop, pop within the tab.
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }

    // If not on the home tab, go back to home tab.
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }

    // We're on the home tab with nothing to pop — require double-back to exit.
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true; // second press within 2 s → exit
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // we always intercept; _handleBackPress decides exit
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_handleBackPress()) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: _tabs,
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

// Wraps each tab in its own Navigator so back-navigation stays within the tab.
class _TabRoot extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  const _TabRoot({required this.child, required this.navigatorKey, super.key});

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => child),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final navBg = Theme.of(context).bottomNavigationBarTheme.backgroundColor
        ?? Colors.white;
    final borderColor = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Tracker',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: 'Diet Plan',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
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

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Theme.of(context)
            .bottomNavigationBarTheme.unselectedItemColor ??
        const Color(0xFFAAAAAA);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? kPrimary : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? kPrimary : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

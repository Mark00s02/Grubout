import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoggedIn) {
          return _GuestView(onLogin: () =>
              Navigator.of(context, rootNavigator: true).pushNamed('/login'));
        }
        return _ProfileView(provider: provider);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest (not logged in)
// ─────────────────────────────────────────────────────────────────────────────
class _GuestView extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: const BoxDecoration(
                      color: kBg, shape: BoxShape.circle),
                  child: const Center(
                      child: Icon(Icons.person, size: 52, color: kGrey)),
                ),
                const SizedBox(height: 24),
                const Text('Not Signed In',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kDark)),
                const SizedBox(height: 10),
                const Text(
                    'Log in or create an account to track your calories and save your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kGrey, fontSize: 14, height: 1.5)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Log In',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pushNamed('/signup'),
                  child: const Text('Create Account',
                      style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile (logged in)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileView extends StatefulWidget {
  final AppProvider provider;
  const _ProfileView({required this.provider});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool _notifMealReminders = true;
  bool _notifDietUpdates = true;
  bool _notifNewRecipes = false;
  bool _notifHealthTips = true;

  AppUser get user => widget.provider.user!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 84, height: 84,
                        decoration: const BoxDecoration(
                            color: kBg, shape: BoxShape.circle),
                        child: const Center(
                          child: Icon(Icons.person,
                              size: 48, color: kGrey),
                        ),
                      ),
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(user.fullName,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(color: kGrey, fontSize: 13)),
                  if (user.isPremium) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 1),
                      ),
                      child: const Text('Premium Member',
                          style: TextStyle(
                              color: Color(0xFFB8860B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

            // ── Stats ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    value: user.calorieGoal.toString(),
                    label: 'Cal Goal',
                  ),
                  _VertDivider(),
                  const _Stat(value: '0', label: 'Recipes Saved'),
                  _VertDivider(),
                  const _Stat(value: '0', label: 'Days Active'),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Section: Account ──
            _SectionHeader(label: 'Account'),
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () => _showEditProfile(context),
            ),
            _MenuItem(
              icon: Icons.diamond_outlined,
              label: 'Subscription',
              trailing: user.isPremium
                  ? const Text('Premium',
                      style: TextStyle(color: kPrimary, fontSize: 12))
                  : null,
              onTap: () => _showSubscription(context),
            ),

            const SizedBox(height: 4),
            _SectionHeader(label: 'Preferences'),
            _MenuItem(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => _showNotifications(context),
            ),
            _MenuItem(
              icon: Icons.language,
              label: 'Language',
              trailing: Text(widget.provider.language,
                  style: const TextStyle(color: kGrey, fontSize: 13)),
              onTap: () => _showLanguage(context),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _showSettings(context),
            ),

            const SizedBox(height: 4),
            _SectionHeader(label: 'Support'),
            _MenuItem(
              icon: Icons.mail_outline,
              label: 'Contact Us',
              onTap: () => _showContactUs(context),
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: 'About Us',
              onTap: () => _showAbout(context),
            ),
            _MenuItem(
              icon: Icons.logout,
              label: 'Logout',
              iconColor: Colors.red.shade400,
              textColor: Colors.red.shade400,
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Edit Profile ──
  void _showEditProfile(BuildContext context) {
    final firstCtrl = TextEditingController(text: user.firstName);
    final lastCtrl = TextEditingController(text: user.lastName);
    final calCtrl =
        TextEditingController(text: user.calorieGoal.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit Profile',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              const SizedBox(height: 16),
              _LabeledField(label: 'First Name', controller: firstCtrl),
              const SizedBox(height: 12),
              _LabeledField(label: 'Last Name', controller: lastCtrl),
              const SizedBox(height: 12),
              _LabeledField(
                  label: 'Daily Calorie Goal',
                  controller: calCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final updated = user.copyWith(
                    firstName: firstCtrl.text.trim(),
                    lastName: lastCtrl.text.trim(),
                    calorieGoal:
                        int.tryParse(calCtrl.text) ?? user.calorieGoal,
                  );
                  await widget.provider.updateUser(updated);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save Changes',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Subscription ──
  void _showSubscription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Premium Plan',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
            const SizedBox(height: 8),
            const Text('₱299 / month',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kPrimary)),
            const SizedBox(height: 16),
            ...[
              'Personalized diet plans',
              'Meal scheduling',
              'Unlimited recipes',
              'Nutrition tracking',
              'Priority support'
            ].map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Text('✅ ', style: TextStyle(fontSize: 14)),
                    Text(f,
                        style: const TextStyle(fontSize: 14, color: kDark)),
                  ]),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: user.isPremium
                  ? null
                  : () async {
                      final updated = user.copyWith(isPremium: true);
                      await widget.provider.updateUser(updated);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(user.isPremium ? 'Already Subscribed' : 'Subscribe Now',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notifications ──
  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Notifications',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              const SizedBox(height: 16),
              _Toggle(
                label: 'Meal Reminders',
                value: _notifMealReminders,
                onChanged: (v) {
                  setState(() => _notifMealReminders = v);
                  setS(() {});
                },
              ),
              _Toggle(
                label: 'Diet Plan Updates',
                value: _notifDietUpdates,
                onChanged: (v) {
                  setState(() => _notifDietUpdates = v);
                  setS(() {});
                },
              ),
              _Toggle(
                label: 'New Recipes',
                value: _notifNewRecipes,
                onChanged: (v) {
                  setState(() => _notifNewRecipes = v);
                  setS(() {});
                },
              ),
              _Toggle(
                label: 'Health Tips',
                value: _notifHealthTips,
                onChanged: (v) {
                  setState(() => _notifHealthTips = v);
                  setS(() {});
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language ──
  void _showLanguage(BuildContext context) {
    const langs = ['English', 'Filipino', 'Español', 'Français', '中文'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Language',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              const SizedBox(height: 16),
              ...langs.map((l) => ListTile(
                    title: Text(l, style: const TextStyle(color: kDark)),
                    trailing: widget.provider.language == l
                        ? const Icon(Icons.check, color: kPrimary)
                        : null,
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      await widget.provider.setLanguage(l);
                      setState(() {});
                      if (context.mounted) Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings ──
  void _showSettings(BuildContext context) {
    String unit = 'Metric';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final provider = context.read<AppProvider>();
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: kLightGrey,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Settings',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 20),

                  // Dark mode — wired to AppProvider
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    trailing: Switch(
                      value: provider.isDarkMode,
                      activeThumbColor: kPrimary,
                      activeTrackColor: kPrimary.withValues(alpha: 0.4),
                      onChanged: (v) {
                        provider.setDarkMode(v);
                        setS(() {});
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // Units
                  _SettingsRow(
                    icon: Icons.straighten,
                    label: 'Units',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: unit,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'Metric',
                              child: Text('Metric')),
                          DropdownMenuItem(value: 'Imperial',
                              child: Text('Imperial')),
                        ],
                        onChanged: (v) => setS(() => unit = v ?? 'Metric'),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Calorie goal shortcut
                  _SettingsRow(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Daily Calorie Goal',
                    trailing: Text('${user.calorieGoal} kcal',
                        style: const TextStyle(
                            color: kPrimary, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditProfile(context);
                    },
                  ),
                  const Divider(height: 1),

                  // Clear data
                  _SettingsRow(
                    icon: Icons.delete_outline,
                    label: 'Clear All Food Logs',
                    iconColor: Colors.red.shade400,
                    textColor: Colors.red.shade400,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Clear Food Logs',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: kDark)),
                          content: const Text(
                              'This will delete all your food log entries. This cannot be undone.',
                              style: TextStyle(color: kGrey)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style: TextStyle(color: kGrey)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Food logs cleared')),
                                );
                              },
                              child: Text('Clear',
                                  style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Contact Us ──
  void _showContactUs(BuildContext context) {
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: kLightGrey,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Contact Us',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              const SizedBox(height: 6),
              const Text('We typically reply within 24 hours.',
                  style: TextStyle(fontSize: 13, color: kGrey)),
              const SizedBox(height: 20),
              // Contact channels
              _SettingsRow(
                icon: Icons.email_outlined,
                label: 'support@grubout.app',
                trailing: const Icon(Icons.copy, size: 16, color: kGrey),
                onTap: () {
                  Clipboard.setData(
                      const ClipboardData(text: 'support@grubout.app'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copied to clipboard')),
                  );
                },
              ),
              const Divider(height: 1),
              _SettingsRow(
                icon: Icons.chat_bubble_outline,
                label: 'Facebook: @grubOutApp',
                trailing: const Icon(Icons.open_in_new, size: 16, color: kGrey),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Facebook...')),
                  );
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Message field
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your message or feedback here...',
                  hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Message sent! We\'ll be in touch soon.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Send Message',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── About ──
  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About grubOut',
            style: TextStyle(fontWeight: FontWeight.w700, color: kDark)),
        content: const Text(
            'grubOut v1.0.0\n\nA Filipino-inspired diet and recipe management app.\n\n© 2024 grubOut. All rights reserved.',
            style: TextStyle(color: kDark, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style:
                    TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Logout ──
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w700, color: kDark)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: kGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: kGrey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                context.read<AppProvider>().setUser(null);
              }
            },
            child: Text('Log Out',
                style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: kDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kGrey)),
      ]);
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 36, color: kDivider);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kGrey,
                letterSpacing: 0.8)),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, color: iconColor ?? kDark, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? kDark)),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: kGrey),
          ]),
        ),
      );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: kBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: kPrimary,
        activeTrackColor: kPrimary.withValues(alpha: 0.4),
        title: Text(label,
            style: const TextStyle(fontSize: 15, color: kDark)),
        contentPadding: EdgeInsets.zero,
      );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Icon(icon, size: 20, color: iconColor ?? kDark),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? kDark)),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      );
}

// Needed for DatabaseService access in save count (future improvement)
// ignore: unused_import
class _SavedCount extends StatefulWidget {
  final int userId;
  const _SavedCount({required this.userId});
  @override
  State<_SavedCount> createState() => _SavedCountState();
}

class _SavedCountState extends State<_SavedCount> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids =
        await DatabaseService().getSavedRecipeIds(widget.userId);
    if (mounted) setState(() => _count = ids.length);
  }

  @override
  Widget build(BuildContext context) =>
      Text('$_count', style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: kDark));
}

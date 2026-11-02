import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/nutrition_calculator.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../goals/goal_setup_screen.dart';
import '../premium/paywall_screen.dart';
import 'legal_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final u = p.user;
    if (u == null) return const Scaffold();
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          // ── Header ───────────────────────────────────────────────────────
          AppCard(
            child: Column(children: [
              GestureDetector(
                onTap: () => _pickAvatar(context, p),
                child: Stack(children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: kPrimary,
                    child: Text(u.avatarEmoji ?? u.initials,
                        style: TextStyle(
                            color: Colors.white, fontSize: u.avatarEmoji != null ? 40 : 28, fontWeight: FontWeight.w800)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: c.surface,
                      child: const Icon(Icons.edit_rounded, size: 15, color: kPrimary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Text(u.fullName, style: context.text.titleLarge),
              Text(u.email, style: TextStyle(color: c.textMuted)),
              const SizedBox(height: 8),
              if (u.isPremium) const PremiumBadge() else
                Text('Member since ${DateFormat('MMMM y').format(u.createdAt)}',
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
              const SizedBox(height: 18),
              Row(children: [
                _HeaderStat('${p.streak}', 'Day streak'),
                _HeaderStat('${p.daysLogged}', 'Days logged'),
                _HeaderStat('${p.savedRecipeIds.length}', 'Saved recipes'),
              ]),
            ]),
          ),

          if (!u.isPremium) ...[
            const SizedBox(height: 14),
            AppCard(
              gradient: const LinearGradient(colors: [Color(0xFF1F3B2C), Color(0xFF2E5A40)]),
              onTap: () => showPaywall(context),
              child: const Row(children: [
                Icon(Icons.workspace_premium_rounded, color: kGold, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Upgrade to Premium',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ]),
            ),
          ],

          _Section('Goals', [
            _Item(Icons.flag_rounded, 'Goals & plan',
                trailing: '${fmtNum(u.calorieGoal)} kcal',
                onTap: () => _push(context, const GoalSetupScreen(editing: true))),
            _Item(Icons.pie_chart_rounded, 'Macro targets',
                trailing: '${u.proteinPct}/${u.carbsPct}/${u.fatPct}',
                premium: !u.isPremium,
                onTap: () {
                  if (requirePremium(context)) _push(context, const MacroTargetsScreen());
                }),
            _Item(Icons.water_drop_rounded, 'Water goal',
                trailing: '${(u.waterGoalMl / 1000).toStringAsFixed(2)} L', onTap: () => _editWater(context, p)),
          ]),

          _Section('Account', [
            _Item(Icons.person_rounded, 'Edit name', onTap: () => _editName(context, p)),
            _Item(Icons.lock_rounded, 'Change password', onTap: () => _changePassword(context, p)),
            _Item(Icons.workspace_premium_rounded, 'Subscription',
                trailing: u.isPremium ? 'Premium' : 'Free', onTap: () => showPaywall(context)),
            _Item(Icons.restore_rounded, 'Restore purchases', onTap: () {
              context.read<PurchaseService>().restore();
              showSnack(context, 'Checking the App Store for purchases…', icon: Icons.restore_rounded);
            }),
          ]),

          _Section('Preferences', [
            _Item(Icons.notifications_rounded, 'Reminders', onTap: () => _push(context, const RemindersScreen())),
            _Item(Icons.dark_mode_rounded, 'Appearance',
                trailing: switch (p.themeMode) {
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                  ThemeMode.system => 'System',
                },
                onTap: () => _pickTheme(context, p)),
          ]),

          _Section('Support', [
            _Item(Icons.mail_rounded, 'Contact us', onTap: () => _contact(context)),
            _Item(Icons.privacy_tip_rounded, 'Privacy Policy', onTap: () => _push(context, const LegalScreen.privacy())),
            _Item(Icons.description_rounded, 'Terms of Use', onTap: () => _push(context, const LegalScreen.terms())),
            _Item(Icons.info_rounded, 'About GrubOut', onTap: () => _about(context)),
          ]),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            onPressed: () => _logout(context, p),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kDanger),
            onPressed: () => _deleteAccount(context, p),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _pickAvatar(BuildContext context, AppProvider p) {
    const emojis = ['🥗', '🍎', '🥑', '🍓', '🥦', '🍍', '🥭', '🍌', '🏃', '💪', '🧘', '🌿', '🐱', '🐶', '😎', '🙂'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Choose an avatar', style: ctx.text.titleLarge),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              for (final e in emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    p.updateUser(p.user!.copyWith(avatarEmoji: e));
                    Navigator.pop(ctx);
                  },
                  child: CircleAvatar(radius: 28, backgroundColor: ctx.colors.surfaceAlt, child: Text(e, style: const TextStyle(fontSize: 28))),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppProvider p) async {
    final first = TextEditingController(text: p.user!.firstName);
    final last = TextEditingController(text: p.user!.lastName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: first, decoration: const InputDecoration(labelText: 'First name')),
          const SizedBox(height: 12),
          TextField(controller: last, decoration: const InputDecoration(labelText: 'Last name')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && first.text.trim().isNotEmpty) {
      await p.updateUser(p.user!.copyWith(firstName: first.text.trim(), lastName: last.text.trim()));
    }
  }

  Future<void> _changePassword(BuildContext context, AppProvider p) async {
    final current = TextEditingController();
    final next = TextEditingController();
    String? error;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Change password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(error!, style: const TextStyle(color: kDanger, fontWeight: FontWeight.w600)),
              ),
            TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
            const SizedBox(height: 12),
            TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password (8+)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (next.text.length < 8) {
                  setState(() => error = 'Use at least 8 characters');
                  return;
                }
                try {
                  await AuthService().changePassword(p.user!, current.text, next.text);
                  final refreshed = await AuthService().getSessionUser();
                  if (refreshed != null) await p.updateUser(refreshed);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) showSnack(context, 'Password updated');
                } catch (e) {
                  setState(() => error = e.toString());
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editWater(BuildContext context, AppProvider p) async {
    var ml = p.user!.waterGoalMl.toDouble();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Daily water goal', style: ctx.text.titleLarge),
              const SizedBox(height: 12),
              Text('${(ml / 1000).toStringAsFixed(2)} L · ${(ml / 250).round()} glasses',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Slider(value: ml, min: 1000, max: 5000, divisions: 16, onChanged: (v) => setState(() => ml = v)),
              TextButton(
                onPressed: () => setState(() => ml = NutritionCalculator.waterGoalMl(p.currentWeightKg).toDouble()),
                child: const Text('Use recommended'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok == true) await p.updateUser(p.user!.copyWith(waterGoalMl: ml.round()));
  }

  void _pickTheme(BuildContext context, AppProvider p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final m in ThemeMode.values)
            ListTile(
              leading: Icon(switch (m) {
                ThemeMode.system => Icons.brightness_auto_rounded,
                ThemeMode.light => Icons.light_mode_rounded,
                ThemeMode.dark => Icons.dark_mode_rounded,
              }),
              title: Text(switch (m) {
                ThemeMode.system => 'Match system',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              }),
              trailing: p.themeMode == m ? const Icon(Icons.check_rounded, color: kPrimary) : null,
              onTap: () {
                p.setThemeMode(m);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _contact(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact us'),
        content: const Text('We read every message.\n\nsupport@grubout.app'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'support@grubout.app'));
              Navigator.pop(ctx);
              showSnack(context, 'Email copied');
            },
            child: const Text('Copy email'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _about(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'GrubOut',
      applicationVersion: '1.0.0',
      applicationIcon: const GrubOutMark(size: 48),
      children: const [
        Text('Eat smart. Live better.\n\n'
            'Nutrition data: USDA FoodData Central, Open Food Facts and a curated Filipino food list. '
            'Recipes: GrubOut and TheMealDB.\n\n'
            'GrubOut is not a medical device and does not provide medical advice.'),
      ],
    );
  }

  Future<void> _logout(BuildContext context, AppProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Your data stays safely on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final nav = Navigator.of(context);
    await p.logout();
    nav.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _deleteAccount(BuildContext context, AppProvider p) async {
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: kDanger, size: 36),
          title: const Text('Delete account?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'This permanently deletes your account, diary, weights and all other data from this device. '
              'This cannot be undone.\n\nIf you have a subscription, cancel it in your App Store settings.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Type DELETE to confirm'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kDanger),
              onPressed: confirm.text.trim() == 'DELETE' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final nav = Navigator.of(context);
    await p.deleteAccount();
    nav.pushNamedAndRemoveUntil('/signup', (_) => false);
  }
}

// ── Building blocks ──────────────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ]),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section(this.title, this.items);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: context.colors.textMuted)),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1) const Divider(indent: 56),
            ],
          ]),
        ),
      ]);
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool premium;
  final VoidCallback onTap;
  const _Item(this.icon, this.title, {required this.onTap, this.trailing, this.premium = false});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: kPrimary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (premium) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.workspace_premium_rounded, color: kGold, size: 18)),
          if (trailing != null) Text(trailing!, style: TextStyle(color: context.colors.textMuted)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
        ]),
      );
}

// ── Reminders ────────────────────────────────────────────────────────────────
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Map<String, bool> _enabled = {};

  @override
  void initState() {
    super.initState();
    NotificationService().enabledReminders().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _toggle(Reminder r, bool on) async {
    final ok = await NotificationService().setReminder(r, on);
    if (!mounted) return;
    if (!ok) {
      showSnack(context, 'Allow notifications for GrubOut in Settings to get reminders',
          icon: Icons.notifications_off_rounded);
      return;
    }
    setState(() => _enabled[r.key] = on);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('People who log consistently are far more likely to reach their goal. Gentle nudges help.',
              style: TextStyle(color: c.textMuted, height: 1.4)),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              for (final r in reminders)
                SwitchListTile(
                  value: _enabled[r.key] ?? false,
                  onChanged: (v) => _toggle(r, v),
                  title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    TimeOfDay(hour: r.hour, minute: r.minute).format(context),
                    style: TextStyle(color: c.textMuted),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Macro targets (Premium) ──────────────────────────────────────────────────
class MacroTargetsScreen extends StatefulWidget {
  const MacroTargetsScreen({super.key});

  @override
  State<MacroTargetsScreen> createState() => _MacroTargetsScreenState();
}

class _MacroTargetsScreenState extends State<MacroTargetsScreen> {
  late final AppUser _u = context.read<AppProvider>().user!;
  late int _p = _u.proteinPct, _c = _u.carbsPct, _f = _u.fatPct;

  static const _presets = [
    ('Balanced', 25, 45, 30),
    ('High protein', 35, 35, 30),
    ('Low carb', 30, 20, 50),
    ('Endurance', 20, 55, 25),
  ];

  int get _total => _p + _c + _f;

  @override
  Widget build(BuildContext context) {
    final kcal = _u.calorieGoal;
    Widget row(String label, int value, Color color, ValueChanged<int> set, int factor) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$value% · ${(kcal * value / 100 / factor).round()} g',
                  style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600)),
            ]),
            Slider(
              value: value.toDouble(),
              min: 5,
              max: 70,
              divisions: 13,
              activeColor: color,
              onChanged: (v) => setState(() => set(v.round())),
            ),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Macro targets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final pr in _presets)
              ActionChip(
                label: Text(pr.$1),
                onPressed: () => setState(() {
                  _p = pr.$2;
                  _c = pr.$3;
                  _f = pr.$4;
                }),
              ),
          ]),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              row('Protein', _p, kProteinColor, (v) => _p = v, 4),
              row('Carbs', _c, kCarbsColor, (v) => _c = v, 4),
              row('Fat', _f, kFatColor, (v) => _f = v, 9),
            ]),
          ),
          const SizedBox(height: 12),
          Text(
            _total == 100 ? 'Total 100% ✓' : 'Total $_total% — adjust to reach 100%',
            textAlign: TextAlign.center,
            style: TextStyle(color: _total == 100 ? kPrimary : kDanger, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _total == 100
                ? () async {
                    final p = context.read<AppProvider>();
                    await p.updateUser(p.user!.copyWith(proteinPct: _p, carbsPct: _c, fatPct: _f));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    showSnack(context, 'Macro targets saved');
                  }
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

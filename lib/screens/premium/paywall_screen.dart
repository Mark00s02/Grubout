import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../profile/legal_screen.dart';

Future<void> showPaywall(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PaywallScreen()),
    );

/// Returns true if the user already has Premium; otherwise opens the paywall.
bool requirePremium(BuildContext context) {
  if (context.read<AppProvider>().isPremium) return true;
  showPaywall(context);
  return false;
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;

  static const _features = [
    (Icons.restaurant_menu_rounded, 'Diet plans', 'Mediterranean, DASH, vegan & flexitarian meal schedules'),
    (Icons.timer_rounded, 'Intermittent fasting', '13–20 hour timers with history'),
    (Icons.insights_rounded, 'Advanced insights', '30 & 90-day trends, macro breakdowns, goal hit-rate'),
    (Icons.tune_rounded, 'Custom macro targets', 'Set your own protein, carb and fat split'),
    (Icons.favorite_rounded, 'Support GrubOut', 'Help us add more Filipino foods and recipes'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PurchaseService>().loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PurchaseService>();
    final premium = context.select<AppProvider, bool>((p) => p.isPremium);
    final c = context.colors;

    if (premium) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.workspace_premium_rounded,
          title: "You're Premium 🎉",
          message: 'Every feature is unlocked. Thank you for supporting GrubOut!',
          action: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
        ),
      );
    }

    final selected = _yearly ? store.yearly : store.monthly;

    return Scaffold(
      body: Stack(children: [
        Container(
          height: 300,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F3B2C), kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: kGold, size: 56),
                  const SizedBox(height: 10),
                  const Text('GrubOut Premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Reach your goal faster with every tool unlocked.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 28),
                  AppCard(
                    child: Column(children: [
                      for (final f in _features)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                              child: Icon(f.$1, color: kPrimary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(f.$3, style: TextStyle(fontSize: 13, color: c.textMuted)),
                              ]),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  if (store.loading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else ...[
                    if (store.yearly != null)
                      _PlanOption(
                        product: store.yearly!,
                        title: 'Yearly',
                        badge: 'BEST VALUE',
                        selected: _yearly,
                        onTap: () => setState(() => _yearly = true),
                      ),
                    if (store.monthly != null)
                      _PlanOption(
                        product: store.monthly!,
                        title: 'Monthly',
                        selected: !_yearly,
                        onTap: () => setState(() => _yearly = false),
                      ),
                    if (store.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(store.error!,
                            textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, fontSize: 13)),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected == null || store.purchasing ? null : () => store.buy(selected),
                    child: store.purchasing
                        ? const SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Continue'),
                  ),
                ),
                if (kDebugMode)
                  TextButton(
                    onPressed: () => context.read<AppProvider>().setPremium(true),
                    child: const Text('Developer: unlock Premium (debug builds only)'),
                  ),
                Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  TextButton(onPressed: store.purchasing ? null : store.restore, child: const Text('Restore purchases')),
                  Text('·', style: TextStyle(color: c.textMuted)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LegalScreen.terms())),
                    child: const Text('Terms'),
                  ),
                  Text('·', style: TextStyle(color: c.textMuted)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LegalScreen.privacy())),
                    child: const Text('Privacy'),
                  ),
                ]),
                Text(
                  'Subscriptions renew automatically at the price shown unless cancelled at least 24 hours '
                  'before the end of the current period. Payment is charged to your Apple ID account. '
                  'Manage or cancel any time in your App Store account settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.textMuted, height: 1.4),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final ProductDetails product;
  final String title;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.product,
    required this.title,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? kPrimary.withValues(alpha: 0.08) : c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? kPrimary : c.border, width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? kPrimary : c.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (badge != null) ...[const SizedBox(width: 8), Pill(badge!, color: kGold, filled: true)],
                ]),
                if (product.description.isNotEmpty)
                  Text(product.description, style: TextStyle(fontSize: 12, color: c.textMuted)),
              ]),
            ),
            Text(product.price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ),
      ),
    );
  }
}

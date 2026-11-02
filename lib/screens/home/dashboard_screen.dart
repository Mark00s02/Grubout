import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/quick_log_sheet.dart';
import '../fasting/fasting_screen.dart';
import '../premium/paywall_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/weight_sheet.dart';
import '../recipe_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final u = p.user;
    if (u == null) return const SizedBox.shrink();
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: p.loadDayData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
                        style: TextStyle(fontSize: 12, letterSpacing: 0.8, color: c.textMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${_greeting()}, ${u.firstName}', style: context.text.headlineSmall),
                  ]),
                ),
                if (p.streak > 0) ...[
                  Pill('${p.streak}', icon: Icons.local_fire_department_rounded, color: kCarbsColor),
                  const SizedBox(width: 10),
                ],
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Stack(clipBehavior: Clip.none, children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: kPrimary,
                      child: Text(u.avatarEmoji ?? u.initials,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: u.avatarEmoji != null ? 22 : 15)),
                    ),
                    if (u.isPremium)
                      const Positioned(
                        right: -2,
                        bottom: -2,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: kGold,
                          child: Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),

              if (!p.isToday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActionChip(
                    avatar: const Icon(Icons.history_rounded, size: 18),
                    label: Text('Showing ${DateFormat('MMM d').format(p.selectedDate)} · Back to today'),
                    onPressed: () => p.selectDate(DateTime.now()),
                  ),
                ),

              _CaloriesCard(provider: p),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _WaterTile(provider: p)),
                const SizedBox(width: 14),
                Expanded(child: _WeightTile(provider: p)),
              ]),
              const SizedBox(height: 14),

              if (p.activeFast != null) ...[
                _FastingTile(provider: p),
                const SizedBox(height: 14),
              ],

              if (p.foodLogs.isEmpty && p.isToday)
                AppCard(
                  onTap: () => showQuickLogSheet(context),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.restaurant_rounded, color: kPrimary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Log your first meal', style: context.text.titleMedium),
                        Text(
                            p.streak > 0
                                ? 'Keep your ${p.streak}-day streak going!'
                                : 'Start a streak today — it only takes a few seconds.',
                            style: TextStyle(color: c.textMuted, fontSize: 13)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),

              if (!u.isPremium) ...[
                const SizedBox(height: 14),
                _PremiumBanner(),
              ],

              SectionHeader('Healthy picks for you',
                  padding: const EdgeInsets.fromLTRB(4, 24, 0, 10),
                  action: 'See all',
                  onAction: () => MainNav.goToTab(context, 3)),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _RecipeTile(recipe: recipes[(i + DateTime.now().day) % recipes.length]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calories ─────────────────────────────────────────────────────────────────
class _CaloriesCard extends StatelessWidget {
  final AppProvider provider;
  const _CaloriesCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final c = context.colors;
    final u = p.user!;
    final remaining = p.caloriesRemaining;
    final budget = p.calorieGoal + p.caloriesBurned;
    final over = remaining < 0;

    Widget stat(IconData icon, String label, num value, Color color) => Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textMuted)),
              Text(fmtNum(value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
        ]);

    return AppCard(
      onTap: () => MainNav.goToTab(context, 1),
      child: Column(children: [
        Row(children: [
          Text('Calories', style: context.text.titleMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Goal − Food + Exercise',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.textMuted)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          ProgressRing(
            value: budget > 0 ? p.caloriesConsumed / budget : 0,
            size: 150,
            stroke: 13,
            overColor: kDanger,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(fmtNum(remaining.abs()),
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1, color: over ? kDanger : null)),
              Text(over ? 'over' : 'remaining', style: TextStyle(color: c.textMuted, fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stat(Icons.flag_rounded, 'Base goal', p.calorieGoal, c.textMuted),
              const SizedBox(height: 14),
              stat(Icons.restaurant_rounded, 'Food', p.caloriesConsumed, kPrimary),
              const SizedBox(height: 14),
              stat(Icons.local_fire_department_rounded, 'Exercise', p.caloriesBurned, kCarbsColor),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: MacroBar(label: 'Protein', value: p.totalProtein, goal: u.proteinGoalG, color: kProteinColor)),
          const SizedBox(width: 14),
          Expanded(child: MacroBar(label: 'Carbs', value: p.totalCarbs, goal: u.carbsGoalG, color: kCarbsColor)),
          const SizedBox(width: 14),
          Expanded(child: MacroBar(label: 'Fat', value: p.totalFat, goal: u.fatGoalG, color: kFatColor)),
        ]),
      ]),
    );
  }
}

// ── Water ────────────────────────────────────────────────────────────────────
class _WaterTile extends StatelessWidget {
  final AppProvider provider;
  const _WaterTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    final goal = provider.user!.waterGoalMl;
    final ml = provider.waterMl;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.water_drop_rounded, color: kWaterColor, size: 20),
          const SizedBox(width: 6),
          Text('Water', style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text('${(ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 2)} L',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text('of ${(goal / 1000).toStringAsFixed(1)} L', style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: goal > 0 ? (ml / goal).clamp(0.0, 1.0) : 0,
            minHeight: 6,
            color: kWaterColor,
            backgroundColor: context.colors.track,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: EdgeInsets.zero),
              onPressed: ml > 0 ? () => provider.addWater(-250) : null,
              child: const Icon(Icons.remove_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: kWaterColor, minimumSize: const Size(0, 36), padding: EdgeInsets.zero),
              onPressed: () => provider.addWater(250),
              child: const Icon(Icons.add_rounded, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Weight ───────────────────────────────────────────────────────────────────
class _WeightTile extends StatelessWidget {
  final AppProvider provider;
  const _WeightTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    final u = provider.user!;
    final current = provider.currentWeightKg;
    final change = current - u.startWeightKg;
    final total = (u.startWeightKg - u.targetWeightKg).abs();
    final done = (u.startWeightKg - current) * (u.goalType == GoalType.gain ? -1 : 1);
    final progress = total > 0 ? (done / total).clamp(0.0, 1.0) : 1.0;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => showWeightSheet(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monitor_weight_rounded, color: kFatColor, size: 20),
          const SizedBox(width: 6),
          Text('Weight', style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text('${current.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text(
          change.abs() < 0.05 ? 'Goal ${u.targetWeightKg.toStringAsFixed(1)} kg' : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg since start',
          style: TextStyle(fontSize: 12, color: context.colors.textMuted),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: progress, minHeight: 6, color: kFatColor, backgroundColor: context.colors.track),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kFatColor, minimumSize: const Size(0, 36)),
            onPressed: () => showWeightSheet(context),
            child: const Text('Log', style: TextStyle(fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}

// ── Fasting ──────────────────────────────────────────────────────────────────
class _FastingTile extends StatelessWidget {
  final AppProvider provider;
  const _FastingTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    final f = provider.activeFast!;
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FastingScreen())),
      child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 30)),
        builder: (_, __) {
          final h = f.elapsed.inHours, m = f.elapsed.inMinutes % 60;
          return Row(children: [
            ProgressRing(
              value: f.progress,
              size: 52,
              stroke: 6,
              color: const Color(0xFF8E5CD9),
              child: const Icon(Icons.timer_rounded, size: 20, color: Color(0xFF8E5CD9)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Fasting · ${h}h ${m}m', style: context.text.titleMedium),
                Text(f.completed ? 'Goal reached — great job!' : '${f.targetHours}h goal · ${(f.progress * 100).round()}%',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]);
        },
      ),
    );
  }
}

// ── Premium banner ───────────────────────────────────────────────────────────
class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3B2C), Color(0xFF2E5A40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => showPaywall(context),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: kGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.workspace_premium_rounded, color: kGold, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Go Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 2),
              Text('Diet plans, fasting, deep insights & more',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
        ]),
      );
}

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: NetImage(recipe.imageUrl, width: 160, height: 140, fallbackEmoji: recipe.emoji),
            ),
            const SizedBox(height: 8),
            Text(recipe.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${recipe.caloriesPerServing} kcal · ${recipe.protein.round()}g protein',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
          ]),
        ),
      );
}

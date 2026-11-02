import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/nutrition_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../exercise/add_exercise_screen.dart';
import '../food/food_detail_sheet.dart';
import '../food/food_search_screen.dart';

/// The food diary: Goal − Food + Exercise = Remaining, one card per meal.
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: p.loadDayData,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _DateBar(provider: p)),
            SliverToBoxAdapter(child: _SummaryEquation(provider: p)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverList.list(children: [
                for (final m in mealTypes) _MealCard(meal: m, provider: p),
                _ExerciseCard(provider: p),
                _WaterCard(provider: p),
                _CompleteDiaryCard(provider: p),
                const SizedBox(height: 32),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Date navigation ──────────────────────────────────────────────────────────
class _DateBar extends StatelessWidget {
  final AppProvider provider;
  const _DateBar({required this.provider});

  String _label(DateTime d) {
    final today = dateOnly(DateTime.now());
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final d = provider.selectedDate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => provider.shiftDate(-1)),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: d,
                firstDate: DateTime(2015),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) provider.selectDate(picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Text(_label(d), style: context.text.titleLarge),
                if (!provider.isToday)
                  Text(DateFormat('MMMM d, y').format(d),
                      style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              ]),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => provider.shiftDate(1)),
      ]),
    );
  }
}

// ── Goal − Food + Exercise = Remaining ───────────────────────────────────────
class _SummaryEquation extends StatelessWidget {
  final AppProvider provider;
  const _SummaryEquation({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final remaining = provider.caloriesRemaining;
    Widget cell(String value, String label, {Color? color, bool bold = false}) => Expanded(
          child: Column(children: [
            FittedBox(
              child: Text(value,
                  style: TextStyle(
                      fontSize: bold ? 20 : 17, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
          ]),
        );
    Widget op(String s) => Text(s, style: TextStyle(fontSize: 16, color: c.textMuted, fontWeight: FontWeight.w600));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(children: [
          Text('Calories remaining', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            cell(fmtNum(provider.calorieGoal), 'Goal'),
            op('−'),
            cell(fmtNum(provider.caloriesConsumed), 'Food'),
            op('+'),
            cell(fmtNum(provider.caloriesBurned), 'Exercise'),
            op('='),
            cell(fmtNum(remaining), 'Remaining', color: remaining < 0 ? kDanger : kPrimary, bold: true),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _MiniMacro('Protein', provider.totalProtein, provider.user?.proteinGoalG ?? 0, kProteinColor)),
            const SizedBox(width: 12),
            Expanded(child: _MiniMacro('Carbs', provider.totalCarbs, provider.user?.carbsGoalG ?? 0, kCarbsColor)),
            const SizedBox(width: 12),
            Expanded(child: _MiniMacro('Fat', provider.totalFat, provider.user?.fatGoalG ?? 0, kFatColor)),
          ]),
        ]),
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  const _MiniMacro(this.label, this.value, this.goal, this.color);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label ${value.round()}/${goal.round()}g',
            style: TextStyle(fontSize: 11, color: context.colors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0,
            minHeight: 5,
            color: color,
            backgroundColor: context.colors.track,
          ),
        ),
      ]);
}

// ── Meal card ────────────────────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final String meal;
  final AppProvider provider;
  const _MealCard({required this.meal, required this.provider});

  void _add(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => FoodSearchScreen(mealType: meal)));

  Future<void> _menu(BuildContext context, String action) async {
    switch (action) {
      case 'quick':
        await showQuickAddSheet(context, mealType: meal);
      case 'copy':
        final from = provider.selectedDate.subtract(const Duration(days: 1));
        final n = await provider.copyMeal(meal, from);
        if (context.mounted) {
          showSnack(context, n == 0 ? 'Nothing logged for ${mealTypeLabel(meal)} yesterday' : 'Copied $n item${n == 1 ? '' : 's'} from yesterday',
              icon: n == 0 ? Icons.info_outline_rounded : Icons.check_circle_rounded);
        }
      case 'clear':
        for (final l in provider.logsForMeal(meal)) {
          await provider.removeFoodLog(l.id!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final logs = provider.logsForMeal(meal);
    final total = logs.fold(0.0, (s, l) => s + l.calories);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: mealTypeColor(meal).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                child: Icon(mealTypeIcon(meal), color: mealTypeColor(meal), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mealTypeLabel(meal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${total.round()} kcal', style: TextStyle(color: c.textMuted, fontSize: 12)),
                ]),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: c.textMuted),
                onSelected: (a) => _menu(context, a),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'quick', child: Text('Quick add calories')),
                  const PopupMenuItem(value: 'copy', child: Text('Copy from yesterday')),
                  if (logs.isNotEmpty) const PopupMenuItem(value: 'clear', child: Text('Remove all')),
                ],
              ),
            ]),
          ),
          for (final l in logs) _LogTile(log: l, provider: provider),
          InkWell(
            onTap: () => _add(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(children: [
                Icon(Icons.add_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text('Add food',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final FoodLog log;
  final AppProvider provider;
  const _LogTile({required this.log, required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dismissible(
      key: ValueKey('log_${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: kDanger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        provider.removeFoodLog(log.id!);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${log.foodName} removed'),
            action: SnackBarAction(label: 'Undo', onPressed: () => provider.addFoodLog(log.copyWith())),
          ));
      },
      child: InkWell(
        onTap: () => showFoodDetailSheet(context, food: log.toFood(), mealType: log.mealType, existing: log),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log.foodName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${log.servingText} · P ${log.protein.round()} · C ${log.carbs.round()} · F ${log.fat.round()}',
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
              ]),
            ),
            Text('${log.calories.round()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
      ),
    );
  }
}

// ── Exercise ─────────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final AppProvider provider;
  const _ExerciseCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final logs = provider.exerciseLogs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: kCarbsColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.directions_run_rounded, color: kCarbsColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Exercise', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${provider.caloriesBurned.round()} kcal burned',
                      style: TextStyle(color: c.textMuted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          for (final e in logs)
            Dismissible(
              key: ValueKey('ex_${e.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: kDanger,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              onDismissed: (_) => provider.removeExerciseLog(e.id!),
              child: ListTile(
                dense: true,
                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${e.durationMinutes} min', style: TextStyle(color: c.textMuted)),
                trailing: Text('${e.caloriesBurned.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExerciseScreen())),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(children: [
                Icon(Icons.add_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text('Add exercise',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Water ────────────────────────────────────────────────────────────────────
class _WaterCard extends StatelessWidget {
  final AppProvider provider;
  const _WaterCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final goal = provider.user?.waterGoalMl ?? 2500;
    final glasses = (goal / 250).ceil();
    final filled = provider.waterMl ~/ 250;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.water_drop_rounded, color: kWaterColor),
            const SizedBox(width: 8),
            const Expanded(child: Text('Water', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Text('${provider.waterMl} / $goal ml',
                style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < glasses.clamp(0, 16); i++)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.addWater(i < filled ? -250 * (filled - i) : 250 * (i + 1 - filled));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 38,
                  decoration: BoxDecoration(
                    color: i < filled ? kWaterColor : kWaterColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10), top: Radius.circular(4)),
                  ),
                  child: Icon(i < filled ? Icons.water_drop_rounded : Icons.add_rounded,
                      size: 16, color: i < filled ? Colors.white : kWaterColor),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ── Complete diary → 5-week projection ───────────────────────────────────────
class _CompleteDiaryCard extends StatelessWidget {
  final AppProvider provider;
  const _CompleteDiaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.foodLogs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.task_alt_rounded),
        label: const Text('Complete this entry'),
        onPressed: () {
          final projected = NutritionCalculator.projectedWeight(
            currentKg: provider.currentWeightKg,
            maintenanceKcal: provider.maintenanceCalories,
            netKcal: provider.caloriesNet,
          );
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.auto_graph_rounded, color: kPrimary, size: 36),
              title: const Text('Diary complete!'),
              content: Text(
                'If every day were like today, in 5 weeks you would weigh\n\n'
                '${projected.toStringAsFixed(1)} kg',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
            ),
          );
        },
      ),
    );
  }
}

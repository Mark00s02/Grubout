import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/nutrition_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../premium/paywall_screen.dart';
import 'weight_sheet.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _days = 7;
  List<DaySummary> _data = [];
  bool _loading = true;
  int _loadedFor = -1;
  int _logSignature = -1;

  Future<void> _load() async {
    final p = context.read<AppProvider>();
    setState(() => _loading = true);
    final data = await p.summaries(_days);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _loadedFor = _days;
    });
  }

  void _setRange(int days) {
    if (days > 7 && !requirePremium(context)) return;
    setState(() => _days = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final u = p.user;
    if (u == null) return const SizedBox.shrink();

    // Reload when today's diary changes (cheap aggregate query).
    final sig = Object.hash(p.foodLogs.length, p.caloriesConsumed.round(), p.caloriesBurned.round());
    if (_loadedFor != _days || sig != _logSignature) {
      _logSignature = sig;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    final logged = _data.where((d) => d.calories > 0).toList();
    final avgKcal = logged.isEmpty ? 0.0 : logged.fold(0.0, (s, d) => s + d.calories) / logged.length;
    final avgP = logged.isEmpty ? 0.0 : logged.fold(0.0, (s, d) => s + d.protein) / logged.length;
    final avgC = logged.isEmpty ? 0.0 : logged.fold(0.0, (s, d) => s + d.carbs) / logged.length;
    final avgF = logged.isEmpty ? 0.0 : logged.fold(0.0, (s, d) => s + d.fat) / logged.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(children: [
                Expanded(child: Text('Progress', style: context.text.headlineSmall)),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: [
                    const ButtonSegment(value: 7, label: Text('7D')),
                    ButtonSegment(value: 30, label: _RangeLabel('30D', locked: !p.isPremium)),
                    ButtonSegment(value: 90, label: _RangeLabel('90D', locked: !p.isPremium)),
                  ],
                  selected: {_days},
                  onSelectionChanged: (s) => _setRange(s.first),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Stat tiles ───────────────────────────────────────────────
              Row(children: [
                Expanded(child: _StatTile(Icons.local_fire_department_rounded, kCarbsColor, '${p.streak}', 'day streak')),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(Icons.calendar_month_rounded, kPrimary, '${p.daysLogged}', 'days logged')),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(Icons.restaurant_rounded, kProteinColor, fmtNum(avgKcal), 'avg kcal')),
              ]),
              const SizedBox(height: 14),

              // ── Weight ───────────────────────────────────────────────────
              _WeightCard(provider: p),
              const SizedBox(height: 14),

              // ── Calories chart ───────────────────────────────────────────
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('Calories', style: context.text.titleMedium)),
                    Text('Goal ${fmtNum(u.calorieGoal)}', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    child: _loading && _data.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _CaloriesChart(data: _data, goal: u.calorieGoal.toDouble()),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Macro averages ───────────────────────────────────────────
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Average macros', style: context.text.titleMedium),
                  Text('per logged day, last $_days days', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: MacroBar(label: 'Protein', value: avgP, goal: u.proteinGoalG, color: kProteinColor)),
                    const SizedBox(width: 14),
                    Expanded(child: MacroBar(label: 'Carbs', value: avgC, goal: u.carbsGoalG, color: kCarbsColor)),
                    const SizedBox(width: 14),
                    Expanded(child: MacroBar(label: 'Fat', value: avgF, goal: u.fatGoalG, color: kFatColor)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Insights ─────────────────────────────────────────────────
              _InsightsCard(data: _data, user: u, premium: p.isPremium),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeLabel extends StatelessWidget {
  final String text;
  final bool locked;
  const _RangeLabel(this.text, {required this.locked});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(text),
        if (locked) const Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.lock_rounded, size: 12)),
      ]);
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile(this.icon, this.color, this.value, this.label);

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ]),
      );
}

// ── Calories bar chart (single series + dashed goal reference) ───────────────
class _CaloriesChart extends StatelessWidget {
  final List<DaySummary> data;
  final double goal;
  const _CaloriesChart({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Round the axis up to a "nice" step so ticks read 500 / 1,000 / 1,500…
    final rawMax = math.max(goal * 1.15, data.fold(0.0, (m, d) => math.max(m, d.calories)) * 1.05);
    final step = rawMax <= 2000 ? 500.0 : (rawMax <= 4000 ? 1000.0 : 2000.0);
    final maxY = (rawMax / step).ceil() * step;
    final barWidth = data.length <= 7 ? 22.0 : (data.length <= 30 ? 7.0 : 2.5);
    final labelEvery = data.length <= 7 ? 1 : (data.length <= 30 ? 7 : 30);
    final axisStyle = TextStyle(fontSize: 11, color: c.textMuted);

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: step,
              getTitlesWidget: (v, meta) =>
                  v == meta.max ? const SizedBox.shrink() : Text(fmtNum(v), style: axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final fromEnd = data.length - 1 - i;
                if (fromEnd % labelEvery != 0) return const SizedBox.shrink();
                final d = data[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data.length <= 7 ? DateFormat('E').format(d).substring(0, 1) : DateFormat('M/d').format(d),
                      style: axisStyle),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: goal,
            color: c.textMuted,
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600),
              labelResolver: (_) => 'goal',
            ),
          ),
        ]),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.isDark ? c.surfaceAlt : const Color(0xFF14201A),
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItem: (group, _, rod, __) {
              final d = data[group.x];
              return BarTooltipItem(
                '${DateFormat('EEE, MMM d').format(d.date)}\n',
                const TextStyle(color: Colors.white70, fontSize: 12),
                children: [
                  TextSpan(
                    text: d.calories > 0 ? '${fmtNum(d.calories)} kcal' : 'Not logged',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].calories,
                width: barWidth,
                color: kPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(math.min(4, barWidth / 2))),
              ),
            ]),
        ],
      ),
    );
  }
}

// ── Weight ───────────────────────────────────────────────────────────────────
class _WeightCard extends StatelessWidget {
  final AppProvider provider;
  const _WeightCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final u = provider.user!;
    final weights = provider.weights;
    final current = provider.currentWeightKg;
    final bmi = NutritionCalculator.bmi(current, u.heightCm);
    final change = current - u.startWeightKg;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Weight', style: context.text.titleMedium),
              const SizedBox(height: 4),
              Text('${current.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg since start · goal ${u.targetWeightKg.toStringAsFixed(1)} kg',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Pill('BMI ${bmi.toStringAsFixed(1)}', color: kPrimary),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: () => showWeightSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Log'),
            ),
          ]),
        ]),
        const SizedBox(height: 16),
        if (weights.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Log your weight on a few different days to see your trend line.',
                style: TextStyle(color: c.textMuted)),
          )
        else
          SizedBox(
            height: 170,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _WeightChart(weights: weights, target: u.targetWeightKg),
            ),
          ),
      ]),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> weights;
  final double target;
  const _WeightChart({required this.weights, required this.target});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = weights.first.date;
    final spots = [
      for (final w in weights) FlSpot(w.date.difference(first).inDays.toDouble(), w.weightKg),
    ];
    final values = [...weights.map((w) => w.weightKg), target];
    final minY = (values.reduce(math.min) - 1).floorToDouble();
    final maxY = (values.reduce(math.max) + 1).ceilToDouble();
    final axisStyle = TextStyle(fontSize: 11, color: c.textMuted);

    return LineChart(LineChartData(
      minY: minY,
      maxY: maxY,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (v, meta) => (v == meta.min || v == meta.max)
                ? const SizedBox.shrink()
                : Text(v.toStringAsFixed(0), style: axisStyle),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: math.max(1, (spots.last.x / 3).ceilToDouble()),
            getTitlesWidget: (v, meta) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(DateFormat('MMM d').format(first.add(Duration(days: v.round()))), style: axisStyle),
            ),
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: target,
          color: c.textMuted,
          strokeWidth: 1.5,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600),
            labelResolver: (_) => 'goal',
          ),
        ),
      ]),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => c.isDark ? c.surfaceAlt : const Color(0xFF14201A),
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
                    '${DateFormat('MMM d').format(first.add(Duration(days: s.x.round())))}\n',
                    const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                        text: '${s.y.toStringAsFixed(1)} kg',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: kFatColor,
          barWidth: 2,
          dotData: FlDotData(
            checkToShowDot: (spot, bar) => spot == bar.spots.last,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 5,
              color: kFatColor,
              strokeWidth: 2,
              strokeColor: c.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kFatColor.withValues(alpha: 0.18), kFatColor.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    ));
  }
}

// ── Insights ─────────────────────────────────────────────────────────────────
class _InsightsCard extends StatelessWidget {
  final List<DaySummary> data;
  final AppUser user;
  final bool premium;
  const _InsightsCard({required this.data, required this.user, required this.premium});

  List<(IconData, String)> _insights() {
    final logged = data.where((d) => d.calories > 0).toList();
    if (logged.isEmpty) return [(Icons.lightbulb_outline_rounded, 'Log meals for a few days to unlock personalised insights.')];
    final out = <(IconData, String)>[];
    final onTarget = logged.where((d) => (d.calories - d.exercise - user.calorieGoal).abs() <= user.calorieGoal * 0.1).length;
    out.add((Icons.track_changes_rounded, 'You were within 10% of your calorie goal on $onTarget of ${logged.length} logged days.'));
    final proteinHit = logged.where((d) => d.protein >= user.proteinGoalG * 0.9).length;
    out.add((Icons.egg_alt_rounded,
        proteinHit >= logged.length / 2
            ? 'Great protein habits — you hit your target on $proteinHit days.'
            : 'Protein was low on ${logged.length - proteinHit} days. Try eggs, tofu, fish or chicken at breakfast.'));
    final weekend = logged.where((d) => d.date.weekday >= 6).toList();
    final weekday = logged.where((d) => d.date.weekday < 6).toList();
    if (weekend.isNotEmpty && weekday.isNotEmpty) {
      final we = weekend.fold(0.0, (s, d) => s + d.calories) / weekend.length;
      final wd = weekday.fold(0.0, (s, d) => s + d.calories) / weekday.length;
      if (we > wd * 1.15) {
        out.add((Icons.weekend_rounded, 'You eat about ${fmtNum(we - wd)} kcal more on weekends. Plan ahead for Saturday!'));
      }
    }
    final exerciseDays = logged.where((d) => d.exercise > 0).length;
    out.add((Icons.directions_run_rounded,
        exerciseDays == 0 ? 'No exercise logged yet — even a 20-minute walk counts.' : 'You exercised on $exerciseDays days. Keep moving!'));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = _insights();
    final visible = premium ? items : items.take(1).toList();
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Smart insights', style: context.text.titleMedium)),
          if (!premium) const PremiumBadge(),
        ]),
        const SizedBox(height: 10),
        for (final i in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i.$1, size: 20, color: kPrimary),
              const SizedBox(width: 10),
              Expanded(child: Text(i.$2, style: const TextStyle(height: 1.4))),
            ]),
          ),
        if (!premium && items.length > 1)
          TextButton.icon(
            onPressed: () => showPaywall(context),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: Text('Unlock ${items.length - 1} more insight${items.length - 1 == 1 ? '' : 's'}'),
          ),
        if (premium)
          Text('Based on the last ${data.length} days.', style: TextStyle(fontSize: 12, color: c.textMuted)),
      ]),
    );
  }
}

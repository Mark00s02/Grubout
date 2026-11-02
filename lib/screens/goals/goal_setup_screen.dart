import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/nutrition_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Multi-step questionnaire that produces the calorie / macro / water plan.
/// Used right after sign-up and again from Profile → "Goals & plan".
class GoalSetupScreen extends StatefulWidget {
  final bool editing;
  const GoalSetupScreen({super.key, this.editing = false});

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final _pages = PageController();
  int _step = 0;

  late GoalType _goal;
  late Sex _sex;
  late int _birthYear;
  late double _height;
  late double _weight;
  late double _target;
  late double _rate;
  late int _activity;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    final u = p.user!;
    _goal = u.goalType;
    _sex = u.sex;
    _birthYear = u.birthYear;
    _height = u.heightCm;
    _weight = widget.editing ? p.currentWeightKg : u.startWeightKg;
    _target = u.targetWeightKg;
    _rate = u.weeklyRateKg;
    _activity = u.activityLevel;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<String> get _titles => [
        "What's your main goal?",
        'Tell us about you',
        if (_goal != GoalType.maintain) 'Set your target',
        'How active are you?',
        'Your personal plan',
      ];

  int get _lastStep => _titles.length - 1;

  double get _targetClamped => switch (_goal) {
        GoalType.lose => _target.clamp(30.0, _weight).toDouble(),
        GoalType.gain => _target.clamp(_weight, 200.0).toDouble(),
        GoalType.maintain => _weight,
      };

  int get _calories => NutritionCalculator.dailyGoal(
        sex: _sex,
        weightKg: _weight,
        heightCm: _height,
        age: DateTime.now().year - _birthYear,
        activityLevel: _activity,
        goal: _goal,
        weeklyRateKg: _goal == GoalType.maintain ? 0 : _rate,
      );

  void _next() {
    HapticFeedback.selectionClick();
    if (_step <= 1 && _goal == GoalType.lose && _target >= _weight) _target = (_weight - 5).roundToDouble();
    if (_step <= 1 && _goal == GoalType.gain && _target <= _weight) _target = (_weight + 5).roundToDouble();
    if (_step < _lastStep) {
      _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
    } else {
      _pages.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _finish() async {
    final p = context.read<AppProvider>();
    final profile = p.user!.copyWith(
      goalType: _goal,
      sex: _sex,
      birthYear: _birthYear,
      heightCm: _height,
      startWeightKg: widget.editing ? p.user!.startWeightKg : _weight,
      targetWeightKg: _targetClamped,
      weeklyRateKg: _goal == GoalType.maintain ? 0 : _rate,
      activityLevel: _activity,
    );
    await p.applyGoals(profile, currentWeightKg: _weight);
    if (widget.editing && (p.weights.isEmpty || (p.currentWeightKg - _weight).abs() > 0.05)) {
      await p.logWeight(_weight, DateTime.now());
    }
    if (!mounted) return;
    if (widget.editing) {
      Navigator.pop(context);
      showSnack(context, 'Your plan has been updated');
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pages = <Widget>[
      _goalStep(),
      _aboutStep(),
      if (_goal != GoalType.maintain) _targetStep(),
      _activityStep(),
      _resultStep(),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: (_step > 0 || widget.editing)
            ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _back)
            : null,
        automaticallyImplyLeading: false,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: (_step + 1) / _titles.length),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: c.track),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: SizedBox(
              width: double.infinity,
              child: Text(_titles[_step.clamp(0, _lastStep)], style: context.text.headlineSmall),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_step == _lastStep ? (widget.editing ? 'Save plan' : 'Start my journey') : 'Continue'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Steps ──────────────────────────────────────────────────────────────────
  Widget _goalStep() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _OptionCard(
            icon: Icons.trending_down_rounded,
            title: 'Lose weight',
            subtitle: 'Burn fat while keeping energy up',
            selected: _goal == GoalType.lose,
            onTap: () => setState(() => _goal = GoalType.lose),
          ),
          _OptionCard(
            icon: Icons.balance_rounded,
            title: 'Maintain weight',
            subtitle: 'Eat better and feel great',
            selected: _goal == GoalType.maintain,
            onTap: () => setState(() => _goal = GoalType.maintain),
          ),
          _OptionCard(
            icon: Icons.trending_up_rounded,
            title: 'Gain weight',
            subtitle: 'Build muscle and strength',
            selected: _goal == GoalType.gain,
            onTap: () => setState(() => _goal = GoalType.gain),
          ),
        ],
      );

  Widget _aboutStep() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Label('Sex (used for your metabolic rate)'),
          SegmentedButton<Sex>(
            segments: const [
              ButtonSegment(value: Sex.female, label: Text('Female'), icon: Icon(Icons.female_rounded)),
              ButtonSegment(value: Sex.male, label: Text('Male'), icon: Icon(Icons.male_rounded)),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
            style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
          ),
          const SizedBox(height: 24),
          _ValueSlider(
            label: 'Age',
            value: (DateTime.now().year - _birthYear).toDouble(),
            min: 13,
            max: 90,
            divisions: 77,
            format: (v) => '${v.round()} yrs',
            onChanged: (v) => setState(() => _birthYear = DateTime.now().year - v.round()),
          ),
          _ValueSlider(
            label: 'Height',
            value: _height,
            min: 120,
            max: 220,
            divisions: 100,
            format: (v) => '${v.round()} cm',
            onChanged: (v) => setState(() => _height = v.roundToDouble()),
          ),
          _ValueSlider(
            label: 'Current weight',
            value: _weight,
            min: 30,
            max: 200,
            divisions: 340,
            format: (v) => '${v.toStringAsFixed(1)} kg',
            onChanged: (v) => setState(() => _weight = (v * 2).round() / 2),
          ),
          const SizedBox(height: 8),
          _BmiChip(weight: _weight, height: _height),
        ],
      );

  Widget _targetStep() {
    final losing = _goal == GoalType.lose;
    final min = losing ? 30.0 : _weight;
    final max = losing ? _weight : 200.0;
    final target = _target.clamp(min, max).toDouble();
    final weeks = NutritionCalculator.weeksToGoal(_weight, target, _rate);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _ValueSlider(
          label: 'Goal weight',
          value: target,
          min: min,
          max: max,
          divisions: ((max - min) * 2).round().clamp(1, 400),
          format: (v) => '${v.toStringAsFixed(1)} kg',
          onChanged: (v) => setState(() => _target = (v * 2).round() / 2),
        ),
        const SizedBox(height: 8),
        _Label('Weekly pace'),
        for (final r in const [0.25, 0.5, 0.75, 1.0])
          _OptionCard(
            icon: r <= 0.25
                ? Icons.spa_rounded
                : r <= 0.5
                    ? Icons.directions_walk_rounded
                    : r <= 0.75
                        ? Icons.directions_run_rounded
                        : Icons.bolt_rounded,
            title: '${r.toString().replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} kg per week',
            subtitle: r <= 0.25
                ? 'Gentle — easiest to sustain'
                : r <= 0.5
                    ? 'Recommended'
                    : r <= 0.75
                        ? 'Ambitious'
                        : 'Aggressive — not for everyone',
            selected: _rate == r,
            compact: true,
            onTap: () => setState(() => _rate = r),
          ),
        if (weeks != null && weeks > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'You could reach ${target.toStringAsFixed(1)} kg around '
              '${DateFormat('MMMM d, y').format(DateTime.now().add(Duration(days: weeks * 7)))}.',
              style: TextStyle(color: context.colors.textMuted, height: 1.4),
            ),
          ),
      ],
    );
  }

  Widget _activityStep() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (var i = 0; i < activityLevels.length; i++)
            _OptionCard(
              icon: const [
                Icons.weekend_rounded,
                Icons.directions_walk_rounded,
                Icons.directions_bike_rounded,
                Icons.fitness_center_rounded,
                Icons.sports_gymnastics_rounded,
              ][i],
              title: activityLevels[i].$1,
              subtitle: activityLevels[i].$2,
              selected: _activity == i,
              compact: true,
              onTap: () => setState(() => _activity = i),
            ),
        ],
      );

  Widget _resultStep() {
    final c = context.colors;
    final kcal = _calories;
    final u = context.read<AppProvider>().user!;
    final p = kcal * u.proteinPct / 400, cb = kcal * u.carbsPct / 400, f = kcal * u.fatPct / 900;
    final water = NutritionCalculator.waterGoalMl(_weight);
    final weeks = _goal == GoalType.maintain ? null : NutritionCalculator.weeksToGoal(_weight, _targetClamped, _rate);
    final minHit = kcal <= NutritionCalculator.minimumCalories(_sex);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppCard(
          gradient: const LinearGradient(
              colors: [kPrimaryLight, kPrimary, kPrimaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Text('Daily calorie goal', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: kcal.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(fmtNum(v),
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ),
            const Text('kcal per day', style: TextStyle(color: Colors.white70)),
            if (weeks != null && weeks > 0) ...[
              const SizedBox(height: 14),
              Pill('Goal by ${DateFormat('MMM d, y').format(DateTime.now().add(Duration(days: weeks * 7)))}',
                  icon: Icons.flag_rounded, color: Colors.white),
            ],
          ]),
        ),
        if (minHit)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'We kept your goal at the safe minimum. Consider a gentler pace or more activity.',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daily macro targets', style: context.text.titleMedium),
            const SizedBox(height: 16),
            Row(children: [
              _MacroTarget('Protein', p, kProteinColor),
              _MacroTarget('Carbs', cb, kCarbsColor),
              _MacroTarget('Fat', f, kFatColor),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(children: [
            const Icon(Icons.water_drop_rounded, color: kWaterColor, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${(water / 1000).toStringAsFixed(2)} L water', style: context.text.titleMedium),
                Text('${water ~/ 250} glasses a day', style: TextStyle(color: c.textMuted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(
          'Estimates use the Mifflin-St Jeor equation. GrubOut is not medical advice — '
          'talk to a healthcare professional before major diet changes.',
          style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4),
        ),
      ],
    );
  }
}

// ── Small building blocks ────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600)),
      );
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withValues(alpha: 0.1) : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? kPrimary : c.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Row(children: [
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(
                  color: selected ? kPrimary : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: selected ? Colors.white : c.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 13)),
                ]),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: kPrimary),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ValueSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const _ValueSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _Label(label)),
          Text(format(v), style: context.text.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ]),
        Row(children: [
          StepperButton(icon: Icons.remove_rounded, onTap: () => onChanged((v - (max - min) / divisions).clamp(min, max))),
          Expanded(
            child: Slider(value: v, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
          StepperButton(icon: Icons.add_rounded, onTap: () => onChanged((v + (max - min) / divisions).clamp(min, max))),
        ]),
      ]),
    );
  }
}

class _BmiChip extends StatelessWidget {
  final double weight;
  final double height;
  const _BmiChip({required this.weight, required this.height});

  @override
  Widget build(BuildContext context) {
    final bmi = NutritionCalculator.bmi(weight, height);
    final cat = NutritionCalculator.bmiCategory(bmi);
    final color = cat == 'Healthy' ? kPrimary : (cat == 'Underweight' ? kProteinColor : kCarbsColor);
    return Align(
      alignment: Alignment.centerLeft,
      child: Pill('BMI ${bmi.toStringAsFixed(1)} · $cat', icon: Icons.monitor_weight_outlined, color: color),
    );
  }
}

class _MacroTarget extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;
  const _MacroTarget(this.label, this.grams, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text('${grams.round()}g', style: context.text.titleLarge),
          Text(label, style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
        ]),
      );
}

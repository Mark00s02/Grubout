import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

Future<void> showWeightSheet(BuildContext context, {DateTime? date}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WeightSheet(date: date ?? DateTime.now()),
    );

class _WeightSheet extends StatefulWidget {
  final DateTime date;
  const _WeightSheet({required this.date});

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late double _kg = context.read<AppProvider>().currentWeightKg;
  late DateTime _date = dateOnly(widget.date);

  void _nudge(double d) {
    HapticFeedback.selectionClick();
    setState(() => _kg = double.parse((_kg + d).clamp(20, 300).toStringAsFixed(1)));
  }

  Future<void> _save() async {
    final p = context.read<AppProvider>();
    final previous = p.currentWeightKg;
    await p.logWeight(_kg, _date);
    if (!mounted) return;
    Navigator.pop(context);
    final diff = _kg - previous;
    final u = p.user!;
    final toGo = (_kg - u.targetWeightKg).abs();
    String msg;
    if (p.weights.length <= 1 || diff.abs() < 0.05) {
      msg = 'Weight saved · ${_kg.toStringAsFixed(1)} kg';
    } else if ((u.goalType == GoalType.lose && diff < 0) || (u.goalType == GoalType.gain && diff > 0)) {
      msg = 'Nice! ${diff.abs().toStringAsFixed(1)} kg closer · ${toGo.toStringAsFixed(1)} kg to go 🎉';
    } else {
      msg = 'Weight saved. Fluctuations are normal — keep going 💪';
    }
    showSnack(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Log weight', style: context.text.titleLarge),
        const SizedBox(height: 4),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today_rounded, size: 16),
          label: Text(DateUtils.isSameDay(_date, DateTime.now()) ? 'Today' : DateFormat('EEE, MMM d').format(_date)),
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2015),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _date = d);
          },
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          StepperButton(icon: Icons.remove_rounded, onTap: () => _nudge(-0.1)),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () async {
              final ctrl = TextEditingController(text: _kg.toStringAsFixed(1));
              final v = await showDialog<double>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Enter weight (kg)'),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              if (v != null && v > 20 && v < 300) setState(() => _kg = v);
            },
            child: Column(children: [
              Text(_kg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Text('kg · tap to type', style: TextStyle(color: c.textMuted)),
            ]),
          ),
          const SizedBox(width: 20),
          StepperButton(icon: Icons.add_rounded, onTap: () => _nudge(0.1)),
        ]),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('Save'))),
      ]),
    );
  }
}

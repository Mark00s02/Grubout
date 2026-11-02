import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../premium/paywall_screen.dart';

const _fastColor = Color(0xFF8E5CD9);
const _plans = [
  (13, 'Circadian', '13:11 · gentle start'),
  (16, '16:8', 'Most popular'),
  (18, '18:6', 'Intermediate'),
  (20, '20:4', 'Advanced'),
];

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  int _hours = 16;
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.read<AppProvider>().activeFast != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  String _hms(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final c = context.colors;
    final active = p.activeFast;

    return Scaffold(
      appBar: AppBar(title: const Text('Fasting')),
      body: !p.isPremium
          ? EmptyState(
              icon: Icons.timer_rounded,
              title: 'Intermittent fasting',
              message: 'Track 13–20 hour fasts with a live timer and history. Included with Premium.',
              action: FilledButton.icon(
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Unlock with Premium'),
                onPressed: () => showPaywall(context),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: ProgressRing(
                    value: active?.progress ?? 0,
                    size: 250,
                    stroke: 18,
                    color: _fastColor,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(active == null ? 'Ready to fast' : (active.completed ? 'Goal reached! 🎉' : 'Fasting'),
                          style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(_hms(active?.elapsed ?? Duration.zero),
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])),
                      if (active != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          active.completed
                              ? '${active.targetHours}h goal complete'
                              : 'Ends ${DateFormat('EEE h:mm a').format(active.start.add(Duration(hours: active.targetHours)))}',
                          style: TextStyle(color: c.textMuted, fontSize: 13),
                        ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
                if (active == null) ...[
                  Text('Choose your fast', style: context.text.titleMedium),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      for (final plan in _plans)
                        _PlanTile(
                          hours: plan.$1,
                          name: plan.$2,
                          note: plan.$3,
                          selected: _hours == plan.$1,
                          onTap: () => setState(() => _hours = plan.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _fastColor),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Start $_hours-hour fast'),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      p.startFast(_hours);
                    },
                  ),
                ] else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: active.completed ? kPrimary : kDanger),
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(active.completed ? 'Finish fast' : 'End fast early'),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final done = active.completed;
                      await p.endFast();
                      if (context.mounted) {
                        showSnack(context, done ? 'Fast complete — amazing discipline! 🏆' : 'Fast ended. Every hour counts!');
                      }
                    },
                  ),
                const SizedBox(height: 28),
                if (p.fasts.where((f) => !f.isActive).isNotEmpty) ...[
                  Text('History', style: context.text.titleMedium),
                  const SizedBox(height: 8),
                  for (final f in p.fasts.where((f) => !f.isActive))
                    Dismissible(
                      key: ValueKey('fast_${f.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: kDanger,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => p.deleteFast(f.id!),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          f.completed ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                          color: f.completed ? kPrimary : c.textMuted,
                        ),
                        title: Text(
                            '${f.elapsed.inHours}h ${f.elapsed.inMinutes % 60}m of ${f.targetHours}h',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(f.start),
                            style: TextStyle(color: c.textMuted)),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Fasting is not suitable for everyone. Avoid it if you are pregnant, breastfeeding, '
                  'diabetic, or have a history of eating disorders, and talk to your doctor first.',
                  style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4),
                ),
              ],
            ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final int hours;
  final String name;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({required this.hours, required this.name, required this.note, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _fastColor.withValues(alpha: 0.12) : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _fastColor : c.border, width: selected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(note, style: TextStyle(fontSize: 12, color: c.textMuted)),
        ]),
      ),
    );
  }
}

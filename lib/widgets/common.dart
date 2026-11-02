import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showSnack(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: kPrimaryLight, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      duration: const Duration(seconds: 2),
    ));
}

String fmtNum(num v) {
  final s = v.round().toString();
  return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

// ── Card ─────────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: c.isDark || gradient != null ? null : Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: c.isDark
            ? null
            : const [BoxShadow(color: Color(0x0A0F2A1A), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader(this.title,
      {super.key, this.action, this.onAction, this.padding = const EdgeInsets.fromLTRB(20, 24, 12, 10)});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(child: Text(title, style: context.text.titleMedium?.copyWith(fontSize: 18))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

// ── Progress ring ────────────────────────────────────────────────────────────
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color? overColor;
  final Color? trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 160,
    this.stroke = 14,
    this.color = kPrimary,
    this.overColor,
    this.trackColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final track = trackColor ?? context.colors.track;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.isFinite ? value : 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, v > 1 && overColor != null ? overColor! : color, track),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.value, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, base..color = track);
    final sweep = math.pi * 2 * value.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(r, -math.pi / 2, sweep, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

// ── Macro bar ────────────────────────────────────────────────────────────────
class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final String unit;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = goal > 0 ? (value / goal) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 7,
            color: pct > 1.05 ? kDanger : color,
            backgroundColor: c.track,
          ),
        ),
      ),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: c.text, fontWeight: FontWeight.w700),
          children: [
            TextSpan(text: '${value.round()}'),
            TextSpan(
                text: ' / ${goal.round()}$unit',
                style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ]);
  }
}

// ── Pill / badge ─────────────────────────────────────────────────────────────
class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final bool filled;

  const Pill(this.text, {super.key, this.icon, this.color = kPrimary, this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
        ]),
      );
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});
  @override
  Widget build(BuildContext context) =>
      const Pill('PREMIUM', icon: Icons.workspace_premium_rounded, color: kGold, filled: true);
}

// ── Empty state ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: kPrimary),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: context.text.titleMedium),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, height: 1.4)),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    );
  }
}

// ── Network image with branded placeholder ───────────────────────────────────
class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackEmoji;

  const NetImage(this.url,
      {super.key, this.width, this.height, this.fit = BoxFit.cover, this.fallbackEmoji = '🍽️'});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget fallback() => Container(
          width: width,
          height: height,
          color: c.surfaceAlt,
          alignment: Alignment.center,
          child: Text(fallbackEmoji, style: const TextStyle(fontSize: 36)),
        );
    if (url == null || url!.isEmpty) return fallback();
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => Container(width: width, height: height, color: c.surfaceAlt),
      errorWidget: (_, __, ___) => fallback(),
    );
  }
}

// ── Brand mark ───────────────────────────────────────────────────────────────
class GrubOutMark extends StatelessWidget {
  final double size;
  const GrubOutMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset('assets/icon/app_icon.png', width: size, height: size),
      );
}

class GrubOutLogo extends StatelessWidget {
  final double size;
  final bool tagline;
  const GrubOutLogo({super.key, this.size = 1.0, this.tagline = true});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GrubOutMark(size: 76 * size),
      SizedBox(height: 16 * size),
      RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 34 * size, letterSpacing: -1, color: c.isDark ? kPrimaryLight : kPrimary),
          children: const [
            TextSpan(text: 'grub', style: TextStyle(fontWeight: FontWeight.w900)),
            TextSpan(text: 'Out', style: TextStyle(fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      if (tagline) ...[
        SizedBox(height: 4 * size),
        Text('Eat smart. Live better.',
            style: TextStyle(color: c.textMuted, fontSize: 14 * size, fontWeight: FontWeight.w500)),
      ],
    ]);
  }
}

// ── Number stepper used in sheets ────────────────────────────────────────────
class StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const StepperButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.surfaceAlt,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 20)),
        ),
      );
}

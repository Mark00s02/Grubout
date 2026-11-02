import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String emoji;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.emoji = '🍽️',
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: NetImage(imageUrl, width: double.infinity, fallbackEmoji: emoji),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ]),
      );
}

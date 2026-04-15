import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool large;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = large ? 160.0 : 110.0;
    final h = large ? 180.0 : 130.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: recipe.color,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ──
            _RecipeImage(recipe: recipe),

            // ── Gradient + name ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: large ? 13 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (large)
                      Text(
                        '${recipe.caloriesPerServing} cal/serving',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tries the hardcoded imageUrl first; if null or broken, queries TheMealDB.
class _RecipeImage extends StatefulWidget {
  final Recipe recipe;
  const _RecipeImage({required this.recipe});

  @override
  State<_RecipeImage> createState() => _RecipeImageState();
}

class _RecipeImageState extends State<_RecipeImage> {
  String? _url;
  bool _fetched = false;

  @override
  void initState() {
    super.initState();
    _url = widget.recipe.imageUrl;
    if (_url == null) _fetchFromApi();
    else _fetched = true;
  }

  Future<void> _fetchFromApi() async {
    try {
      final q = Uri.encodeComponent(widget.recipe.name);
      final res = await http
          .get(Uri.parse(
              'https://www.themealdb.com/api/json/v1/1/search.php?s=$q'))
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final meals = data['meals'] as List?;
      setState(() {
        _url = meals?.isNotEmpty == true
            ? meals!.first['strMealThumb'] as String?
            : null;
        _fetched = true;
      });
    } catch (_) {
      if (mounted) setState(() => _fetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_fetched) {
      return Container(color: widget.recipe.color);
    }
    if (_url != null) {
      return CachedNetworkImage(
        imageUrl: _url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: widget.recipe.color),
        errorWidget: (_, __, ___) => _ColorFallback(recipe: widget.recipe),
      );
    }
    return _ColorFallback(recipe: widget.recipe);
  }
}

class _ColorFallback extends StatelessWidget {
  final Recipe recipe;
  const _ColorFallback({required this.recipe});

  @override
  Widget build(BuildContext context) => Container(
        color: recipe.color,
        child: Center(
          child: Icon(Icons.restaurant, color: Colors.white70, size: 40),
        ),
      );
}

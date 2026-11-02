import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/models.dart';
import '../../services/food_api_service.dart';
import 'create_food_screen.dart';
import 'food_detail_sheet.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String mealType;
  const BarcodeScannerScreen({super.key, required this.mealType});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (code == null) return;
    setState(() {
      _busy = true;
      _status = 'Looking up $code…';
    });
    HapticFeedback.mediumImpact();
    await _controller.stop();
    final food = await FoodApiService().lookupBarcode(code);
    if (!mounted) return;

    if (food == null || food.caloriesPer100g <= 0) {
      final create = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Product not found'),
          content: Text(food == null
              ? "We couldn't find barcode $code. You can add it yourself from its nutrition label."
              : '${food.name} has no calorie data yet. Add it from its nutrition label?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Scan again')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create food')),
          ],
        ),
      );
      if (!mounted) return;
      if (create == true) {
        final created = await Navigator.push<FoodSearchResult>(
            context, MaterialPageRoute(builder: (_) => CreateFoodScreen(initialName: food?.name ?? '')));
        if (!mounted) return;
        if (created != null) {
          final added = await showFoodDetailSheet(context, food: created, mealType: widget.mealType);
          if (mounted && added == true) Navigator.pop(context, true);
          return;
        }
      }
      _resume();
      return;
    }

    final added = await showFoodDetailSheet(context, food: food, mealType: widget.mealType);
    if (!mounted) return;
    if (added == true) {
      Navigator.pop(context, true);
    } else {
      _resume();
    }
  }

  void _resume() {
    setState(() {
      _busy = false;
      _status = null;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan barcode', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Camera access is off. Enable it in Settings → GrubOut → Camera to scan barcodes.'
                    : 'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
        // Viewfinder
        Center(
          child: Container(
            width: 280,
            height: 170,
            decoration: BoxDecoration(
              border: Border.all(color: kPrimaryLight, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              if (_busy)
                const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _status ?? 'Point your camera at the barcode on the package',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs — create these as auto-renewable subscriptions (same
/// subscription group) in App Store Connect → your app → Subscriptions.
const kPremiumMonthlyId = 'grubout_premium_monthly';
const kPremiumYearlyId = 'grubout_premium_yearly';
const kPremiumProductIds = {kPremiumMonthlyId, kPremiumYearlyId};

/// Thin wrapper around the App Store / Google Play billing APIs.
class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Called whenever a purchase or restore grants premium.
  void Function()? onPremiumGranted;

  bool storeAvailable = false;
  bool loading = false;
  bool purchasing = false;
  String? error;
  List<ProductDetails> products = [];

  ProductDetails? get monthly => products.where((p) => p.id == kPremiumMonthlyId).firstOrNull;
  ProductDetails? get yearly => products.where((p) => p.id == kPremiumYearlyId).firstOrNull;

  Future<void> init() async {
    if (_sub != null || kIsWeb) return;
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      error = e.toString();
      purchasing = false;
      notifyListeners();
    });
  }

  Future<void> loadProducts() async {
    await init();
    loading = true;
    error = null;
    notifyListeners();
    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final res = await _iap.queryProductDetails(kPremiumProductIds);
        products = res.productDetails;
        if (products.isEmpty) {
          error = 'Subscriptions are not available yet. They appear once the products '
              'are approved in App Store Connect (or in a TestFlight sandbox build).';
        }
      } else {
        error = 'The store is not available on this device.';
      }
    } catch (e) {
      error = 'Could not reach the store: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    purchasing = true;
    error = null;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      purchasing = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> restore() async {
    await init();
    purchasing = true;
    error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      error = e.toString();
    }
    // Restore emits nothing if there is nothing to restore.
    Future.delayed(const Duration(seconds: 4), () {
      if (purchasing) {
        purchasing = false;
        notifyListeners();
      }
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (kPremiumProductIds.contains(p.productID)) onPremiumGranted?.call();
          purchasing = false;
        case PurchaseStatus.error:
          error = p.error?.message ?? 'Purchase failed';
          purchasing = false;
        case PurchaseStatus.canceled:
          purchasing = false;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// import 'dart:async';
// import 'package:in_app_purchase/in_app_purchase.dart';
//
// class GooglePlayBillingService {
//   static final GooglePlayBillingService _instance = GooglePlayBillingService._internal();
//   factory GooglePlayBillingService() => _instance;
//   GooglePlayBillingService._internal();
//
//   final InAppPurchase _iap = InAppPurchase.instance;
//   StreamSubscription<List<PurchaseDetails>>? _subscription;
//
//   static const Map<String, String> planToProductId = {
//     'startup': 'chat_startup_monthly',
//     'growth': 'chat_growth_monthly',
//     'enterprise': 'chat_enterprise_monthly',
//   };
//
//   bool _isAvailable = false;
//   bool get isAvailable => _isAvailable;
//
//   // ✅ Completer للانتظار — أفضل من StreamController للاستخدام مرة واحدة
//   Completer<PurchaseDetails>? _purchaseCompleter;
//
//   Future<bool> initialize() async {
//     try {
//       _isAvailable = await _iap.isAvailable();
//       if (!_isAvailable) return false;
//
//       _subscription = _iap.purchaseStream.listen(
//         _handlePurchaseUpdates,
//         onDone: () => _subscription?.cancel(),
//         onError: (error) => print('❌ IAP Stream Error: $error'),
//       );
//
//       return true;
//     } catch (e) {
//       _isAvailable = false;
//       return false;
//     }
//   }
//
//   Future<List<ProductDetails>> fetchProductDetails() async {
//     if (!_isAvailable) throw Exception('Billing not available');
//
//     final productIds = planToProductId.values.toSet();
//     final response = await _iap.queryProductDetails(productIds);
//
//     if (response.productDetails.isEmpty) {
//       throw Exception('No products found');
//     }
//
//     return response.productDetails;
//   }
//
//   // ✅ شراء مع انتظار النتيجة — الحل الجذري
//   Future<PurchaseDetails> purchasePlan(String planId) async {
//     final productId = planToProductId[planId];
//     if (productId == null) throw Exception('Unknown plan: $planId');
//
//     final products = await fetchProductDetails();
//     final product = products.firstWhere(
//           (p) => p.id == productId,
//       orElse: () => throw Exception('Product not found'),
//     );
//
//     // ✅ إنشاء Completer جديد قبل كل عملية شراء
//     _purchaseCompleter = Completer<PurchaseDetails>();
//
//     final purchaseParam = PurchaseParam(productDetails: product);
//     await _iap.buyNonConsumable(purchaseParam: purchaseParam);
//
//     // ✅ انتظار النتيجة من _handlePurchaseUpdates
//     return await _purchaseCompleter!.future.timeout(
//       const Duration(seconds: 60),
//       onTimeout: () {
//         _purchaseCompleter = null;
//         throw TimeoutException('انتهت مهلة الشراء');
//       },
//     );
//   }
//
//   void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
//     for (final purchase in purchases) {
//       print('📦 Purchase Update: ${purchase.productID} — Status: ${purchase.status}');
//
//       // ✅ إكمال الـ Completer إذا كان موجوداً ولم يُكمل بعد
//       if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
//         _purchaseCompleter!.complete(purchase);
//         _purchaseCompleter = null;
//       }
//
//       switch (purchase.status) {
//         case PurchaseStatus.purchased:
//           print('✅ شراء ناجح: ${purchase.productID}');
//           _verifyPurchase(purchase);
//           break;
//         case PurchaseStatus.pending:
//           print('⏳ شراء معلق: ${purchase.productID}');
//           break;
//         case PurchaseStatus.error:
//           print('❌ خطأ: ${purchase.error?.message}');
//           break;
//         case PurchaseStatus.restored:
//           print('🔄 مستعاد: ${purchase.productID}');
//           break;
//         case PurchaseStatus.canceled:
//           print('🚫 ملغى');
//           break;
//       }
//     }
//   }
//
//   Future<void> _verifyPurchase(PurchaseDetails purchase) async {
//     if (purchase.pendingCompletePurchase) {
//       await _iap.completePurchase(purchase);
//       print('✅ تم إكمال الشراء');
//     }
//   }
//
//   Future<void> restorePurchases() async {
//     await _iap.restorePurchases();
//   }
//
//   void dispose() {
//     _subscription?.cancel();
//     _purchaseCompleter = null;
//   }
// }

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class GooglePlayBillingService {
  static final GooglePlayBillingService _instance =
      GooglePlayBillingService._internal();

  factory GooglePlayBillingService() => _instance;

  GooglePlayBillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const Map<String, String> planToProductId = {
    'startup': 'chat_startup_v2',
    'growth': 'chat_growth_v3',
    'enterprise': 'chat_enterprise',
  };

  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  Completer<PurchaseDetails>? _purchaseCompleter;

  String? _pendingProductId;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        print('❌ Google Play Billing غير متاح');
        return false;
      }

      await _subscription?.cancel();

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          print('❌ IAP Stream Error: $error');

          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.completeError(error);
          }

          _purchaseCompleter = null;
          _pendingProductId = null;
        },
      );

      print('✅ Google Play Billing initialized');

      return true;
    } catch (e) {
      print('❌ Billing initialization error: $e');

      _isAvailable = false;

      return false;
    }
  }

  Future<List<ProductDetails>> fetchProductDetails() async {
    if (!_isAvailable) {
      throw Exception('Billing not available');
    }

    final productIds = planToProductId.values.toSet();

    final response = await _iap.queryProductDetails(productIds);

    print('🔍 Requested products: $productIds');
    print(
        '🔍 Found products: ${response.productDetails.map((e) => e.id).toList()}');
    print('🔍 Not found products: ${response.notFoundIDs}');

    if (response.error != null) {
      print('❌ Product query error: ${response.error}');
    }

    if (response.productDetails.isEmpty) {
      throw Exception(
        'No products found. notFoundIDs=${response.notFoundIDs}',
      );
    }

    return response.productDetails;
  }

  Future<PurchaseDetails> purchasePlan(String planId) async {
    if (!_isAvailable) {
      throw Exception('Google Play Billing غير متاح');
    }

    final productId = planToProductId[planId];

    if (productId == null) {
      throw Exception('Unknown plan: $planId');
    }

    print('🛒 Starting purchase');
    print('🛒 Plan: $planId');
    print('🛒 Expected Product ID: $productId');

    final products = await fetchProductDetails();

    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () {
        throw Exception(
          'Product "$productId" not returned by Google Play',
        );
      },
    );

    print('✅ Product found: ${product.id}');
    print('✅ Title: ${product.title}');
    print('✅ Price: ${product.price}');

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      throw Exception('هناك عملية شراء أخرى قيد التنفيذ');
    }

    _purchaseCompleter = Completer<PurchaseDetails>();
    _pendingProductId = productId;

    final purchaseParam = PurchaseParam(
      productDetails: product,
    );

    // ✅ استخدام buyConsumable مع autoConsume: true للاستهلاك التلقائي
    final launched = await _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true, // ✅ الاستهلاك التلقائي فور الشراء
    );

    print('🛒 Billing flow launched: $launched');

    if (!launched) {
      _purchaseCompleter = null;
      _pendingProductId = null;

      throw Exception('Google Play رفض بدء عملية الشراء');
    }

    try {
      return await _purchaseCompleter!.future.timeout(
        const Duration(seconds: 30), // ✅ تقليل المهلة من 90 إلى 30 ثانية
      );
    } on TimeoutException {
      _purchaseCompleter = null;
      _pendingProductId = null;

      throw TimeoutException(
        'انتهت مهلة انتظار نتيجة Google Play',
      );
    }
  }

  // ✅ استهلاك الشراء بعد التحقق من Backend
  Future<void> consumePurchase(PurchaseDetails purchase) async {
    try {
      print('🔄 Consuming purchase: ${purchase.productID}');
      await _iap.completePurchase(purchase);
      print('✅ Purchase consumed successfully');
    } catch (e) {
      print('❌ Error consuming purchase: $e');
      // لا نرمي خطأ هنا لأن الاستهلاك ليس ضرورياً لنجاح العملية
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    print('──────────────────────────────');
    print('📦 Purchase stream event');
    print('📦 Count: ${purchases.length}');
    print('──────────────────────────────');

    for (final purchase in purchases) {
      final purchaseToken = purchase.verificationData.serverVerificationData;

      print('📦 Runtime type: ${purchase.runtimeType}');
      print('📦 Status: ${purchase.status}');
      print('📦 Product ID: "${purchase.productID}"');
      print('📦 Purchase ID: "${purchase.purchaseID}"');
      print(
        '📦 Verification source: '
        '${purchase.verificationData.source}',
      );
      print(
        '📦 Server verification length: '
        '${purchaseToken.length}',
      );
      print(
        '📦 Pending complete: '
        '${purchase.pendingCompletePurchase}',
      );
      print(
        '📦 Error code: ${purchase.error?.code}',
      );
      print(
        '📦 Error message: ${purchase.error?.message}',
      );

      /*
       * مهم:
       * in_app_purchase_android يمكن في بعض الحالات أن يرسل
       * PurchaseDetails فارغ مع status=error.
       *
       * إذا كان error.code == 7 (Item Already Owned)، نعتبره خطأ حقيقي
       * وننهي الـ completer.
       */
      final hasRealPurchaseData =
          purchase.productID.isNotEmpty && purchaseToken.isNotEmpty;

      if (!hasRealPurchaseData) {
        // ✅ معالجة خاصة لـ Item Already Owned
        if (purchase.status == PurchaseStatus.error &&
            (purchase.error?.code == 7 ||
                purchase.error?.message ==
                    'BillingResponse.itemAlreadyOwned')) {
          print('⚠️ Item Already Owned (responseCode: 7)');
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.completeError(
              Exception(
                  'لقد اشتريت هذا المنتج بالفعل. يمكنك استعادة اشتراكك من الإعدادات.'),
            );
          }
          _purchaseCompleter = null;
          _pendingProductId = null;
          return;
        }

        print(
          '⚠️ تجاهل PurchaseDetails فارغ. '
          'بانتظار event يحتوي بيانات الشراء الحقيقية.',
        );

        continue;
      }

      /*
       * إذا عندنا عملية شراء حالية،
       * لازم يكون المنتج هو نفسه الذي بدأنا شراءه.
       */
      if (_pendingProductId != null &&
          purchase.productID != _pendingProductId) {
        print(
          '⚠️ Purchase لمنتج آخر: '
          '${purchase.productID}. '
          'المتوقع: $_pendingProductId',
        );

        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.purchased:
          print('✅ شراء حقيقي ناجح: ${purchase.productID}');

          /*
           * لا تعمل completePurchase هنا.
           *
           * أولاً أرسل purchaseToken للسيرفر.
           * وبعد نجاح التحقق من السيرفر،
           * اعمل completePurchase.
           */

          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(purchase);
          }

          _purchaseCompleter = null;
          _pendingProductId = null;

          break;

        case PurchaseStatus.restored:
          print('🔄 Purchase restored: ${purchase.productID}');

          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(purchase);
          }

          _purchaseCompleter = null;
          _pendingProductId = null;

          break;

        case PurchaseStatus.pending:
          print('⏳ Purchase pending: ${purchase.productID}');
          break;

        case PurchaseStatus.error:
          print(
            '❌ Purchase error: '
            '${purchase.error?.code} - '
            '${purchase.error?.message}',
          );

          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(purchase);
          }

          _purchaseCompleter = null;
          _pendingProductId = null;

          break;

        case PurchaseStatus.canceled:
          print('🚫 Purchase canceled');

          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(purchase);
          }

          _purchaseCompleter = null;
          _pendingProductId = null;

          break;
      }
    }
  }

  /*
   * استدعِ هذه الدالة فقط بعد أن يقول Laravel
   * إن Google تحقق من الاشتراك بنجاح.
   */
  Future<void> completeVerifiedPurchase(
    PurchaseDetails purchase,
  ) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);

      print(
        '✅ Purchase completed/acknowledged: '
        '${purchase.productID}',
      );
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();

    _subscription = null;
    _purchaseCompleter = null;
    _pendingProductId = null;
  }
}

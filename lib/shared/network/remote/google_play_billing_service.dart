
//
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
//   // ✅ Product IDs — تأكد من التطابق التام مع Play Console
//   static const Map<String, String> planToProductId = {
//     'startup': 'chat_startup_monthly',
//     'growth': 'chat_growth_monthly',
//     'enterprise': 'chat_enterprise_monthly',
//   };
//
//   bool _isAvailable = false;
//   bool get isAvailable => _isAvailable;
//
//   // ✅ تهيئة صحيحة مع await
//   Future<bool> initialize() async {
//     try {
//       _isAvailable = await _iap.isAvailable();
//
//       if (!_isAvailable) {
//         print('❌ Google Play Billing غير متاح');
//         print('💡 تأكد من:');
//         print('   1. التطبيق مثبت من Play Store');
//         print('   2. حسابك مسجل في المختبرين');
//         print('   3. الاشتراكات مفعّلة منذ 24 ساعة');
//         return false;
//       }
//
//       print('✅ Google Play Billing متاح');
//
//       _subscription = _iap.purchaseStream.listen(
//         _handlePurchaseUpdates,
//         onDone: () => _subscription?.cancel(),
//         onError: (error) => print('❌ IAP Stream Error: $error'),
//       );
//
//       return true;
//     } catch (e) {
//       print('❌ Initialize Error: $e');
//       _isAvailable = false;
//       return false;
//     }
//   }
//
//   // ✅ جلب تفاصيل المنتجات
//   Future<List<ProductDetails>> fetchProductDetails() async {
//     if (!_isAvailable) {
//       throw Exception(
//           'Google Play Billing غير متاح.\n\n'
//               'الأسباب المحتملة:\n'
//               '1. الاشتراكات جديدة — انتظر 24 ساعة\n'
//               '2. التطبيق غير مثبت من Play Store\n'
//               '3. حسابك ليس في قائمة المختبرين\n'
//               '4. الـ Product IDs غير مطابقة\n'
//               '5. لم يتم استدعاء initialize() أولاً'
//       );
//     }
//
//     final productIds = planToProductId.values.toSet();
//     print('🔍 البحث عن المنتجات: $productIds');
//
//     final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
//
//     if (response.notFoundIDs.isNotEmpty) {
//       print('⚠️ منتجات غير موجودة: ${response.notFoundIDs}');
//       print('💡 السبب المحتمل: الاشتراكات لم تُنشر بعد — انتظر 24 ساعة');
//     }
//
//     if (response.productDetails.isEmpty) {
//       throw Exception(
//           'لم يتم العثور على أي منتجات.\n'
//               'الأسباب:\n'
//               '1. الاشتراكات جديدة — انتظر 24 ساعة منذ الإنشاء\n'
//               '2. الـ Product IDs في الكود لا تطابق Play Console\n'
//               '3. الاشتراكات غير مفعّلة في Play Console'
//       );
//     }
//
//     print('✅ تم العثور على ${response.productDetails.length} منتج');
//     for (final p in response.productDetails) {
//       print('   📦 ${p.id}: ${p.title} - ${p.price}');
//     }
//
//     return response.productDetails;
//   }
//
//   // ✅ شراء منتج (اشتراك)
//   Future<void> purchasePlan(String planId) async {
//     final productId = planToProductId[planId];
//     if (productId == null) {
//       throw Exception('خطة غير معروفة: $planId');
//     }
//
//     final products = await fetchProductDetails();
//     final product = products.firstWhere(
//           (p) => p.id == productId,
//       orElse: () => throw Exception('المنتج $productId غير موجود في Play Console'),
//     );
//
//     final purchaseParam = PurchaseParam(productDetails: product);
//     await _iap.buyNonConsumable(purchaseParam: purchaseParam);
//   }
//
//   // ✅ معالجة تحديثات المشتريات
//   void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
//     for (final purchase in purchases) {
//       switch (purchase.status) {
//         case PurchaseStatus.purchased:
//           print('✅ شراء ناجح: ${purchase.productID}');
//           _verifyPurchase(purchase);
//           break;
//         case PurchaseStatus.pending:
//           print('⏳ شراء معلق: ${purchase.productID}');
//           break;
//         case PurchaseStatus.error:
//           print('❌ خطأ في الشراء: ${purchase.error?.message}');
//           break;
//         case PurchaseStatus.restored:
//           print('🔄 استعادة شراء: ${purchase.productID}');
//           break;
//         case PurchaseStatus.canceled:
//           print('🚫 شراء ملغى');
//           break;
//       }
//     }
//   }
//
//   // ✅ التحقق من الشراء
//   Future<void> _verifyPurchase(PurchaseDetails purchase) async {
//     print('🔐 التحقق من: ${purchase.productID}');
//     print('🔐 Purchase Token: ${purchase.purchaseID}');
//     print('🔐 Server Verification: ${purchase.verificationData.serverVerificationData}');
//
//     // TODO: أرسل purchase.purchaseToken إلى Backend للتحقق
//
//     if (purchase.pendingCompletePurchase) {
//       await _iap.completePurchase(purchase);
//       print('✅ تم إكمال الشراء');
//     }
//   }
//
//   // ✅ استعادة المشتريات
//   Future<void> restorePurchases() async {
//     await _iap.restorePurchases();
//   }
//
//   // ✅ التخلص
//   void dispose() {
//     _subscription?.cancel();
//   }
// }

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class GooglePlayBillingService {
  static final GooglePlayBillingService _instance = GooglePlayBillingService._internal();
  factory GooglePlayBillingService() => _instance;
  GooglePlayBillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const Map<String, String> planToProductId = {
    'startup': 'chat_startup_monthly',
    'growth': 'chat_growth_monthly',
    'enterprise': 'chat_enterprise_monthly',
  };

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // ✅ Completer للانتظار — أفضل من StreamController للاستخدام مرة واحدة
  Completer<PurchaseDetails>? _purchaseCompleter;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) return false;

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('❌ IAP Stream Error: $error'),
      );

      return true;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  Future<List<ProductDetails>> fetchProductDetails() async {
    if (!_isAvailable) throw Exception('Billing not available');

    final productIds = planToProductId.values.toSet();
    final response = await _iap.queryProductDetails(productIds);

    if (response.productDetails.isEmpty) {
      throw Exception('No products found');
    }

    return response.productDetails;
  }

  // ✅ شراء مع انتظار النتيجة — الحل الجذري
  Future<PurchaseDetails> purchasePlan(String planId) async {
    final productId = planToProductId[planId];
    if (productId == null) throw Exception('Unknown plan: $planId');

    final products = await fetchProductDetails();
    final product = products.firstWhere(
          (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    // ✅ إنشاء Completer جديد قبل كل عملية شراء
    _purchaseCompleter = Completer<PurchaseDetails>();

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);

    // ✅ انتظار النتيجة من _handlePurchaseUpdates
    return await _purchaseCompleter!.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _purchaseCompleter = null;
        throw TimeoutException('انتهت مهلة الشراء');
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      print('📦 Purchase Update: ${purchase.productID} — Status: ${purchase.status}');

      // ✅ إكمال الـ Completer إذا كان موجوداً ولم يُكمل بعد
      if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
        _purchaseCompleter!.complete(purchase);
        _purchaseCompleter = null;
      }

      switch (purchase.status) {
        case PurchaseStatus.purchased:
          print('✅ شراء ناجح: ${purchase.productID}');
          _verifyPurchase(purchase);
          break;
        case PurchaseStatus.pending:
          print('⏳ شراء معلق: ${purchase.productID}');
          break;
        case PurchaseStatus.error:
          print('❌ خطأ: ${purchase.error?.message}');
          break;
        case PurchaseStatus.restored:
          print('🔄 مستعاد: ${purchase.productID}');
          break;
        case PurchaseStatus.canceled:
          print('🚫 ملغى');
          break;
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
      print('✅ تم إكمال الشراء');
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseCompleter = null;
  }
}
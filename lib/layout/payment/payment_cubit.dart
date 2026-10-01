import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:chat/shared/network/payment_api_service.dart';
import 'package:chat/shared/network/local/cache_helper.dart';
import '../../models/plan_models.dart';
import '../../shared/network/remote/google_play_billing_service.dart';
import 'payment_states.dart';

enum PaymentMethod { stripe, googlePlay }

class PaymentCubit extends Cubit<PaymentState> with WidgetsBindingObserver {
  final PaymentApiService _apiService;
  final GooglePlayBillingService _googlePlayBilling;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// يُصبح true عند فتح متصفح Stripe وينتظر النتيجة
  bool _awaitingStripeResult = false;

  PaymentMethod get selectedMethod => _selectedMethod;

  PaymentCubit(this._apiService)
      : _googlePlayBilling = GooglePlayBillingService(),
        super(PaymentInitial()) {
    WidgetsBinding.instance.addObserver(this);
    _initBilling();
    _initDeepLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingStripeResult) {
      // المستخدم رجع للتطبيق أثناء انتظار Stripe
      // ننتظر 5 ثوانٍ لإعطاء Deep Link فرصة للوصول
      Future.delayed(const Duration(seconds: 5), () {
        if (_awaitingStripeResult && !isClosed && this.state is PaymentLoading) {
          print('⏱️ No Stripe deep link received — resetting payment state');
          _awaitingStripeResult = false;
          emit(PaymentCancelled());
        }
      });
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      print('🔗 Deep Link received: $uri');
      if (uri.scheme == 'lynomia' && uri.host == 'billing') {
        final checkoutStatus = uri.queryParameters['checkout'];
        print('💳 Billing Checkout Status: $checkoutStatus');

        if (checkoutStatus == 'success') {
          _awaitingStripeResult = false;
          if (!isClosed) {
            emit(PaymentLoading());
          }
          // ⏳ انتظار 2-3 ثوانٍ حتى يكتمل تأكيد الدفع في السيرفر
          await Future.delayed(const Duration(seconds: 3));
          try {
            final entitlements = await _apiService.fetchEntitlements();
            String planName = 'الجديدة';
            if (entitlements['plan'] != null && entitlements['plan']['name'] != null) {
              planName = entitlements['plan']['name'].toString();
            }
            if (!isClosed) {
              emit(PaymentSuccess('external_stripe', planName));
            }
          } catch (e) {
            print('❌ Error fetching entitlements: $e');
            if (!isClosed) {
              emit(PaymentSuccess('external_stripe', 'الجديدة'));
            }
          }
        } else if (checkoutStatus == 'canceled') {
          _awaitingStripeResult = false;
          if (!isClosed) {
            emit(PaymentCancelled());
          }
        } else if (checkoutStatus == 'portal') {
          try {
            await _apiService.fetchEntitlements();
          } catch (_) {}
        }
      }
    }, onError: (err) {
      print('❌ Deep Link Error: $err');
    });
  }

  Future<void> _initBilling() async {
    try {
      final available = await _googlePlayBilling.initialize();
      if (!available) {
        print('⚠️ Billing غير متاح');
      }
    } catch (e) {
      print('❌ Billing init error: $e');
    }
  }

  PaymentMethod _selectedMethod = PaymentMethod.stripe;

  void selectPaymentMethod(PaymentMethod method) {
    _selectedMethod = method;
    emit(PaymentMethodChanged(method));
  }

  Future<void> loadPlans() async {
    emit(PlansLoading());
    try {
      final plans = await _apiService.fetchPlans();
      emit(PlansLoaded(plans));
    } catch (e) {
      emit(PlansError(e.toString()));
    }
  }

  void selectPlan(PlanModel plan) {
    if (state is PlansLoaded) {
      final currentState = state as PlansLoaded;
      emit(PlansLoaded(currentState.plans, selectedPlan: plan));
    }
  }

  Future<void> completePayment({required String plan}) async {
    if (!isClosed) {
      emit(PaymentLoading());
    }

    try {
      if (_selectedMethod == PaymentMethod.googlePlay) {
        await _completeGooglePlayPayment(plan);
      } else {
        await _completeStripePayment(plan);
      }
    } catch (e) {
      if (!isClosed) {
        emit(PaymentError(e.toString()));
      }
    }
  }

  // ─── الدفع عبر Google Play Billing — مُبسّط وصحيح ───────────
  // Future<void> _completeGooglePlayPayment(String plan) async {
  //   try {
  //     if (!_googlePlayBilling.isAvailable) {
  //       emit(const PaymentError(
  //           'Google Play Billing غير متاح.\n'
  //               'تأكد من تثبيت التطبيق من Play Store'
  //       ));
  //       return;
  //     }
  //
  //     // ✅ شراء + انتظار النتيجة في خطوة واحدة
  //     final purchaseResult = await _googlePlayBilling.purchasePlan(plan);
  //
  //     // ✅ معالجة النتيجة
  //     switch (purchaseResult.status) {
  //       case PurchaseStatus.purchased:
  //       // إرسال إلى Backend
  //         final success = await _verifyWithBackend(purchaseResult);
  //
  //         if (success) {
  //           String planName = plan;
  //           if (state is PlansLoaded) {
  //             final selected = (state as PlansLoaded).selectedPlan;
  //             if (selected != null) planName = selected.name;
  //           }
  //           emit(PaymentSuccess('google_play_purchase', planName));
  //         } else {
  //           emit(const PaymentError('فشل التحقق من الشراء في السيرفر'));
  //         }
  //         break;
  //
  //       case PurchaseStatus.pending:
  //         emit(const PaymentError('الشراء معلق — يرجى الانتظار'));
  //         break;
  //
  //       // case PurchaseStatus.error:
  //       //   emit(PaymentError('خطأ: ${purchaseResult.error?.message}'));
  //       //   break;
  //       case PurchaseStatus.error:
  //         final errorCode = purchaseResult.error?.code ?? '';
  //         final errorMsg = purchaseResult.error?.message ?? '';
  //
  //         print('❌ Purchase Error Code: $errorCode');
  //         print('❌ Purchase Error Message: $errorMsg');
  //
  //         if (errorCode == 'item_already_owned' ||
  //             errorMsg.toLowerCase().contains('already owned')) {
  //
  //           print('🔄 المستخدم يملك الاشتراك بالفعل!');
  //
  //           // نحاول التحقق من السيرفر
  //           try {
  //             final success = await _verifyWithBackend(purchaseResult);
  //             if (success) {
  //               String planName = plan;
  //               if (state is PlansLoaded) {
  //                 final selected = (state as PlansLoaded).selectedPlan;
  //                 if (selected != null) planName = selected.name;
  //               }
  //               emit(PaymentSuccess('google_play_purchase', planName));
  //             } else {
  //               emit(const PaymentError(
  //                   'أنت مشترك بالفعل في Google Play!\n'
  //                       'ولكن فشل التحقق من السيرفر. يرجى المحاولة لاحقاً.'
  //               ));
  //             }
  //           } catch (e) {
  //             emit(PaymentError(
  //                 'أنت مشترك بالفعل، ولكن هناك مشكلة في السيرفر: $e'
  //             ));
  //           }
  //         } else {
  //           emit(PaymentError('خطأ: $errorMsg'));
  //         }
  //         break;
  //
  //       case PurchaseStatus.canceled:
  //         emit( PaymentCancelled());
  //         break;
  //
  //       case PurchaseStatus.restored:
  //         String planName = plan;
  //         if (state is PlansLoaded) {
  //           final selected = (state as PlansLoaded).selectedPlan;
  //           if (selected != null) planName = selected.name;
  //         }
  //         emit(PaymentSuccess('restored', planName));
  //         break;
  //     }
  //
  //   } on TimeoutException {
  //     emit(const PaymentError('انتهت مهلة الشراء'));
  //   } catch (e) {
  //     emit(PaymentError('فشل الشراء: $e'));
  //   }
  // }

  Future<void> _completeGooglePlayPayment(String plan) async {
    try {
      if (!_googlePlayBilling.isAvailable) {
        if (!isClosed) {
          emit(const PaymentError('Google Play Billing غير متاح.\n'
              'تأكد من تثبيت التطبيق من Play Store'));
        }
        return;
      }

      // ✅ شراء + انتظار النتيجة
      final purchaseResult = await _googlePlayBilling.purchasePlan(plan);

      switch (purchaseResult.status) {
        case PurchaseStatus.purchased:
          print('✅ شراء ناجح في Google Play');

          // ✅ التحقق من السيرفر
          final success = await _verifyWithBackend(purchaseResult, plan);

          if (success) {
            String planName = plan;
            if (state is PlansLoaded) {
              final selected = (state as PlansLoaded).selectedPlan;
              if (selected != null) planName = selected.name;
            }
            if (!isClosed) {
              emit(PaymentSuccess('google_play_purchase', planName));
            }
          } else {
            if (!isClosed) {
              emit(const PaymentError('فشل التحقق من الشراء في السيرفر'));
            }
          }
          break;

        case PurchaseStatus.pending:
          if (!isClosed) {
            emit(const PaymentError('الشراء معلق — يرجى الانتظار'));
          }
          break;

        case PurchaseStatus.error:
          if (!isClosed) {
            emit(PaymentError('خطأ: ${purchaseResult.error?.message}'));
          }
          break;

        case PurchaseStatus.canceled:
          if (!isClosed) {
            emit(PaymentCancelled());
          }
          break;

        case PurchaseStatus.restored:
          String planName = plan;
          if (state is PlansLoaded) {
            final selected = (state as PlansLoaded).selectedPlan;
            if (selected != null) planName = selected.name;
          }
          if (!isClosed) {
            emit(PaymentSuccess('restored', planName));
          }
          break;
      }
    } on TimeoutException {
      if (!isClosed) {
        emit(const PaymentError('انتهت مهلة الشراء'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(PaymentError('فشل الشراء: $e'));
      }
    }
  }

  // Future<bool> _verifyWithBackend(PurchaseDetails purchase) async {
  //   try {
  //     final token = _lynomiaToken;
  //     final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;
  //
  //     if (accountId == 0) return false;
  //
  //     return await _apiService.verifyGooglePlayPurchase(
  //       accountId: accountId,
  //       productId: purchase.productID,
  //       purchaseToken: purchase.purchaseID ?? '',
  //       verificationData: purchase.verificationData.serverVerificationData,
  //       packageName: 'com.Lynomia.Lynomia_chat',
  //     );
  //   } catch (e) {
  //     print('❌ Backend verification failed: $e');
  //     return false;
  //   }
  // }

  Future<bool> _verifyWithBackend(
      PurchaseDetails purchase, String planId) async {
    try {
      final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;

      print('🔍 Verifying purchase with backend...');
      print('🔍 Account ID: $accountId');
      print('🔍 Product ID: ${purchase.productID}');
      print('🔍 Purchase ID (Order ID): ${purchase.purchaseID}');
      print(
          '🔍 Purchase Token (Server Verification Data): ${purchase.verificationData.serverVerificationData}');
      print('🔍 Plan ID: $planId');

      if (accountId == 0) {
        print('❌ Account ID is 0!');
        return false;
      }

      // ✅ UPDATED: نرسل الباراميترات الجديدة المطلوبة
      // purchaseToken يجب أن يكون serverVerificationData وليس purchaseID
      return await _apiService.verifyGooglePlayPurchase(
        accountId: accountId,
        productId: purchase.productID,
        purchaseToken: purchase.verificationData.serverVerificationData,
        orderId: purchase.purchaseID ?? '',
        planId: planId,
      );
    } catch (e) {
      print('❌ Backend verification failed: $e');
      return false;
    }
  }

  String? get _lynomiaToken =>
      CacheHelper.getString(key: CacheHelper.keyLynomiaToken);

  // ─── الدفع عبر Stripe في المتصفح الخارجي ────────────────────────
  Future<void> _completeStripePayment(String plan) async {
    try {
      final planId = int.tryParse(plan) ?? 1;

      print('🚀 Requesting Stripe checkout URL for planId: $planId');

      final checkoutUrl = await _apiService.createCheckoutUrl(
        planId: planId,
      );

      print('🔗 Opening checkout URL in external browser: $checkoutUrl');

      final Uri uri = Uri.parse(checkoutUrl);
      _awaitingStripeResult = true;
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('تعذر فتح متصفح الإنترنت الخارجي');
      }
    } catch (e) {
      _awaitingStripeResult = false;
      print('❌ Stripe Checkout Error: $e');
      if (!isClosed) {
        emit(PaymentError('فشل فتح رابط الدفع: $e'));
      }
    }
  }

  void reset() {
    emit(PaymentInitial());
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _googlePlayBilling.dispose();
    return super.close();
  }
}

// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:chat/shared/network/payment_api_service.dart';
// import 'package:chat/shared/network/local/cache_helper.dart';
// import '../../models/plan_models.dart';
// import '../../shared/network/remote/google_play_billing_service.dart';
// import 'payment_states.dart';
//
// enum PaymentMethod { stripe, googlePlay }
//
// class PaymentCubit extends Cubit<PaymentState> {
//   final PaymentApiService _apiService;
//   final GooglePlayBillingService _googlePlayBilling;
//   StreamSubscription<List<PurchaseDetails>>? _subscription;
//
//   PaymentMethod get selectedMethod => _selectedMethod;
//   PaymentMethod _selectedMethod = PaymentMethod.googlePlay;
//
//   PaymentCubit(this._apiService)
//       : _googlePlayBilling = GooglePlayBillingService(),
//         super(PaymentInitial()) {
//     _initBilling();
//     _listenToPurchaseUpdated();
//   }
//
//   Future<void> _initBilling() async {
//     try {
//       final available = await _googlePlayBilling.initialize();
//       if (!available) {
//         print('⚠️ Google Play Billing غير متاح على هذا الجهاز');
//       } else {
//         print('✅ Google Play Billing متصل وجاهز للاستخدام');
//       }
//     } catch (e) {
//       print('❌ Billing init error: $e');
//     }
//   }
//
//   void _listenToPurchaseUpdated() {
//     final Stream<List<PurchaseDetails>> purchaseUpdated =
//         InAppPurchase.instance.purchaseStream;
//     _subscription = purchaseUpdated.listen((purchaseDetailsList) {
//       _listenToPurchaseDetails(purchaseDetailsList);
//     }, onDone: () {
//       _subscription?.cancel();
//     }, onError: (error) {
//       print('❌ Stream Error: $error');
//     });
//   }
//
//   void _listenToPurchaseDetails(List<PurchaseDetails> purchaseDetailsList) {
//     for (var purchaseDetails in purchaseDetailsList) {
//       if (purchaseDetails.status == PurchaseStatus.purchased ||
//           purchaseDetails.status == PurchaseStatus.restored) {
//
//         // 🛑 طباعة النص الصريح للـ Purchase Token 🛑
//         printPurchaseDetailsForBackend(purchaseDetails);
//
//         if (purchaseDetails.pendingCompletePurchase) {
//           InAppPurchase.instance.completePurchase(purchaseDetails);
//         }
//
//         emit(
//           PaymentSuccess(
//             purchaseDetails.verificationData.serverVerificationData,
//             purchaseDetails.productID,
//           ),
//         );
//       } else if (purchaseDetails.status == PurchaseStatus.error) {
//         emit(PaymentError(purchaseDetails.error?.message ?? 'خطأ في العملية'));
//       }
//     }
//   }
//
//   void selectPaymentMethod(PaymentMethod method) {
//     _selectedMethod = method;
//     emit(PaymentMethodChanged(method));
//   }
//
//   Future<void> loadPlans() async {
//     emit(PlansLoading());
//     try {
//       final plans = await _apiService.fetchPlans();
//       emit(PlansLoaded(plans));
//     } catch (e) {
//       emit(PlansError(e.toString()));
//     }
//   }
//
//   void selectPlan(PlanModel plan) {
//     if (state is PlansLoaded) {
//       final currentState = state as PlansLoaded;
//       emit(
//         PlansLoaded(
//           currentState.plans,
//           selectedPlan: plan,
//         ),
//       );
//     }
//   }
//
//   Future<void> completePayment({
//     required String plan,
//   }) async {
//     emit(PaymentLoading());
//
//     try {
//       if (_selectedMethod == PaymentMethod.googlePlay) {
//         await _completeGooglePlayPayment('12345678');
//       } else {
//         await _completeStripePayment(plan);
//       }
//     } catch (e) {
//       emit(PaymentError(e.toString()));
//     }
//   }
//
//   Future<void> _completeGooglePlayPayment(String productId) async {
//     try {
//       final InAppPurchase iap = InAppPurchase.instance;
//       final bool available = await iap.isAvailable();
//
//       if (!available) {
//         emit(const PaymentError('Google Play Billing غير متاح على هذا الجهاز'));
//         return;
//       }
//
//       print('🚀 جاري بدء الشراء المباشر للمنتج ID: $productId');
//
//       final ProductDetailsResponse response =
//       await iap.queryProductDetails({productId});
//
//       if (response.notFoundIDs.contains(productId) ||
//           response.productDetails.isEmpty) {
//         print('❌ المنتج غير موجود: $productId');
//         emit(PaymentError('المنتج $productId غير متوفر في المتجر حالياً'));
//         return;
//       }
//
//       final ProductDetails productDetails = response.productDetails.first;
//       print('✅ تم العثور على المنتج: ${productDetails.title} - السعر: ${productDetails.price}');
//
//       final PurchaseParam purchaseParam =
//       PurchaseParam(productDetails: productDetails);
//
//       await iap.buyConsumable(purchaseParam: purchaseParam);
//     } on TimeoutException {
//       emit(const PaymentError('انتهت مهلة الشراء'));
//     } catch (e) {
//       print('❌ Google Play purchase exception: $e');
//       emit(PaymentError('فشل الشراء: $e'));
//     }
//   }
//
//   void printPurchaseDetailsForBackend(PurchaseDetails purchase) {
//     final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;
//     final token = purchase.verificationData.serverVerificationData;
//
//     print('\n=============================================================');
//     print('📦 [بيانات الشراء لتقديمها للـ BACKEND]');
//     print('=============================================================');
//     print('1️⃣ Account ID: $accountId');
//     print('2️⃣ Product ID: ${purchase.productID}');
//     print('3️⃣ Order ID: ${purchase.purchaseID}');
//     print('4️⃣ Verification Source: ${purchase.verificationData.source}');
//     print('5️⃣ Purchase Token (انسخ هذا للـ Backend):');
//     print(token); // سيطبع النص الكامل للـ token هنا
//     print('=============================================================\n');
//   }
//
//   Future<void> _completeStripePayment(String plan) async {
//     final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;
//
//     if (accountId == 0) {
//       emit(const PaymentError('لم يتم العثور على معرف الحساب'));
//       return;
//     }
//
//     final paymentIntent = await _apiService.createPaymentIntent(
//       accountId: accountId,
//       plan: plan,
//     );
//
//     await Stripe.instance.initPaymentSheet(
//       paymentSheetParameters: SetupPaymentSheetParameters(
//         paymentIntentClientSecret: paymentIntent,
//         merchantDisplayName: 'Lynomia Chat',
//         allowsDelayedPaymentMethods: true,
//         style: ThemeMode.light,
//         googlePay: const PaymentSheetGooglePay(
//           merchantCountryCode: 'SA',
//           currencyCode: 'USD',
//           testEnv: true,
//         ),
//       ),
//     );
//
//     await Stripe.instance.presentPaymentSheet();
//
//     String planName = plan;
//     if (state is PlansLoaded) {
//       final selected = (state as PlansLoaded).selectedPlan;
//       if (selected != null) planName = selected.name;
//     }
//
//     emit(PaymentSuccess(paymentIntent, planName));
//   }
//
//   void reset() {
//     emit(PaymentInitial());
//   }
//
//   @override
//   Future<void> close() {
//     _subscription?.cancel();
//     _googlePlayBilling.dispose();
//     return super.close();
//   }
// }

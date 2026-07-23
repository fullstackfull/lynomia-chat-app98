



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
//   PaymentMethod get selectedMethod => _selectedMethod;
//
//   // ✅ Constructor — لا يحتوي على await
//   PaymentCubit(this._apiService)
//       : _googlePlayBilling = GooglePlayBillingService(),
//         super(PaymentInitial()) {
//     // استدعاء التهيئة بدون await
//     _initBilling();
//   }
//
//   // ✅ دالة منفصلة للتهيئة — async
//   Future<void> _initBilling() async {
//     try {
//       final available = await _googlePlayBilling.initialize();
//       if (!available) {
//         print('⚠️ Billing غير متاح — قد تحتاج انتظار 24 ساعة');
//       }
//     } catch (e) {
//       print('❌ Billing init error: $e');
//     }
//   }
//
//   PaymentMethod _selectedMethod = PaymentMethod.stripe;
//
//   // ─── اختيار طريقة الدفع ──────────────────────
//   void selectPaymentMethod(PaymentMethod method) {
//     _selectedMethod = method;
//     emit(PaymentMethodChanged(method));
//   }
//
//   // ─── جلب الخطط من الـ API ───────────────────
//   Future<void> loadPlans() async {
//     emit(PlansLoading());
//
//     try {
//       final plans = await _apiService.fetchPlans();
//       emit(PlansLoaded(plans));
//     } catch (e) {
//       print('❌ Load Plans Error: $e');
//       emit(PlansError(e.toString()));
//     }
//   }
//
//   // ─── اختيار خطة ──────────────────────────────
//   void selectPlan(PlanModel plan) {
//     if (state is PlansLoaded) {
//       final currentState = state as PlansLoaded;
//       emit(PlansLoaded(currentState.plans, selectedPlan: plan));
//     }
//   }
//
//   // ─── إكمال عملية الدفع ──────────────────────
//   Future<void> completePayment({required String plan}) async {
//     emit(PaymentLoading());
//
//     try {
//       if (_selectedMethod == PaymentMethod.googlePlay) {
//         await _completeGooglePlayPayment(plan);
//       } else {
//         await _completeStripePayment(plan);
//       }
//     } catch (e) {
//       print('❌ Complete Payment Error: $e');
//       emit(PaymentError(e.toString()));
//     }
//   }
//
//   // ─── الدفع عبر Google Play Billing ───────────
//   Future<void> _completeGooglePlayPayment(String plan) async {
//     try {
//       // ✅ التحقق من التهيئة أولاً
//       if (!_googlePlayBilling.isAvailable) {
//         emit(const PaymentError(
//             'Google Play Billing غير متاح.\n'
//                 '1. انتظر 24 ساعة منذ إنشاء الاشتراكات\n'
//                 '2. تأكد من تثبيت التطبيق من Play Store\n'
//                 '3. تأكد من تسجيل حسابك في المختبرين'
//         ));
//         return;
//       }
//
//       await _googlePlayBilling.purchasePlan(plan);
//
//       String planName = plan;
//       if (state is PlansLoaded) {
//         final selected = (state as PlansLoaded).selectedPlan;
//         if (selected != null) planName = selected.name;
//       }
//
//       emit(PaymentSuccess('google_play_purchase', planName));
//     } catch (e) {
//       emit(PaymentError('فشل الشراء عبر Google Play: $e'));
//     }
//   }
//
//   // ─── الدفع عبر Stripe ────────────────────────
//   Future<void> _completeStripePayment(String plan) async {
//     final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;
//
//     if (accountId == 0) {
//       emit(const PaymentError('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول'));
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
//   // ─── إعادة تعيين الحالة ────────────────────
//   void reset() {
//     emit(PaymentInitial());
//   }
//
//   @override
//   Future<void> close() {
//     _googlePlayBilling.dispose();
//     return super.close();
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:chat/shared/network/payment_api_service.dart';
import 'package:chat/shared/network/local/cache_helper.dart';
import '../../models/plan_models.dart';
import '../../shared/network/remote/google_play_billing_service.dart';
import 'payment_states.dart';

enum PaymentMethod { stripe, googlePlay }

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentApiService _apiService;
  final GooglePlayBillingService _googlePlayBilling;
  PaymentMethod get selectedMethod => _selectedMethod;

  PaymentCubit(this._apiService)
      : _googlePlayBilling = GooglePlayBillingService(),
        super(PaymentInitial()) {
    _initBilling();
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
    emit(PaymentLoading());

    try {
      if (_selectedMethod == PaymentMethod.googlePlay) {
        await _completeGooglePlayPayment(plan);
      } else {
        await _completeStripePayment(plan);
      }
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  // ─── الدفع عبر Google Play Billing — مُبسّط وصحيح ───────────
  Future<void> _completeGooglePlayPayment(String plan) async {
    try {
      if (!_googlePlayBilling.isAvailable) {
        emit(const PaymentError(
            'Google Play Billing غير متاح.\n'
                'تأكد من تثبيت التطبيق من Play Store'
        ));
        return;
      }

      // ✅ شراء + انتظار النتيجة في خطوة واحدة
      final purchaseResult = await _googlePlayBilling.purchasePlan(plan);

      // ✅ معالجة النتيجة
      switch (purchaseResult.status) {
        case PurchaseStatus.purchased:
        // إرسال إلى Backend
          final success = await _verifyWithBackend(purchaseResult);

          if (success) {
            String planName = plan;
            if (state is PlansLoaded) {
              final selected = (state as PlansLoaded).selectedPlan;
              if (selected != null) planName = selected.name;
            }
            emit(PaymentSuccess('google_play_purchase', planName));
          } else {
            emit(const PaymentError('فشل التحقق من الشراء في السيرفر'));
          }
          break;

        case PurchaseStatus.pending:
          emit(const PaymentError('الشراء معلق — يرجى الانتظار'));
          break;

        case PurchaseStatus.error:
          emit(PaymentError('خطأ: ${purchaseResult.error?.message}'));
          break;

        case PurchaseStatus.canceled:
          emit( PaymentCancelled());
          break;

        case PurchaseStatus.restored:
          String planName = plan;
          if (state is PlansLoaded) {
            final selected = (state as PlansLoaded).selectedPlan;
            if (selected != null) planName = selected.name;
          }
          emit(PaymentSuccess('restored', planName));
          break;
      }

    } on TimeoutException {
      emit(const PaymentError('انتهت مهلة الشراء'));
    } catch (e) {
      emit(PaymentError('فشل الشراء: $e'));
    }
  }

  Future<bool> _verifyWithBackend(PurchaseDetails purchase) async {
    try {
      final token = _lynomiaToken;
      final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;

      if (accountId == 0) return false;

      return await _apiService.verifyGooglePlayPurchase(
        accountId: accountId,
        productId: purchase.productID,
        purchaseToken: purchase.purchaseID ?? '',
        verificationData: purchase.verificationData.serverVerificationData,
        packageName: 'com.Lynomia.Lynomia_chat',
      );
    } catch (e) {
      print('❌ Backend verification failed: $e');
      return false;
    }
  }

  String? get _lynomiaToken =>
      CacheHelper.getString(key: CacheHelper.keyLynomiaToken);

  // ─── الدفع عبر Stripe ────────────────────────
  Future<void> _completeStripePayment(String plan) async {
    final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;

    if (accountId == 0) {
      emit(const PaymentError('لم يتم العثور على معرف الحساب'));
      return;
    }

    final paymentIntent = await _apiService.createPaymentIntent(
      accountId: accountId,
      plan: plan,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent,
        merchantDisplayName: 'Lynomia Chat',
        allowsDelayedPaymentMethods: true,
        style: ThemeMode.light,
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'SA',
          currencyCode: 'USD',
          testEnv: true,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    String planName = plan;
    if (state is PlansLoaded) {
      final selected = (state as PlansLoaded).selectedPlan;
      if (selected != null) planName = selected.name;
    }

    emit(PaymentSuccess(paymentIntent, planName));
  }

  void reset() {
    emit(PaymentInitial());
  }

  @override
  Future<void> close() {
    _googlePlayBilling.dispose();
    return super.close();
  }
}
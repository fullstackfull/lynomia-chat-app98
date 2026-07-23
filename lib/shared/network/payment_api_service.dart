
//
// import 'package:dio/dio.dart';
// import 'package:chat/shared/network/local/cache_helper.dart';
//
// import '../../models/plan_models.dart';
//
// class PaymentApiService {
//   final Dio _dio;
//
//   PaymentApiService(this._dio);
//
//   // ─── قراءة التوكن الحقيقي من الكاش ─────────────
//   String? get _lynomiaToken =>
//       CacheHelper.getString(key: CacheHelper.keyLynomiaToken);
//
//   // ─── جلب الخطط من الـ API ─────────────────────
//   Future<List<PlanModel>> fetchPlans() async {
//     try {
//       final token = _lynomiaToken;
//       if (token == null || token.isEmpty) {
//         throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
//       }
//
//       const url = 'https://lynomia.com/api/plans/chat';
//
//       print('📤 GET Fetch Plans: $url');
//
//       final response = await _dio.get(
//         url,
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         ),
//       );
//
//       print('📥 Plans Status: ${response.statusCode}');
//       print('📥 Plans Data: ${response.data}');
//
//       if (response.statusCode == 200) {
//         final data = response.data;
//
//         // التعامل مع هيكل الـ Response المخصص
//         final originalData = data['data']?['original']?['data'];
//
//         if (originalData != null && originalData is Map) {
//           final List<PlanModel> plans = [];
//
//           originalData.forEach((key, value) {
//             if (value is Map<String, dynamic>) {
//               plans.add(PlanModel.fromJson(key, value));
//             }
//           });
//
//           print('✅ Loaded ${plans.length} plans from API');
//           return plans;
//         }
//
//         throw Exception('هيكل البيانات غير متوقع من الـ API');
//       }
//
//       throw Exception('فشل جلب الخطط: ${response.statusCode}');
//     } catch (e) {
//       print('❌ Fetch Plans Error: $e');
//       throw Exception('فشل جلب الخطط: $e');
//     }
//   }
//
//   // ─── إنشاء Payment Intent ─────────────────────
//   Future<String> createPaymentIntent({
//     required int accountId,
//     required String plan,
//   }) async {
//     try {
//       final token = _lynomiaToken;
//       if (token == null || token.isEmpty) {
//         throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
//       }
//
//       const url = 'https://lynomia.com/api/chat/mobile-checkout';
//
//       print('📤 POST Create Payment Intent: $url');
//       print('📤 Account ID: $accountId');
//       print('📤 Plan: $plan');
//
//       final response = await _dio.post(
//         url,
//         queryParameters: {
//           'account_id': accountId,
//           'plan': plan,
//         },
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         ),
//       );
//
//       print('📥 Payment Intent Status: ${response.statusCode}');
//       print('📥 Payment Intent Data: ${response.data}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final paymentIntent = response.data['paymentIntent'];
//         print('✅ Payment Intent: $paymentIntent');
//         return paymentIntent;
//       }
//
//       throw Exception('فشل إنشاء Payment Intent: ${response.statusCode}');
//     } catch (e) {
//       print('❌ Create Payment Intent Error: $e');
//       throw Exception('فشل إنشاء Payment Intent: تأكد من صحة البيانات');
//     }
//   }
// }

import 'package:dio/dio.dart';
import 'package:chat/shared/network/local/cache_helper.dart';

import '../../models/plan_models.dart';
import '../../models/payment_history_model.dart';

class PaymentApiService {
  final Dio _dio;

  PaymentApiService(this._dio);

  // ─── قراءة التوكن الحقيقي من الكاش ─────────────
  String? get _lynomiaToken =>
      CacheHelper.getString(key: CacheHelper.keyLynomiaToken);

  // ─── جلب الخطط من الـ API ─────────────────────
  Future<List<PlanModel>> fetchPlans() async {
    try {
      final token = _lynomiaToken;
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }

      const url = 'https://lynomia.com/api/plans/chat';

      print('📤 GET Fetch Plans: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Plans Status: ${response.statusCode}');
      print('📥 Plans Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // التعامل مع هيكل الـ Response المخصص
        final originalData = data['data']?['original']?['data'];

        if (originalData != null && originalData is Map) {
          final List<PlanModel> plans = [];

          originalData.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              plans.add(PlanModel.fromJson(key, value));
            }
          });

          print('✅ Loaded ${plans.length} plans from API');
          return plans;
        }

        throw Exception('هيكل البيانات غير متوقع من الـ API');
      }

      throw Exception('فشل جلب الخطط: ${response.statusCode}');
    } catch (e) {
      print('❌ Fetch Plans Error: $e');
      throw Exception('فشل جلب الخطط: $e');
    }
  }

  // ─── إنشاء Payment Intent (Stripe) ────────────
  Future<String> createPaymentIntent({
    required int accountId,
    required String plan,
  }) async {
    try {
      final token = _lynomiaToken;
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }

      const url = 'https://lynomia.com/api/chat/mobile-checkout';

      print('📤 POST Create Payment Intent: $url');
      print('📤 Account ID: $accountId');
      print('📤 Plan: $plan');

      final response = await _dio.post(
        url,
        queryParameters: {
          'account_id': accountId,
          'plan': plan,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Payment Intent Status: ${response.statusCode}');
      print('📥 Payment Intent Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final paymentIntent = response.data['paymentIntent'];
        print('✅ Payment Intent: $paymentIntent');
        return paymentIntent;
      }

      throw Exception('فشل إنشاء Payment Intent: ${response.statusCode}');
    } catch (e) {
      print('❌ Create Payment Intent Error: $e');
      throw Exception('فشل إنشاء Payment Intent: تأكد من صحة البيانات');
    }
  }

  // ─── التحقق من شراء Google Play ──────────────
  Future<bool> verifyGooglePlayPurchase({
    required int accountId,
    required String productId,
    required String purchaseToken,
    required String verificationData,
    required String packageName,
  }) async {
    try {
      final token = _lynomiaToken;
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }

      // ✅ TODO: استبدل هذا بالـ URL الحقيقي لـ Backend
      const url = 'https://lynomia.com/api/verify-google-play-purchase';

      print('📤 POST Verify Google Play Purchase: $url');
      print('📤 Account ID: $accountId');
      print('📤 Product ID: $productId');
      print('📤 Purchase Token: $purchaseToken');

      final response = await _dio.post(
        url,
        data: {
          'account_id': accountId,
          'product_id': productId,
          'purchase_token': purchaseToken,
          'verification_data': verificationData,
          'package_name': packageName,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Verification Status: ${response.statusCode}');
      print('📥 Verification Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Purchase verified successfully');
        return true;
      }

      print('❌ Verification failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Verify Purchase Error: $e');
      return false;
    }
  }

  // ─── جلب سجل الاشتراكات ─────────────────────
  Future<List<PaymentHistoryModel>> fetchPaymentHistory({
    required int accountId,
  }) async {
    try {
      final token = _lynomiaToken;
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }

      const url = 'https://lynomia.com/api/my/payment/chat';

      print('📤 POST Fetch Payment History: $url');
      print('📤 User ID (Account ID): $accountId');

      final response = await _dio.post(
        url,
        data: {
          'userid': accountId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Payment History Status: ${response.statusCode}');
      print('📥 Payment History Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data;
        final List<PaymentHistoryModel> history = data
            .map((item) => PaymentHistoryModel.fromJson(item))
            .toList();
        
        print('✅ Loaded ${history.length} payment records');
        return history;
      }

      throw Exception('فشل جلب سجل الاشتراكات: ${response.statusCode}');
    } catch (e) {
      print('❌ Fetch Payment History Error: $e');
      throw Exception('فشل جلب سجل الاشتراكات: $e');
    }
  }
}
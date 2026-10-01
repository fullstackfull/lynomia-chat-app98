import 'package:dio/dio.dart';
import 'package:chat/shared/network/local/cache_helper.dart';

import '../../models/plan_models.dart';
import '../../models/payment_history_model.dart';

class PaymentApiService {
  final Dio _dio;

  static const String _defaultBaseUrl = 'https://chat.lynomia.com';

  PaymentApiService(Dio dio) : _dio = dio {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = _defaultBaseUrl;
    }
  }

  // ─── قراءة التوكن الحقيقي من الكاش ─────────────
  String? get _authToken => CacheHelper.getString(key: CacheHelper.keyAuthToken);
  int? get _accountId => CacheHelper.getInt(key: CacheHelper.keyAccountId);

  // ─── جلب الخطط من الـ API ─────────────────────
  Future<List<PlanModel>> fetchPlans() async {
    try {
      final authToken = _authToken;
      final accountId = _accountId;

      if (authToken == null || authToken.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }
      if (accountId == null) {
        throw Exception('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول مرة أخرى.');
      }

      final url = '/api/v1/accounts/$accountId/billing/plans';

      print('📤 GET Fetch Plans: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'api_access_token': authToken,
          },
        ),
      );

      print('📥 Plans Status: ${response.statusCode}');
      print('📥 Plans Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final mobileCheckoutEnabled = data['mobile_checkout_enabled'] ?? false;
        final plansData = data['plans'] as List<dynamic>?;

        if (plansData != null) {
          final List<PlanModel> plans = plansData
              .map((item) => PlanModel.fromJsonNew(item))
              .toList();

          print('✅ Loaded ${plans.length} plans from API');
          print('✅ Mobile checkout enabled: $mobileCheckoutEnabled');
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

  // ─── جلب الخطة الحالية والحقوق ─────────────────────
  Future<Map<String, dynamic>> fetchEntitlements() async {
    try {
      final authToken = _authToken;
      final accountId = _accountId;

      if (authToken == null || authToken.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }
      if (accountId == null) {
        throw Exception('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول مرة أخرى.');
      }

      final url = '/api/v1/accounts/$accountId/billing/entitlements';

      print('📤 GET Fetch Entitlements: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'api_access_token': authToken,
          },
        ),
      );

      print('📥 Entitlements Status: ${response.statusCode}');
      print('📥 Entitlements Data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ Loaded entitlements successfully');
        return response.data;
      }

      throw Exception('فشل جلب الحقوق: ${response.statusCode}');
    } catch (e) {
      print('❌ Fetch Entitlements Error: $e');
      throw Exception('فشل جلب الحقوق: $e');
    }
  }

  // ─── طلب رابط الدفع (Browser-based) ────────────
  Future<String> createCheckoutUrl({
    required int planId,
  }) async {
    try {
      final authToken = _authToken;
      final accountId = _accountId;

      if (authToken == null || authToken.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }
      if (accountId == null) {
        throw Exception('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول مرة أخرى.');
      }

      final url = '/api/v1/accounts/$accountId/billing/checkout';

      print('📤 POST Create Checkout URL: $url');
      print('📤 Plan ID: $planId');

      final response = await _dio.post(
        url,
        data: {
          'plan_id': planId,
          'mobile': true,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': authToken,
          },
        ),
      );

      print('📥 Checkout URL Status: ${response.statusCode}');
      print('📥 Checkout URL Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final checkoutUrl = response.data['url'];
        print('✅ Checkout URL: $checkoutUrl');
        return checkoutUrl;
      }

      throw Exception('فشل إنشاء رابط الدفع: ${response.statusCode}');
    } catch (e) {
      print('❌ Create Checkout URL Error: $e');
      throw Exception('فشل إنشاء رابط الدفع: تأكد من صحة البيانات');
    }
  }

  // ─── طلب رابط إدارة الفوترة ─────────────────────
  Future<String> createBillingPortalUrl() async {
    try {
      final authToken = _authToken;
      final accountId = _accountId;

      if (authToken == null || authToken.isEmpty) {
        throw Exception('لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
      }
      if (accountId == null) {
        throw Exception('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول مرة أخرى.');
      }

      final url = '/api/v1/accounts/$accountId/billing/portal';

      print('📤 POST Create Billing Portal URL: $url');

      final response = await _dio.post(
        url,
        data: {'mobile': true},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': authToken,
          },
        ),
      );

      print('📥 Billing Portal URL Status: ${response.statusCode}');
      print('📥 Billing Portal URL Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final portalUrl = response.data['url'];
        print('✅ Billing Portal URL: $portalUrl');
        return portalUrl;
      }

      throw Exception('فشل إنشاء رابط إدارة الفوترة: ${response.statusCode}');
    } catch (e) {
      print('❌ Create Billing Portal URL Error: $e');
      throw Exception('فشل إنشاء رابط إدارة الفوترة: تأكد من صحة البيانات');
    }
  }

  // ─── إنشاء Payment Intent (Stripe) - محفوظة للاستخدام المستقبلي ────────────
  Future<String> createPaymentIntent({
    required int accountId,
    required String plan,
  }) async {
    try {
      final token = _authToken;
      if (token == null || token.isEmpty) {
        throw Exception(
            'لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
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
    required String orderId,
    required String planId,
  }) async {
    try {
      const url = 'https://lynomia.com/api/verify-purchase';

      print('📤 POST Verify Google Play Purchase: $url');
      print('📤 Account ID: $accountId');
      print('📤 Product ID: $productId');
      print('📤 Purchase Token: $purchaseToken');
      print('📤 Order ID: $orderId');
      print('📤 Plan ID: $planId');

      final token = _authToken;
      if (token == null || token.isEmpty) {
        print('❌ No Lynomia token found');
        return false;
      }

      final response = await _dio.post(
        url,
        data: {
          'platform': 'chat',
          'user_id': accountId,
          'plan_id': planId,
          'product_id': productId,
          'order_id': orderId,
          'plan_type': 'monthly',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Verification Status: ${response.statusCode}');
      print('📥 Verification Response Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Purchase verified successfully');
        return true;
      }

      print('❌ Verification failed: ${response.statusCode}');
      print('❌ Response: ${response.data}');
      return false;
    } catch (e) {
      print('❌ Verify Purchase Error: $e');
      return false;
    }
  }

  Future<List<PaymentHistoryModel>> fetchPaymentHistory({
    required int accountId,
  }) async {
    try {
      final token = _authToken;
      if (token == null || token.isEmpty) {
        throw Exception(
            'لم يتم العثور على توكن الدفع. يرجى تسجيل الدخول مرة أخرى.');
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
        final List<PaymentHistoryModel> history =
            data.map((item) => PaymentHistoryModel.fromJson(item)).toList();

        print('✅ Loaded ${history.length} payment records');
        return history;
      }

      throw Exception('فشل جلب سجل الاشتراكات: ${response.statusCode}');
    } catch (e) {
      print('❌ Fetch Payment History Error: $e');
      rethrow;
    }
  }
}

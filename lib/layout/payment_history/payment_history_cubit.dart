import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/network/payment_api_service.dart';
import '../../shared/network/local/cache_helper.dart';
import 'payment_history_states.dart';

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  final PaymentApiService _apiService;

  PaymentHistoryCubit(this._apiService) : super(PaymentHistoryInitial());

  // ─── جلب سجل الاشتراكات ─────────────────────
  Future<void> fetchPaymentHistory() async {
    emit(PaymentHistoryLoading());

    try {
      // جلب account_id من الكاش
      final accountId = CacheHelper.getData(key: CacheHelper.keyAccountId) ?? 0;

      if (accountId == 0) {
        emit(const PaymentHistoryError('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول.'));
        return;
      }

      final history = await _apiService.fetchPaymentHistory(accountId: accountId);
      emit(PaymentHistoryLoaded(history));
    } catch (e) {
      print('❌ Fetch Payment History Error: $e');
      emit(PaymentHistoryError(_formatUserFriendlyError(e)));
    }
  }

  String _formatUserFriendlyError(dynamic error) {
    if (error is DioError) {
      if (error.type == DioErrorType.connectTimeout ||
          error.type == DioErrorType.sendTimeout ||
          error.type == DioErrorType.receiveTimeout ||
          error.type == DioErrorType.other) {
        return 'تعذر الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'حدث خطأ في الخادم (رمز $statusCode). يرجى المحاولة في وقت لاحق.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مرة أخرى.';
      }
      return 'حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة مرة أخرى.';
    }

    String msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }

    if (msg.contains('DioError') ||
        msg.contains('DioException') ||
        msg.contains('Http status error') ||
        msg.contains('Source stack:')) {
      if (msg.contains('500')) {
        return 'حدث خطأ في الخادم يرجى المحاولة في وقت لاحق.';
      }
      return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
    }

    return msg;
  }
}

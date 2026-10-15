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
        emit(const PaymentHistoryError('history_no_account'));
        return;
      }

      final history = await _apiService.fetchPaymentHistory(accountId: accountId);
      emit(PaymentHistoryLoaded(history));
    } catch (e) {
      print('❌ Fetch Payment History Error: $e');
      emit(PaymentHistoryError(_formatUserFriendlyError(e)));
    }
  }

  /// Which failure this was, as a catalogue key.
  ///
  /// These were eight hardcoded Arabic sentences, and the error state prints the string it is given
  /// as it stands, so an English user read them in Arabic. A cubit has no `BuildContext` and so
  /// cannot translate; it names the failure and the view says it in the reader's language. `tr`
  /// returns an unrecognised string unchanged, so a message the server wrote still shows verbatim.
  String _formatUserFriendlyError(dynamic error) {
    if (error is DioError) {
      if (error.type == DioErrorType.connectTimeout ||
          error.type == DioErrorType.sendTimeout ||
          error.type == DioErrorType.receiveTimeout ||
          error.type == DioErrorType.other) {
        return 'history_network';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) return 'history_session_expired';
      if (statusCode != null && statusCode >= 500) return 'history_server';
      return 'history_unexpected';
    }

    // Anything that reads like a transport failure rather than a sentence someone wrote: Dio's
    // `toString` carries a stack trace, which is not something to show a customer.
    final msg = error.toString();
    if (msg.contains('DioError') ||
        msg.contains('DioException') ||
        msg.contains('Http status error') ||
        msg.contains('Source stack:')) {
      return msg.contains('500') ? 'history_server' : 'history_unexpected';
    }

    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }
}

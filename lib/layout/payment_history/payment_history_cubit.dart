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
        emit(const PaymentHistoryError('لم يتم العثور على معرف الحساب. يرجى تسجيل الدخول'));
        return;
      }

      final history = await _apiService.fetchPaymentHistory(accountId: accountId);
      emit(PaymentHistoryLoaded(history));
    } catch (e) {
      print('❌ Fetch Payment History Error: $e');
      emit(PaymentHistoryError(e.toString()));
    }
  }
}

import 'package:equatable/equatable.dart';
import '../../models/payment_history_model.dart';

abstract class PaymentHistoryState extends Equatable {
  const PaymentHistoryState();

  @override
  List<Object?> get props => [];
}

class PaymentHistoryInitial extends PaymentHistoryState {}

class PaymentHistoryLoading extends PaymentHistoryState {}

class PaymentHistoryLoaded extends PaymentHistoryState {
  final List<PaymentHistoryModel> history;

  const PaymentHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class PaymentHistoryError extends PaymentHistoryState {
  final String error;

  const PaymentHistoryError(this.error);

  @override
  List<Object?> get props => [error];
}



import 'package:chat/layout/payment/payment_cubit.dart';
import 'package:equatable/equatable.dart';

import '../../models/plan_models.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}



class PaymentIntentLoaded extends PaymentState {
  final String paymentIntent;
  const PaymentIntentLoaded(this.paymentIntent);
  @override
  List<Object?> get props => [paymentIntent];
}


class PaymentMethodChanged extends PaymentState {
  final PaymentMethod method;
  const PaymentMethodChanged(this.method);
  @override
  List<Object?> get props => [method];
}

class PlansLoading extends PaymentState {}

class PlansLoaded extends PaymentState {
  final List<PlanModel> plans;
  final PlanModel? selectedPlan;
  const PlansLoaded(this.plans, {this.selectedPlan});
  @override
  List<Object?> get props => [plans, selectedPlan];
}

class PlansError extends PaymentState {
  final String message;
  const PlansError(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final String paymentId;
  final String planName;
  const PaymentSuccess(this.paymentId, this.planName);
  @override
  List<Object?> get props => [paymentId, planName];
}

class PaymentCancelled extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}
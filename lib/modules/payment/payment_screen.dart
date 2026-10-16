import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:chat/layout/payment/payment_cubit.dart';
import 'package:chat/layout/payment/payment_states.dart';
import 'package:chat/shared/app_localizations.dart';
import 'package:chat/shared/network/local/cache_helper.dart';

import '../../layout/cubit/cubit.dart';
import '../../models/plan_models.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_plan.dart';
import '../../shared/styles/lyn_type.dart';

/// Paying for the plan: the cubit wiring. The layout is [PaymentForm].
///
/// WHAT THIS SCREEN USED TO BE. One long scroll: a 24-padding hero card for the plan, two payment
/// methods, then the plan's ENTIRE feature list again — the same list the buyer had just read on the
/// previous screen — then three security panels, and only then the pay button, roughly 1,100 pixels
/// down. On an 844-tall phone the action was three screens below the fold, and the amount being
/// charged scrolled out of sight long before it.
///
/// WHAT IT IS NOW. The amount and the button are pinned to the bottom, together, so the figure you
/// are agreeing to is on screen at the moment you agree to it. The feature list is still here and
/// still complete, but folded shut, because it is a reassurance on this screen rather than the reason
/// for it. Google Play is offered only where Google Play can take a payment.
class PaymentScreen extends StatelessWidget {
  final PlanModel plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;

    return Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        backgroundColor: LynSurface.surface(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        title: Text(
          AppLocalizations.tr(context, 'Complete payment'),
          style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
        ),
      ),
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentResultScreen(
                  isSuccess: true,
                  paymentId: state.paymentId,
                  planName: state.planName,
                ),
              ),
            );
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // The cubit emits a catalogue KEY for the failures it raises itself; `tr` returns any
                // other string unchanged, so a message relayed from the server still shows verbatim.
                // Those failures used to be hardcoded Arabic sentences, shown to English users as-is.
                content: Text(AppLocalizations.tr(context, state.message)),
                backgroundColor: LynPalette.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is PaymentCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.tr(context, 'Payment cancelled')),
                backgroundColor: LynPalette.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<PaymentCubit>();
          return PaymentForm(
            plan: plan,
            method: context.watch<PaymentCubit>().selectedMethod,
            isProcessing: state is PaymentLoading,
            isDark: isDark,
            onMethodChange: cubit.selectPaymentMethod,
            onPay: () => cubit.completePayment(plan: plan.id),
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }
}

/// What is being bought, how it will be paid for, and the action — as a widget, so a golden can pump
/// exactly what ships rather than a reconstruction of it.
class PaymentForm extends StatelessWidget {
  const PaymentForm({
    super.key,
    required this.plan,
    required this.method,
    required this.isProcessing,
    required this.isDark,
    required this.onMethodChange,
    required this.onPay,
    required this.onCancel,
  });

  final PlanModel plan;
  final PaymentMethod method;
  final bool isProcessing;
  final bool isDark;
  final ValueChanged<PaymentMethod> onMethodChange;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  // Was `_getPlanColor`, a second private copy that disagreed with the plan screen's: `startup` came
  // out indigo here and blue there, so a plan changed colour between the two steps of one purchase.
  ({Color fill, Color ink}) get _accent => LynPlan.accent(plan.id, isDark);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LynSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _orderSummary(context),
                  const SizedBox(height: LynSpace.xl),
                  _sectionHead(context, 'Payment method'),
                  const SizedBox(height: LynSpace.md),

                  // Android only. Google Play Billing cannot take a payment on an iPhone, so on iOS
                  // this card used to be a guaranteed dead end: selecting it and paying hit
                  // `isAvailable == false` and raised an error.
                  if (Platform.isAndroid) ...[
                    _methodCard(
                      context: context,
                      title: 'Google Play',
                      subtitle: AppLocalizations.tr(context, 'Payment via Google Play Billing'),
                      icon: Icons.play_circle_fill,
                      // Google's own blue: a third party's mark, not a product colour.
                      brand: const Color(0xFF4285F4),
                      isSelected: method == PaymentMethod.googlePlay,
                      onTap: isProcessing ? null : () => onMethodChange(PaymentMethod.googlePlay),
                    ),
                    const SizedBox(height: LynSpace.md),
                  ],

                  _methodCard(
                    context: context,
                    title: AppLocalizations.tr(context, 'Credit Card (Stripe)'),
                    subtitle: AppLocalizations.tr(context, 'Credit card payment'),
                    icon: Icons.credit_card,
                    // Stripe's own violet, for the same reason.
                    brand: const Color(0xFF635BFF),
                    isSelected: method == PaymentMethod.stripe,
                    onTap: isProcessing ? null : () => onMethodChange(PaymentMethod.stripe),
                  ),

                  const SizedBox(height: LynSpace.xl),
                  _features(context),
                  const SizedBox(height: LynSpace.xl),
                  _sectionHead(context, 'Your payment is secure'),
                  const SizedBox(height: LynSpace.md),
                  _security(context),
                ],
              ),
            ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  Widget _sectionHead(BuildContext context, String key) => Text(
        AppLocalizations.tr(context, key),
        style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
      );

  /// What is being bought, in one band: the plan, its price, and the limits that distinguish it.
  Widget _orderSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LynSpace.lg),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.lg),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
                ),
              ),
              const SizedBox(width: LynSpace.sm),
              Text(plan.formattedPrice, style: LynType.subtitle.copyWith(color: _accent.ink)),
            ],
          ),
          const SizedBox(height: LynSpace.sm),
          Text(
            // One line, separated by a middot, instead of two icon-and-label pairs on a row that
            // overflowed once Arabic set the numbers wider.
            '${LynPlan.agents(context, plan.agents)}  ·  ${LynPlan.inboxes(context, plan.inboxes)}',
            style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  /// The plan's features, complete, but folded shut: the buyer read them on the previous screen, and
  /// unfolded they put a thousand pixels between this screen's top and its button.
  Widget _features(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.md),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Theme(
        // The stock tile draws its own dividers above and below; the container's border is the edge.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: LynSpace.lg),
          childrenPadding: const EdgeInsets.fromLTRB(LynSpace.lg, 0, LynSpace.lg, LynSpace.lg),
          iconColor: LynSurface.textSecondary(isDark),
          collapsedIconColor: LynSurface.textSecondary(isDark),
          title: Text(
            AppLocalizations.tr(context, 'Included features'),
            style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
          children: [
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: LynSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child:
                          Icon(Icons.check_rounded, color: LynSurface.successText(isDark), size: 18),
                    ),
                    const SizedBox(width: LynSpace.md),
                    Expanded(
                      child: Text(
                        LynPlan.feature(context, feature),
                        style: LynType.body.copyWith(color: LynSurface.textPrimary(isDark)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _methodCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color brand,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: LynSurface.surface(isDark),
      borderRadius: BorderRadius.circular(LynSpace.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LynSpace.md),
        child: Container(
          padding: const EdgeInsets.all(LynSpace.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LynSpace.md),
            border: Border.all(
              color: isSelected ? brand : LynSurface.border(isDark),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brand.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(LynSpace.sm + 2),
                ),
                child: Icon(icon, color: brand, size: 24),
              ),
              const SizedBox(width: LynSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
                  ],
                ),
              ),
              const SizedBox(width: LynSpace.sm),
              // A radio, not a tick that only ever appears: these two are one choice, and an empty
              // ring on the other card is what says so.
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? brand : LynSurface.borderStrong(isDark),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _security(BuildContext context) {
    return Column(
      children: [
        _securityItem(
          context: context,
          icon: Icons.lock_outline_rounded,
          title: 'Data encryption',
          description: 'All your information is encrypted and protected',
        ),
        // Only where Stripe is the one taking the money. It was claimed on both methods, which made
        // it a promise about a processor that was not involved.
        if (method == PaymentMethod.stripe) ...[
          const SizedBox(height: LynSpace.md),
          _securityItem(
            context: context,
            icon: Icons.verified_user_outlined,
            title: 'Stripe protection',
            description: 'We use Stripe to process payments securely',
          ),
        ],
        const SizedBox(height: LynSpace.md),
        _securityItem(
          context: context,
          icon: Icons.event_busy_outlined,
          title: 'Easy cancellation',
          description: 'You can cancel your subscription at any time',
        ),
      ],
    );
  }

  Widget _securityItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: LynPalette.indigo.withOpacity(isDark ? 0.22 : 0.10),
            borderRadius: BorderRadius.circular(LynSpace.sm + 2),
          ),
          child: Icon(icon,
              color: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep, size: 19),
        ),
        const SizedBox(width: LynSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.tr(context, title),
                  style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark))),
              const SizedBox(height: 2),
              Text(AppLocalizations.tr(context, description),
                  style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
            ],
          ),
        ),
      ],
    );
  }

  /// The amount and the action, together and pinned.
  ///
  /// The button's own label cannot always carry the figure — the Google Play label names the store
  /// rather than a sum — so the figure gets its own line above it and is on screen either way.
  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LynSpace.lg),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        border: Border(top: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.tr(context, 'Total'),
                  style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
                ),
              ),
              Text(plan.formattedPrice,
                  style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
              const SizedBox(width: LynSpace.xs),
              Text(AppLocalizations.tr(context, 'per_month'),
                  style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
            ],
          ),
          const SizedBox(height: LynSpace.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isProcessing ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent.fill,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.fill.withOpacity(0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
              ),
              child: isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: LynSpace.md),
                        Text(AppLocalizations.tr(context, 'Processing payment...'),
                            style: LynType.subtitle.copyWith(color: Colors.white)),
                      ],
                    )
                  : Text(
                      method == PaymentMethod.googlePlay
                          ? AppLocalizations.tr(context, 'Subscribe via Google Play')
                          : AppLocalizations.tr(context, 'Pay {amount}')
                              .replaceFirst('{amount}', plan.formattedPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LynType.subtitle.copyWith(color: Colors.white),
                    ),
            ),
          ),
          if (!isProcessing)
            TextButton(
              onPressed: onCancel,
              child: Text(
                AppLocalizations.tr(context, 'cancel'),
                style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
              ),
            ),
        ],
      ),
    );
  }
}

class PaymentResultScreen extends StatefulWidget {
  final bool isSuccess;
  final String paymentId;
  final String planName;

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    required this.paymentId,
    required this.planName,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _hasCheckedSubscription = false;

  @override
  void initState() {
    super.initState();
    // ✅ تحديث حالة الاشتراك بعد الدفع الناجح - مرة واحدة فقط
    if (widget.isSuccess && !_hasCheckedSubscription) {
      _hasCheckedSubscription = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final appCubit = AppCubit.get(context);
        final userEmail = CacheHelper.getString(key: CacheHelper.keyUserEmail);
        if (userEmail != null && userEmail.isNotEmpty) {
          appCubit.checkSubscription(email: userEmail);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;
    return PaymentResultView(
      isSuccess: widget.isSuccess,
      paymentId: widget.paymentId,
      planName: widget.planName,
      isDark: isDark,
      onDone: () => Navigator.popUntil(context, (route) => route.isFirst),
    );
  }
}

/// How the purchase ended.
class PaymentResultView extends StatelessWidget {
  const PaymentResultView({
    super.key,
    required this.isSuccess,
    required this.paymentId,
    required this.planName,
    required this.isDark,
    required this.onDone,
  });

  final bool isSuccess;
  final String paymentId;
  final String planName;
  final bool isDark;
  final VoidCallback onDone;

  /// What actually happened, in a sentence.
  ///
  /// The plan's name arrives from the server and can be absent — the Stripe deep link reads it out of
  /// an entitlements call that may not have caught up yet. It used to fall back to the Arabic word
  /// 'الجديدة', which an English buyer then read in the middle of an English sentence. A missing name
  /// now picks the sentence that does not need one, which is true in both languages.
  String _message(BuildContext context) {
    if (!isSuccess) {
      return AppLocalizations.tr(
          context, 'An error occurred while processing the payment. Please try again.');
    }
    if (planName.isEmpty) {
      return AppLocalizations.tr(context, 'Your subscription has been activated successfully');
    }
    return AppLocalizations.tr(
            context, 'Your subscription to plan {plan} has been activated successfully')
        .replaceFirst('{plan}', planName);
  }

  @override
  Widget build(BuildContext context) {
    final tone = isSuccess ? LynPalette.success : LynPalette.danger;
    final ink = isSuccess ? LynSurface.successText(isDark) : LynSurface.dangerText(isDark);

    return Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        backgroundColor: LynSurface.canvas(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.xl),
                child: Column(
                  children: [
                    const SizedBox(height: LynSpace.xxl),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: tone.withOpacity(isDark ? 0.22 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_rounded : Icons.close_rounded,
                        color: ink,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: LynSpace.xl),
                    Text(
                      isSuccess
                          ? AppLocalizations.tr(context, 'Payment successful')
                          : AppLocalizations.tr(context, 'Payment failed'),
                      textAlign: TextAlign.center,
                      style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                    ),
                    const SizedBox(height: LynSpace.md),
                    Text(
                      _message(context),
                      textAlign: TextAlign.center,
                      style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark)),
                    ),
                    if (isSuccess && paymentId.isNotEmpty) ...[
                      const SizedBox(height: LynSpace.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(LynSpace.lg),
                        decoration: BoxDecoration(
                          color: LynSurface.surface(isDark),
                          borderRadius: BorderRadius.circular(LynSpace.md),
                          border: Border.all(color: LynSurface.border(isDark)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.tr(context, 'Transaction ID'),
                              style:
                                  LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
                            ),
                            const SizedBox(height: LynSpace.xs),
                            Text(
                              paymentId,
                              // Left-to-right even in Arabic: a reference someone reads out or
                              // compares against a receipt character by character must not have its
                              // segments reordered by the bidi algorithm.
                              textDirection: TextDirection.ltr,
                              style: LynType.body.copyWith(
                                color: LynSurface.textPrimary(isDark),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: LynSpace.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LynSpace.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? LynPalette.success : LynPalette.indigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
                  ),
                  child: Text(
                    isSuccess
                        ? AppLocalizations.tr(context, 'Back to home')
                        : AppLocalizations.tr(context, 'Try again'),
                    style: LynType.subtitle.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

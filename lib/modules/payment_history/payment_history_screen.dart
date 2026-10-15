import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// The intl package exports its own `TextDirection`, which shadows the framework's.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/payment_history/payment_history_cubit.dart';
import '../../layout/payment_history/payment_history_states.dart';
import '../../models/payment_history_model.dart';
import '../../shared/app_localizations.dart';
import '../../shared/network/payment_api_service.dart';
import '../../shared/styles/lyn_controls.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

/// What has been paid, and when: the cubit wiring. The layout is [PaymentHistoryList].
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;

    return BlocProvider(
      create: (context) => PaymentHistoryCubit(PaymentApiService(Dio()))..fetchPaymentHistory(),
      child: Scaffold(
        backgroundColor: LynSurface.canvas(isDark),
        appBar: AppBar(
          backgroundColor: LynSurface.surface(isDark),
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
          iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
          title: Text(
            AppLocalizations.tr(context, 'Payment history'),
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
        ),
        body: BlocBuilder<PaymentHistoryCubit, PaymentHistoryState>(
          builder: (context, state) {
            if (state is PaymentHistoryLoaded) {
              return PaymentHistoryList(
                history: state.history,
                isDark: isDark,
                onRefresh: context.read<PaymentHistoryCubit>().fetchPaymentHistory,
              );
            }
            if (state is PaymentHistoryError) {
              return PaymentHistoryFailure(
                // The cubit names the failure; this is where it gets said in the reader's language.
                // `tr` passes an unrecognised string through, so a server message still shows.
                message: AppLocalizations.tr(context, state.error),
                isDark: isDark,
                onRetry: context.read<PaymentHistoryCubit>().fetchPaymentHistory,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

/// The receipts.
///
/// Each row was a shadowed card with its content on one cramped line: the plan and date on the left,
/// the amount on the right, and underneath two columns sharing the width — one of them holding a
/// Stripe intent id, 27 characters wide, in about 150 pixels, which wrapped to three lines and left
/// the two columns ragged against each other. The amount is the thing being looked for, so it leads;
/// the reference sits on its own full-width line beneath, where it fits.
class PaymentHistoryList extends StatelessWidget {
  const PaymentHistoryList({
    super.key,
    required this.history,
    required this.isDark,
    required this.onRefresh,
  });

  final List<PaymentHistoryModel> history;
  final bool isDark;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return PaymentHistoryEmpty(isDark: isDark);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: LynPalette.indigo,
      child: ListView.separated(
        padding: const EdgeInsets.all(LynSpace.lg),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: LynSpace.md),
        itemBuilder: (context, i) => _receipt(context, history[i]),
      ),
    );
  }

  Widget _receipt(BuildContext context, PaymentHistoryModel payment) {
    final accent = _accent(payment.way, isDark);
    final name = payment.planName.isEmpty
        // The note did not carry a plan name. Naming the thing generically is true; the word
        // "Unknown" was not, and was printed in English to Arabic readers.
        ? AppLocalizations.tr(context, 'Subscription')
        : payment.planName;

    return Container(
      padding: const EdgeInsets.all(LynSpace.lg),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.md),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.fill.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(LynSpace.sm + 2),
                ),
                child: Icon(_icon(payment.way), color: accent.ink, size: 20),
              ),
              const SizedBox(width: LynSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Was '${day}/${month}/${year}' — unpadded, ambiguous, and in Latin digits
                      // and slashes in the middle of an Arabic screen. The active locale decides.
                      DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                          .format(payment.createdAt),
                      style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LynSpace.sm),
              Text(
                payment.formattedPrice,
                // The amount is a figure read against a bank statement, so its digits line up.
                style: LynType.subtitle.copyWith(
                  color: LynSurface.textPrimary(isDark),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: LynSpace.md),
          Divider(height: 1, thickness: 1, color: LynSurface.border(isDark)),
          const SizedBox(height: LynSpace.md),
          _field(context, AppLocalizations.tr(context, 'Payment method'),
              _methodLabel(context, payment.way)),
          const SizedBox(height: LynSpace.sm),
          _field(context, AppLocalizations.tr(context, 'Transaction ID'), payment.intentId,
              monospaceDigits: true),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value,
      {bool monospaceDigits = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(label,
              style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
        ),
        Expanded(
          child: Text(
            value,
            // A reference is read out or compared against a receipt character by character, so the
            // bidi algorithm must not reorder its segments on an Arabic screen.
            textDirection: monospaceDigits ? TextDirection.ltr : null,
            textAlign: monospaceDigits ? TextAlign.start : null,
            style: LynType.caption.copyWith(
              color: LynSurface.textPrimary(isDark),
              fontFeatures:
                  monospaceDigits ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ),
      ],
    );
  }

  /// What the buyer paid through, in words. It was `way.toUpperCase()`, so the screen said
  /// "GOOGLE_PLAY" — a database value with its underscore, shouted.
  String _methodLabel(BuildContext context, String way) {
    switch (way.toLowerCase()) {
      case 'stripe':
        return AppLocalizations.tr(context, 'Credit Card (Stripe)');
      case 'google_play':
        return 'Google Play';
      default:
        return way;
    }
  }

  IconData _icon(String way) {
    switch (way.toLowerCase()) {
      case 'stripe':
        return Icons.credit_card_outlined;
      case 'google_play':
        return Icons.play_circle_outline;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  /// The processor's colour. It used to be success-green for Google Play and warning-amber for
  /// anything else, which reads as the state of the payment — these rows are all settled payments,
  /// and none of them is a warning. Brand hues and a neutral default say "which processor" without
  /// saying "and here is how it went".
  ({Color fill, Color ink}) _accent(String way, bool isDark) {
    switch (way.toLowerCase()) {
      case 'stripe':
        return (
          fill: LynPalette.indigo,
          ink: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep,
        );
      case 'google_play':
        return (
          fill: LynPalette.blue,
          ink: isDark ? LynPalette.blueOnDark : LynPalette.royal,
        );
      default:
        return (
          fill: LynSurface.borderStrong(isDark),
          ink: LynSurface.textSecondary(isDark),
        );
    }
  }
}

/// Nothing has been paid yet.
class PaymentHistoryEmpty extends StatelessWidget {
  const PaymentHistoryEmpty({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LynSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: LynSurface.surfaceMuted(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 32, color: LynSurface.textTertiary(isDark)),
            ),
            const SizedBox(height: LynSpace.lg),
            Text(
              AppLocalizations.tr(context, 'No payment history'),
              textAlign: TextAlign.center,
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
            ),
            const SizedBox(height: LynSpace.sm),
            Text(
              AppLocalizations.tr(context, 'Receipts appear here after your first payment.'),
              textAlign: TextAlign.center,
              style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark)),
            ),
            const SizedBox(height: LynSpace.xxl),
            LynPoweredBy(
              isDark: isDark,
              onTap: () async {
                final url = Uri.parse('https://lynomia.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The history could not be fetched.
class PaymentHistoryFailure extends StatelessWidget {
  const PaymentHistoryFailure({
    super.key,
    required this.message,
    required this.isDark,
    required this.onRetry,
  });

  final String message;
  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LynSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: LynSurface.dangerSurface(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 32, color: LynSurface.dangerText(isDark)),
            ),
            const SizedBox(height: LynSpace.lg),
            Text(
              AppLocalizations.tr(context, 'Error loading payment history'),
              textAlign: TextAlign.center,
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
            ),
            const SizedBox(height: LynSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark)),
              ),
            ),
            const SizedBox(height: LynSpace.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppLocalizations.tr(context, 'Retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: LynPalette.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: LynSpace.xl, vertical: LynSpace.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

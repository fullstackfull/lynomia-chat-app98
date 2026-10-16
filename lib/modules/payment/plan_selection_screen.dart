import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chat/layout/payment/payment_cubit.dart';
import 'package:chat/layout/payment/payment_states.dart';
import 'package:chat/shared/network/payment_api_service.dart';

import '../../layout/cubit/cubit.dart';
import '../../models/plan_models.dart';
import '../../shared/app_localizations.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_plan.dart';
import '../../shared/styles/lyn_type.dart';
import 'payment_screen.dart';

/// Choosing a plan.
///
/// WHAT THIS SCREEN USED TO BE. Three cards, each about 420 logical pixels tall, stacked. A phone is
/// 844 tall with an app bar on it, so one card filled the view and the next showed as a sliver.
/// Comparing plans — the only thing this screen exists to do — meant scrolling down, scrolling back,
/// and holding the first price in your head. The "Subscribe" button repeated three times, once per
/// card, so the action moved as you scrolled.
///
/// WHAT IT IS NOW. Every plan's name and price sit on one row, visible at once, which is the comparison
/// the buyer came for. Tapping one shows that plan's limits and features below. The action is a single
/// button pinned to the bottom that names the plan it will buy, so it is one thumb-reach away no matter
/// how long the feature list runs.
class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;

    return BlocProvider(
      create: (context) => PaymentCubit(PaymentApiService(Dio()))..loadPlans(),
      child: Scaffold(
        backgroundColor: LynSurface.canvas(isDark),
        appBar: AppBar(
          backgroundColor: LynSurface.surface(isDark),
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
          iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
          title: Text(
            AppLocalizations.tr(context, 'Choose the plan'),
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
          actions: [
            // Android only, because the destination is Google Play's own subscription page. An iPhone
            // user has no subscription there, so offering them the link would be a dead end.
            //
            // This existed as a `SubscriptionManager` class that nothing called: its one caller was a
            // commented-out app bar action, which made a shipped feature unreachable.
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: LynSpace.sm),
                child: TextButton(
                  onPressed: SubscriptionManager.openSubscriptionManagement,
                  child: Text(
                    AppLocalizations.tr(context, 'Manage subscription'),
                    style: LynType.callout.copyWith(color: LynPalette.indigo),
                  ),
                ),
              ),
          ],
        ),
        body: BlocConsumer<PaymentCubit, PaymentState>(
          // ONLY the plan-loading states rebuild this screen. The payment screen is pushed with this
          // same cubit, so picking a payment method there emits `PaymentMethodChanged` — and without
          // this guard that rebuilt the screen underneath into the fallback spinner. Pressing back
          // then landed on a spinner that never resolved, because nothing would emit `PlansLoaded`
          // again. Ignoring the payment flow's states leaves the last loaded plans on screen.
          buildWhen: (_, state) =>
              state is PlansLoaded ||
              state is PlansLoading ||
              state is PlansError ||
              state is PaymentInitial,
          listener: (context, state) {
            if (state is PlansError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.tr(context, 'No internet connection')),
                  backgroundColor: LynPalette.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PlansError) return _error(context, isDark);
            if (state is PlansLoaded) {
              if (state.plans.isEmpty) return _error(context, isDark);
              // The cubit's `selectedPlan` is null until something is tapped. Resolving the default
              // here rather than emitting one keeps the screen a pure function of the state it was
              // given.
              final selected = state.selectedPlan ??
                  state.plans.firstWhere(
                    (p) => LynPlan.isRecommended(p.id),
                    orElse: () => state.plans.first,
                  );
              return PlanPicker(
                plans: state.plans,
                selected: selected,
                isDark: isDark,
                onSelect: context.read<PaymentCubit>().selectPlan,
                onSubscribe: () {
                  final paymentCubit = context.read<PaymentCubit>();
                  // The Google Play path reads `selectedPlan` off the state for the plan's name on
                  // success, so it has to be set even when the buyer took the default and tapped
                  // nothing.
                  paymentCubit.selectPlan(selected);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: paymentCubit,
                        child: PaymentScreen(plan: selected),
                      ),
                    ),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _error(BuildContext context, bool isDark) {
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
                color: LynSurface.dangerSurface(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 32, color: LynSurface.dangerText(isDark)),
            ),
            const SizedBox(height: LynSpace.xl),
            Text(
              AppLocalizations.tr(context, 'Failed to load plans.'),
              textAlign: TextAlign.center,
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
            ),
            const SizedBox(height: LynSpace.xl),
            ElevatedButton(
              onPressed: () => context.read<PaymentCubit>().loadPlans(),
              style: ElevatedButton.styleFrom(
                backgroundColor: LynPalette.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.xl, vertical: LynSpace.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
              ),
              // Was the hardcoded Arabic 'إعادة المحاولة', printed as-is to English users.
              child: Text(AppLocalizations.tr(context, 'Retry'), style: LynType.callout),
            ),
          ],
        ),
      ),
    );
  }

}

/// The plan comparison, and the one button that acts on it.
///
/// A widget rather than a method on the screen, for the same reason `HomeView` is: a golden can pump
/// this and be rendering exactly what ships, instead of a reconstruction of it. It takes plain values
/// and callbacks and knows nothing about the cubit.
class PlanPicker extends StatelessWidget {
  const PlanPicker({
    super.key,
    required this.plans,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    required this.onSubscribe,
  });

  final List<PlanModel> plans;
  final PlanModel selected;
  final bool isDark;
  final ValueChanged<PlanModel> onSelect;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final accent = LynPlan.accent(selected.id, isDark);

    return SafeArea(
      child: Column(
        // Stretch, not the default centre: a centred Column shrink-wraps each child to its own width,
        // which floated the heading and its subtitle into the middle of the screen instead of setting
        // them against the gutter the rest of the layout uses.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(LynSpace.lg, LynSpace.lg, LynSpace.lg, LynSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'Subscription plans'),
                  style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                ),
                const SizedBox(height: LynSpace.xs),
                Text(
                  AppLocalizations.tr(context, 'Choose the plan that suits your needs.'),
                  style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark)),
                ),
              ],
            ),
          ),

          // The comparison. Expanded cells, so the row divides whatever width there is and can never
          // overflow however many plans the API sends or how long their names are.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg),
            // The cells have to be the same height — the recommended one carries an extra line, and
            // three boxes of three different depths with their borders at three different places is
            // not a row. `stretch` alone cannot do it here: this Row sits in a Column that gives its
            // children unbounded height, so stretching to the parent means stretching to infinity,
            // which is what the first golden of this screen asserted on. `IntrinsicHeight` measures
            // the tallest cell first and gives the Row that as its bound.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final plan in plans) ...[
                    Expanded(
                      child: _PlanTab(
                        plan: plan,
                        isSelected: plan.id == selected.id,
                        isDark: isDark,
                        onTap: () => onSelect(plan),
                      ),
                    ),
                    if (plan != plans.last) const SizedBox(width: LynSpace.sm),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: LynSpace.lg),
          Divider(height: 1, thickness: 1, color: LynSurface.border(isDark)),

          Expanded(child: _detail(context, accent)),

          // Pinned, so the action never moves and never needs scrolling to.
          Container(
            padding: const EdgeInsets.all(LynSpace.lg),
            decoration: BoxDecoration(
              color: LynSurface.surface(isDark),
              border: Border(top: BorderSide(color: LynSurface.border(isDark))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent.fill,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LynSpace.md)),
                ),
                child: Text(
                  AppLocalizations.tr(context, 'Subscribe to {plan}')
                      .replaceFirst('{plan}', selected.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LynType.subtitle.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, ({Color fill, Color ink}) accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(LynSpace.lg, LynSpace.xl, LynSpace.lg, LynSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(selected.formattedPrice, style: LynType.display.copyWith(color: accent.ink)),
              const SizedBox(width: LynSpace.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: LynSpace.xs + 2),
                child: Text(
                  // Was the hardcoded Arabic '/شهر' beside every price, in both languages.
                  AppLocalizations.tr(context, 'per_month'),
                  style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: LynSpace.lg),
          Row(
            children: [
              _limitChip(
                icon: Icons.people_outline_rounded,
                label: LynPlan.agents(context, selected.agents),
                accent: accent,
              ),
              const SizedBox(width: LynSpace.sm),
              _limitChip(
                icon: Icons.inbox_outlined,
                label: LynPlan.inboxes(context, selected.inboxes),
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: LynSpace.xl),
          Text(
            AppLocalizations.tr(context, 'What you get'),
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
          const SizedBox(height: LynSpace.md),
          for (final feature in selected.features)
            Padding(
              padding: const EdgeInsets.only(bottom: LynSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_rounded, color: accent.ink, size: 18),
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
    );
  }

  Widget _limitChip({
    required IconData icon,
    required String label,
    required ({Color fill, Color ink}) accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.sm - 1),
      decoration: BoxDecoration(
        color: accent.fill.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent.ink, size: 15),
          const SizedBox(width: LynSpace.xs + 2),
          Text(label, style: LynType.caption.copyWith(color: accent.ink)),
        ],
      ),
    );
  }
}

/// One plan in the comparison row: its name, its price, and whether the product recommends it.
///
/// The recommendation used to be a `PositionedDirectional` flag floating in a `Stack` over the card's
/// corner, where it sat on top of the plan's own name. Here it is a line of the cell's own layout, so
/// nothing can collide with anything.
class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.plan,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final PlanModel plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = LynPlan.accent(plan.id, isDark);
    final recommended = LynPlan.isRecommended(plan.id);

    return Material(
      color: isSelected ? accent.fill.withOpacity(isDark ? 0.18 : 0.08) : LynSurface.surface(isDark),
      borderRadius: BorderRadius.circular(LynSpace.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LynSpace.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: LynSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LynSpace.md),
            border: Border.all(
              color: isSelected ? accent.fill : LynSurface.border(isDark),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            // Not `min`: the cell is stretched to the row's height, and the content sits at the top
            // of it rather than floating in the middle of a taller box.
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                plan.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LynType.caption.copyWith(
                  color: isSelected ? accent.ink : LynSurface.textSecondary(isDark),
                ),
              ),
              const SizedBox(height: LynSpace.xs),
              // Scaled down rather than ellipsised: a truncated price is worse than a small one.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  plan.formattedPrice,
                  style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
                ),
              ),
              if (recommended) ...[
                const SizedBox(height: LynSpace.xs + 2),
                Text(
                  // Was the hardcoded Arabic 'الأكثر شيوعاً' on the English screen too.
                  AppLocalizations.tr(context, 'Most popular'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LynType.micro.copyWith(color: accent.ink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Google Play's own subscription management, which is where an Android buyer cancels or changes a
/// plan. Reached from this screen's app bar on Android.
class SubscriptionManager {
  const SubscriptionManager._();

  static Future<void> openSubscriptionManagement() async {
    final url = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

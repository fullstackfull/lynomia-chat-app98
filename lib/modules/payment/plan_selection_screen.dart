import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat/layout/payment/payment_cubit.dart';
import 'package:chat/layout/payment/payment_states.dart';
import 'package:chat/shared/network/payment_api_service.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../models/plan_models.dart';
import '../../shared/app_localizations.dart';
import 'payment_screen.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;

    return BlocProvider(
      create: (context) => PaymentCubit(PaymentApiService(Dio()))..loadPlans(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: LynSurface.surface(isDark),
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
          iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
          title: Text(AppLocalizations.tr(context, 'Choose the plan'),
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
          ),
          // actions: [
          //   // ✅ زر إدارة الاشتراكات
          //   TextButton.icon(
          //     onPressed: () => _openSubscriptionManagement(),
          //     icon: Icon(
          //       Icons.settings,
          //       color: LynPalette.indigo,
          //       size: 20,
          //     ),
          //     label: Text(AppLocalizations.tr(context, 'Subscriptions'),
          //       style: TextStyle(
          //         color: LynPalette.indigo,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ],
        ),
        body: BlocConsumer<PaymentCubit, PaymentState>(
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
            if (state is PlansLoading || state is PaymentInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PlansError) {
              return Center(
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
                      child: Icon(Icons.wifi_off_rounded,
                          size: 32, color: LynSurface.dangerText(isDark)),
                    ),
                    const SizedBox(height: LynSpace.xl),
                    Text(AppLocalizations.tr(context, 'Failed to load plans.'),
                      style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
                    ),
                    const SizedBox(height: LynSpace.xl),
                    ElevatedButton(
                      onPressed: () => context.read<PaymentCubit>().loadPlans(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LynPalette.indigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: LynSpace.xl, vertical: LynSpace.md),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(LynSpace.md)),
                      ),
                      // Was the hardcoded Arabic 'إعادة المحاولة', printed as-is to English users.
                      child: Text(AppLocalizations.tr(context, 'Retry'), style: LynType.callout),
                    ),
                  ],
                ),
              );
            }

            if (state is PlansLoaded) {
              return _buildPlansList(context, state.plans, isDark);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }


  // ─── ترجمة المميزات ديناميكياً ─────────────────
  String _translateFeature(BuildContext context, String featureKey) {
    final translated = AppLocalizations.tr(context, 'feature_$featureKey');

    if (translated == 'feature_$featureKey') {
      return _formatFeatureKey(featureKey);
    }

    return translated;
  }

  String _formatFeatureKey(String key) {
    return key
        .split('_')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : '')
        .join(' ');
  }

  String _translateAgents(BuildContext context, int count) {
    return AppLocalizations.tr(context, 'limit_agents')
        .replaceFirst('{count}', count.toString());
  }

  String _translateInboxes(BuildContext context, int count) {
    return AppLocalizations.tr(context, 'limit_inboxes')
        .replaceFirst('{count}', count.toString());
  }

  Widget _buildPlansList(BuildContext context, List<PlanModel> plans, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LynSpace.xl, LynSpace.xl, LynSpace.xl, LynSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(AppLocalizations.tr(context, 'Subscription Plans'),
                    textAlign: TextAlign.center,
                    style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                  ),
                  const SizedBox(height: LynSpace.sm),
                  Text(AppLocalizations.tr(context, 'Choose the plan that suits your needs.'),
                    textAlign: TextAlign.center,
                    style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LynSpace.xl),

            // ✅ معلومات التجديد التلقائي
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: isDark ? HexColor('#1E293B') : HexColor('#F0F9FF'),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(
            //       color: HexColor('#0EA5E9').withOpacity(0.3),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.info_outline,
            //         color: HexColor('#0EA5E9'),
            //         size: 24,
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(AppLocalizations.tr(context, 'Automatic renewal'),
            //               style: TextStyle(
            //                 color: LynSurface.textPrimary(isDark),
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.w700,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(AppLocalizations.tr(context, 'All subscriptions made via Google Play automatically renew on a monthly basis. You can cancel the renewal at any time in your Google Play settings by using the "Manage subscription" button at the top.'),
            //               style: TextStyle(
            //                 color: LynSurface.textSecondary(isDark),
            //                 fontSize: 12,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 24),

            // Plans from API
            ...plans.map((plan) => _buildPlanCard(context, plan, isDark)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, PlanModel plan, bool isDark) {
    final accent = _planAccent(plan.id, isDark);
    final color = accent.fill;
    final ink = accent.ink;
    final bool isRecommended = plan.id == 'growth';

    return Container(
      margin: const EdgeInsets.only(bottom: LynSpace.lg),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.lg),
        border: Border.all(
          color: isRecommended ? color : (LynSurface.border(isDark)),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (isRecommended)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: LynSpace.md, vertical: LynSpace.xs + 2),
                decoration: BoxDecoration(
                  color: color,
                  // Directional, so the flag stays on the card's end corner in both scripts rather
                  // than sliding over the plan's name in Arabic.
                  borderRadius: const BorderRadiusDirectional.only(
                    topEnd: Radius.circular(14),
                    bottomStart: Radius.circular(LynSpace.md),
                  ),
                ),
                // Was the hardcoded Arabic 'الأكثر شيوعاً' on the English screen too.
                child: Text(
                  AppLocalizations.tr(context, 'Most popular'),
                  style: LynType.micro.copyWith(color: Colors.white),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(LynSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  plan.name,
                  style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                ),
                const SizedBox(height: LynSpace.sm),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedPrice,
                      style: LynType.display.copyWith(color: ink),
                    ),
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
                // const SizedBox(height: 8),
                //
                // // ✅ معلومات التجديد التلقائي لكل خطة
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                //   decoration: BoxDecoration(
                //     color: HexColor('#FEF3C7').withOpacity(0.5),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Icon(
                //         Icons.autorenew,
                //         color: HexColor('#D97706'),
                //         size: 14,
                //       ),
                //       const SizedBox(width: 4),
                //       Text(
                //         'يتجدد تلقائياً شهرياً',
                //         style: TextStyle(
                //           color: HexColor('#92400E'),
                //           fontSize: 11,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 16),

                // Limits
                Row(
                  children: [
                    _buildLimitChip(
                      icon: Icons.people,
                      label: _translateAgents(context, plan.agents),
                      color: color,
                      ink: ink,
                      isDark: isDark,
                    ),
                    const SizedBox(width: LynSpace.sm),
                    _buildLimitChip(
                      icon: Icons.inbox,
                      label: _translateInboxes(context, plan.inboxes),
                      color: color,
                      ink: ink,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: LynSpace.lg),
                Divider(color: LynSurface.border(isDark), height: 1),
                const SizedBox(height: LynSpace.lg),

                // Features
                ...plan.features.map(
                      (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: LynSpace.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_rounded, color: ink, size: 18),
                        ),
                        const SizedBox(width: LynSpace.md),
                        Expanded(
                          child: Text(
                            _translateFeature(context, feature),
                            style: LynType.callout
                                .copyWith(color: LynSurface.textPrimary(isDark)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: LynSpace.lg),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<PaymentCubit>().selectPlan(plan);

                      final paymentCubit = context.read<PaymentCubit>();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: paymentCubit,
                            child: PaymentScreen(plan: plan),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LynSpace.md),
                      ),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.tr(context, 'Subscribe now'),
                      style: LynType.subtitle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color ink,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: LynSpace.md, vertical: LynSpace.xs + 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ink, size: 14),
          const SizedBox(width: LynSpace.xs + 2),
          Text(label, style: LynType.micro.copyWith(color: ink)),
        ],
      ),
    );
  }

  /// A plan's accent, as a PAIR: the hue that identifies the plan, and the tone its words are set in.
  ///
  /// One value cannot do both jobs. The brand indigo measures 5.00:1 on paper and 3.18:1 on the dark
  /// card, so a single colour is readable in one theme and fails in the other — and the price, the
  /// limit chips and the feature ticks were all painted in the fill colour straight. The fill is used
  /// for the card's border, the recommendation flag and the button, where it sits under white; `ink`
  /// is used wherever the accent has to carry text, and measures 7.9 / 6.8 and up on both fields.
  ///
  /// The three hues were a violet and a pink picked outside the palette. These are the product's own
  /// blue, indigo and magenta, which is also the order they read in: trial, standard, top.
  ({Color fill, Color ink}) _planAccent(String planId, bool isDark) {
    switch (planId) {
      case 'startup':
        return (
          fill: LynPalette.blue,
          ink: isDark ? LynPalette.blueOnDark : LynPalette.royal,
        );
      case 'enterprise':
        return (
          fill: LynPalette.magenta,
          ink: isDark ? LynPalette.magentaOnDark : LynPalette.magentaDeep,
        );
      case 'growth':
      default:
        return (
          fill: LynPalette.indigo,
          ink: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep,
        );
    }
  }
}

class SubscriptionManager {
  // ✅ فتح إدارة الاشتراكات في Google Play
  static Future<void> openSubscriptionManagement() async {
    final url = Uri.parse(
        'https://play.google.com/store/account/subscriptions'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ✅ فتح إدارة اشتراك محدد
  static Future<void> openSpecificSubscription(String productId) async {
    final url = Uri.parse(
        'https://play.google.com/store/account/subscriptions?sku=$productId'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
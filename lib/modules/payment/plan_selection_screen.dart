
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hexcolor/hexcolor.dart';
// import 'package:chat/layout/payment/payment_cubit.dart';
// import 'package:chat/layout/payment/payment_states.dart';
// import 'package:chat/shared/network/payment_api_service.dart';
// import 'package:dio/dio.dart';
//
// import '../../layout/cubit/cubit.dart';
// import '../../models/plan_models.dart';
// import '../../shared/app_localizations.dart';
// import 'payment_screen.dart';
//
// class PlanSelectionScreen extends StatelessWidget {
//   const PlanSelectionScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = AppCubit.get(context).isDark;
//
//     return BlocProvider(
//       create: (context) => PaymentCubit(PaymentApiService(Dio()))..loadPlans(),
//       child: Scaffold(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         appBar: AppBar(
//           backgroundColor: LynSurface.canvas(isDark),
//           elevation: 0,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: LynSurface.textPrimary(isDark)),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: Text(
//             'اختر الخطة',
//             style: TextStyle(
//               color: LynSurface.textPrimary(isDark),
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         body: BlocConsumer<PaymentCubit, PaymentState>(
//           listener: (context, state) {
//             if (state is PlansError) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('لا يتوفر اتصال بالانترنت'),
//                   backgroundColor: LynPalette.danger,
//                   behavior: SnackBarBehavior.floating,
//                 ),
//               );
//             }
//           },
//           builder: (context, state) {
//             if (state is PlansLoading || state is PaymentInitial) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             if (state is PlansError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: 64, color: LynPalette.danger),
//                     const SizedBox(height: 16),
//                     Text(
//                       'فشل تحميل الخطط',
//                       style: TextStyle(
//                         color: LynSurface.textPrimary(isDark),
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () => context.read<PaymentCubit>().loadPlans(),
//                       child: const Text('إعادة المحاولة'),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             if (state is PlansLoaded) {
//               return _buildPlansList(context, state.plans, isDark);
//             }
//
//             return const Center(child: CircularProgressIndicator());
//           },
//         ),
//       ),
//     );
//   }
//
//   // ─── ترجمة المميزات ديناميكياً ─────────────────
//   String _translateFeature(BuildContext context, String featureKey) {
//     // نحاول الترجمة، وإذا لم نجدها نعرضها كما هي
//     final translated = AppLocalizations.tr(context, 'feature_$featureKey');
//
//     // إذا لم تُترجم (تساوي نفس المفتاح)، نعرض المفتاح منسق
//     if (translated == 'feature_$featureKey') {
//       // ننسق المفتاح: ai_features → Ai Features
//       return _formatFeatureKey(featureKey);
//     }
//
//     return translated;
//   }
//
//   // ─── تنسيق المفتاح إذا لم تُترجم ────────────────
//   String _formatFeatureKey(String key) {
//     return key
//         .split('_')
//         .map((word) => word.isNotEmpty
//         ? '${word[0].toUpperCase()}${word.substring(1)}'
//         : '')
//         .join(' ');
//   }
//
//   // ─── ترجمة الحدود ──────────────────────────────
//   String _translateAgents(BuildContext context, int count) {
//     return AppLocalizations.tr(context, 'limit_agents')
//         .replaceFirst('{count}', count.toString());
//   }
//
//   String _translateInboxes(BuildContext context, int count) {
//     return AppLocalizations.tr(context, 'limit_inboxes')
//         .replaceFirst('{count}', count.toString());
//   }
//
//   Widget _buildPlansList(BuildContext context, List<PlanModel> plans, bool isDark) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Center(
//               child: Column(
//                 children: [
//                   Text(
//                     'خطط الاشتراك',
//                     style: TextStyle(
//                       color: LynSurface.textPrimary(isDark),
//                       fontSize: 28,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'اختر الخطة المناسبة لاحتياجاتك',
//                     style: TextStyle(
//                       color: LynSurface.textSecondary(isDark),
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 40),
//
//             // Plans from API
//             ...plans.map((plan) => _buildPlanCard(context, plan, isDark)),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlanCard(BuildContext context, PlanModel plan, bool isDark) {
//     // تحديد اللون حسب الخطة
//     final Color color = _getPlanColor(plan.id);
//     final bool isRecommended = plan.id == 'growth'; // Growth هي الأكثر شيوعاً
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       decoration: BoxDecoration(
//         color: LynSurface.surface(isDark),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isRecommended ? color : (LynSurface.border(isDark)),
//           width: isRecommended ? 2 : 1,
//         ),
//         boxShadow: isDark ? null : [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           if (isRecommended)
//             Positioned(
//               top: 0,
//               right: 0,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: const BorderRadius.only(
//                     topRight: Radius.circular(18),
//                     bottomLeft: Radius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'الأكثر شيوعاً',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title
//                 Text(
//                   plan.name,
//                   style: TextStyle(
//                     color: LynSurface.textPrimary(isDark),
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//
//                 // Price
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       plan.formattedPrice,
//                       style: TextStyle(
//                         color: color,
//                         fontSize: 36,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 6),
//                       child: Text(
//                         '/شهر',
//                         style: TextStyle(
//                           color: LynSurface.textSecondary(isDark),
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Limits
//                 Row(
//                   children: [
//                     _buildLimitChip(
//                       icon: Icons.people,
//                       label: _translateAgents(context, plan.agents),  // ← ترجمة ديناميكية
//                       color: color,
//                       isDark: isDark,
//                     ),
//                     const SizedBox(width: 12),
//                     _buildLimitChip(
//                       icon: Icons.inbox,
//                       label: _translateInboxes(context, plan.inboxes),  // ← ترجمة ديناميكية
//                       color: color,
//                       isDark: isDark,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Divider
//                 Divider(
//                   color: LynSurface.border(isDark),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Features
//                 ...plan.features.map(
//                       (feature) => Padding(
//                     padding: const EdgeInsets.only(bottom: 12),
//                     child: Row(
//                       children: [
//                         Icon(Icons.check_circle, color: color, size: 20),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             _translateFeature(context, feature),  // ← ترجمة ديناميكية!
//                             style: TextStyle(
//                               color: LynSurface.textPrimary(isDark),
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//
//                 // Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       // حفظ الخطة المختارة
//                       context.read<PaymentCubit>().selectPlan(plan);
//
//                       // الانتقال لشاشة الدفع
//                       // ✅ الصحيح - تمرير الـ Cubit
//                       final paymentCubit = context.read<PaymentCubit>();
//
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => BlocProvider.value(
//                             value: paymentCubit,
//                             child: PaymentScreen(plan: plan),
//                           ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: color,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Text(
//                       'اشترك الآن',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLimitChip({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required bool isDark,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 16),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getPlanColor(String planId) {
//     switch (planId) {
//       case 'startup':
//         return LynPalette.indigo; // بنفسجي
//       case 'growth':
//         return HexColor('#8B5CF6'); // بنفسجي فاتح
//       case 'enterprise':
//         return HexColor('#EC4899'); // وردي
//       default:
//         return LynPalette.indigo;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
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
          backgroundColor: LynSurface.canvas(isDark),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: LynSurface.textPrimary(isDark)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(AppLocalizations.tr(context, 'Choose the plan'),
            style: TextStyle(
              color: LynSurface.textPrimary(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
                  content: Text('لا يتوفر اتصال بالانترنت'),
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
                    Icon(Icons.error_outline, size: 64, color: LynPalette.danger),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.tr(context, 'Failed to load plans.'),
                      style: TextStyle(
                        color: LynSurface.textPrimary(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.read<PaymentCubit>().loadPlans(),
                      child: const Text('إعادة المحاولة'),
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

  // ✅ فتح إدارة الاشتراكات
  Future<void> _openSubscriptionManagement() async {
    final url = Uri.parse(
        'https://play.google.com/store/account/subscriptions'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(AppLocalizations.tr(context, 'Subscription Plans'),
                    style: TextStyle(
                      color: LynSurface.textPrimary(isDark),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.tr(context, 'Choose the plan that suits your needs.'),
                    style: TextStyle(
                      color: LynSurface.textSecondary(isDark),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
    final Color color = _getPlanColor(plan.id);
    final bool isRecommended = plan.id == 'growth';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecommended ? color : (LynSurface.border(isDark)),
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'الأكثر شيوعاً',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  plan.name,
                  style: TextStyle(
                    color: LynSurface.textPrimary(isDark),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedPrice,
                      style: TextStyle(
                        color: color,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/شهر',
                        style: TextStyle(
                          color: LynSurface.textSecondary(isDark),
                          fontSize: 16,
                        ),
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
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildLimitChip(
                      icon: Icons.inbox,
                      label: _translateInboxes(context, plan.inboxes),
                      color: color,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Divider
                Divider(
                  color: LynSurface.border(isDark),
                ),
                const SizedBox(height: 16),

                // Features
                ...plan.features.map(
                      (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _translateFeature(context, feature),
                            style: TextStyle(
                              color: LynSurface.textPrimary(isDark),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:  Text(AppLocalizations.tr(context, 'Subscribe now'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(String planId) {
    switch (planId) {
      case 'startup':
        return LynPalette.indigo;
      case 'growth':
        return HexColor('#8B5CF6');
      case 'enterprise':
        return HexColor('#EC4899');
      default:
        return LynPalette.indigo;
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
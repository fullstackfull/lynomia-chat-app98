

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hexcolor/hexcolor.dart';
// import 'package:chat/layout/payment/payment_cubit.dart';
// import 'package:chat/layout/payment/payment_states.dart';
// import 'package:chat/shared/app_localizations.dart';
//
// import '../../layout/cubit/cubit.dart';
// import '../../models/plan_models.dart';
//
// class PaymentScreen extends StatelessWidget {
//   final PlanModel plan;
//
//   const PaymentScreen({
//     super.key,
//     required this.plan,
//   });
//
//   // ─── ترجمة المميزات ديناميكياً ─────────────────
//   String _translateFeature(BuildContext context, String featureKey) {
//     final translated = AppLocalizations.tr(context, 'feature_$featureKey');
//
//     // إذا لم تُترجم (تساوي نفس المفتاح)، ننسق المفتاح
//     if (translated == 'feature_$featureKey') {
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
//   @override
//   Widget build(BuildContext context) {
//     final isDark = AppCubit.get(context).isDark;
//     final color = _getPlanColor(plan.id);
//
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: LynSurface.canvas(isDark),
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: LynSurface.textPrimary(isDark)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           AppLocalizations.tr(context, 'Complete Payment'),
//           style: TextStyle(
//             color: LynSurface.textPrimary(isDark),
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: BlocConsumer<PaymentCubit, PaymentState>(
//         listener: (context, state) {
//           if (state is PaymentSuccess) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => PaymentResultScreen(
//                   isSuccess: true,
//                   paymentId: state.paymentId,
//                   planName: state.planName,
//                 ),
//               ),
//             );
//           } else if (state is PaymentError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: LynPalette.danger,
//                 behavior: SnackBarBehavior.floating,
//               ),
//             );
//           } else if (state is PaymentCancelled) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(AppLocalizations.tr(context, 'Payment cancelled')),
//                 backgroundColor: LynPalette.warning,
//                 behavior: SnackBarBehavior.floating,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           return SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Plan Info Card
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       color: LynSurface.surface(isDark),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: color.withOpacity(0.3),
//                         width: 2,
//                       ),
//                       boxShadow: isDark ? null : [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: color.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Icon(
//                                 Icons.workspace_premium,
//                                 color: color,
//                                 size: 32,
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     plan.name,
//                                     style: TextStyle(
//                                       color: LynSurface.textPrimary(isDark),
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     plan.formattedPrice,
//                                     style: TextStyle(
//                                       color: color,
//                                       fontSize: 28,
//                                       fontWeight: FontWeight.w800,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Divider(
//                           color: LynSurface.border(isDark),
//                         ),
//                         const SizedBox(height: 12),
//                         // ✅ الحدود المترجمة ديناميكياً
//                         Row(
//                           children: [
//                             _buildInfoItem(
//                               icon: Icons.people,
//                               text: _translateAgents(context, plan.agents),
//                               color: color,
//                               isDark: isDark,
//                             ),
//                             const SizedBox(width: 20),
//                             _buildInfoItem(
//                               icon: Icons.inbox,
//                               text: _translateInboxes(context, plan.inboxes),
//                               color: color,
//                               isDark: isDark,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   // في بداية Column (بعد Plan Info Card):
//                   const SizedBox(height: 24),
//
// // ─── اختيار طريقة الدفع ──────────────────────
//                   Text(
//                     AppLocalizations.tr(context, 'Payment Method'),
//                     style: TextStyle(
//                       color: LynSurface.textPrimary(isDark),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//
// // Google Play Billing Option
//                   _buildPaymentMethodCard(
//                     context: context,
//                     title: 'Google Play',
//                     subtitle: 'Pay with Google Play Billing',
//                     icon: Icons.play_circle_fill,
//                     color: HexColor('#4285F4'), // Google Blue
//                     isSelected: context.watch<PaymentCubit>().selectedMethod == PaymentMethod.googlePlay,
//                     onTap: () => context.read<PaymentCubit>().selectPaymentMethod(PaymentMethod.googlePlay),
//                     isDark: isDark,
//                   ),
//
//                   const SizedBox(height: 12),
//
// // Stripe Option
//                   _buildPaymentMethodCard(
//                     context: context,
//                     title: 'Credit Card (Stripe)',
//                     subtitle: 'Pay with credit card',
//                     icon: Icons.credit_card,
//                     color: HexColor('#635BFF'), // Stripe Purple
//                     isSelected: context.watch<PaymentCubit>().selectedMethod == PaymentMethod.stripe,
//                     onTap: () => context.read<PaymentCubit>().selectPaymentMethod(PaymentMethod.stripe),
//                     isDark: isDark,
//                   ),
//                   const SizedBox(height: 40),
//
//                   // ✅ المميزات المترجمة ديناميكياً
//                   Text(
//                     AppLocalizations.tr(context, 'Included Features'),
//                     style: TextStyle(
//                       color: LynSurface.textPrimary(isDark),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ...plan.features.map(
//                         (feature) => Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.check_circle,
//                             color: LynPalette.success,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 12),
//                           Text(
//                             _translateFeature(context, feature),
//                             style: TextStyle(
//                               color: LynSurface.textPrimary(isDark),
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//
//                   // Payment Info
//                   _buildSecurityInfo(context, isDark),
//                   const SizedBox(height: 40),
//
//                   // Pay Button
//                   if (state is PaymentLoading)
//                     Center(
//                       child: Column(
//                         children: [
//                           CircularProgressIndicator(
//                             color: color,
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             AppLocalizations.tr(context, 'Processing payment...'),
//                             style: TextStyle(
//                               color: LynSurface.textSecondary(isDark),
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   else
//                     SizedBox(
//                       width: double.infinity,
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           context.read<PaymentCubit>().completePayment(
//                             plan: plan.id,
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: color,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(
//                               Icons.payment,
//                               color: Colors.white,
//                               size: 24,
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               context.read<PaymentCubit>().selectedMethod == PaymentMethod.googlePlay
//                                   ? 'Subscribe via Google Play'
//                                   : 'Pay ${plan.formattedPrice}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 20),
//
//                   // Cancel Button
//                   if (state is! PaymentLoading)
//                     Center(
//                       child: TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text(
//                           AppLocalizations.tr(context, 'cancel'),
//                           style: TextStyle(
//                             color: LynSurface.textSecondary(isDark),
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildInfoItem({
//     required IconData icon,
//     required String text,
//     required Color color,
//     required bool isDark,
//   }) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: color, size: 18),
//         const SizedBox(width: 6),
//         Text(
//           text,
//           style: TextStyle(
//             color: LynSurface.textSecondary(isDark),
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }
//   Widget _buildPaymentMethodCard({
//     required BuildContext context,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required bool isSelected,
//     required VoidCallback onTap,
//     required bool isDark,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: LynSurface.surface(isDark),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? color : (LynSurface.border(isDark)),
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(icon, color: color, size: 28),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       color: LynSurface.textPrimary(isDark),
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       color: LynSurface.textSecondary(isDark),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (isSelected)
//               Icon(Icons.check_circle, color: color, size: 24),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSecurityInfo(BuildContext context, bool isDark) {
//     return Column(
//       children: [
//         _buildSecurityItem(
//           context: context,
//           isDark: isDark,
//           icon: Icons.lock,
//           title: AppLocalizations.tr(context, 'Data Encryption'),
//           description: AppLocalizations.tr(context, 'All your information is encrypted and protected'),
//         ),
//         const SizedBox(height: 16),
//         _buildSecurityItem(
//           context: context,
//           isDark: isDark,
//           icon: Icons.security,
//           title: AppLocalizations.tr(context, 'Stripe Protection'),
//           description: 'We use Stripe to process payments securely',
//         ),
//         const SizedBox(height: 16),
//         _buildSecurityItem(
//           context: context,
//           isDark: isDark,
//           icon: Icons.cancel,
//           title: AppLocalizations.tr(context, 'Easy Cancellation'),
//           description: 'You can cancel your subscription at any time',
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSecurityItem({
//     required BuildContext context,
//     required bool isDark,
//     required IconData icon,
//     required String title,
//     required String description,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 48,
//           height: 48,
//           decoration: BoxDecoration(
//             color: LynSurface.surface(isDark),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(
//             icon,
//             color: LynPalette.indigo,
//             size: 24,
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: LynSurface.textPrimary(isDark),
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: TextStyle(
//                   color: LynSurface.textSecondary(isDark),
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Color _getPlanColor(String planId) {
//     switch (planId) {
//       case 'startup':
//         return LynPalette.indigo;
//       case 'growth':
//         return HexColor('#8B5CF6');
//       case 'enterprise':
//         return HexColor('#EC4899');
//       default:
//         return LynPalette.indigo;
//     }
//   }
// }
//
// class PaymentResultScreen extends StatelessWidget {
//   final bool isSuccess;
//   final String paymentId;
//   final String planName;
//
//   const PaymentResultScreen({
//     super.key,
//     required this.isSuccess,
//     required this.paymentId,
//     required this.planName,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = AppCubit.get(context).isDark;
//
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: LynSurface.canvas(isDark),
//         elevation: 0,
//         automaticallyImplyLeading: false,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: isSuccess
//                         ? LynPalette.success.withOpacity(0.2)
//                         : LynPalette.danger.withOpacity(0.2),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     isSuccess ? Icons.check_circle : Icons.error,
//                     color: isSuccess ? LynPalette.success : LynPalette.danger,
//                     size: 64,
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 Text(
//                   isSuccess
//                       ? AppLocalizations.tr(context, 'Payment Successful!')
//                       : AppLocalizations.tr(context, 'Payment Failed'),
//                   style: TextStyle(
//                     color: LynSurface.textPrimary(isDark),
//                     fontSize: 28,
//                     fontWeight: FontWeight.w700,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   isSuccess
//                       ? AppLocalizations.tr(context, 'Your subscription to plan {plan} has been activated successfully')
//                       .replaceFirst('{plan}', planName)
//                       : AppLocalizations.tr(context, 'An error occurred while processing the payment. Please try again.'),
//                   style: TextStyle(
//                     color: LynSurface.textSecondary(isDark),
//                     fontSize: 16,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),
//                 if (widget.isSuccess)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: LynSurface.surface(isDark),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: LynSurface.border(isDark),
//                         width: 1,
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           AppLocalizations.tr(context, 'Transaction ID'),
//                           style: TextStyle(
//                             color: LynSurface.textSecondary(isDark),
//                             fontSize: 12,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           paymentId,
//                           style: TextStyle(
//                             color: LynSurface.textPrimary(isDark),
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 const SizedBox(height: 40),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.popUntil(context, (route) => route.isFirst);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isSuccess
//                           ? LynPalette.success
//                           : LynPalette.indigo,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: Text(
//                       isSuccess
//                           ? AppLocalizations.tr(context, 'Back to Home')
//                           : AppLocalizations.tr(context, 'Try Again'),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:chat/layout/payment/payment_cubit.dart';
import 'package:chat/layout/payment/payment_states.dart';
import 'package:chat/shared/app_localizations.dart';
import 'package:chat/shared/network/local/cache_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../models/plan_models.dart';
import '../../shared/styles/lyn_palette.dart';

class PaymentScreen extends StatelessWidget {
  final PlanModel plan;

  const PaymentScreen({
    super.key,
    required this.plan,
  });

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

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;
    final color = _getPlanColor(plan.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: LynSurface.canvas(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: LynSurface.textPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.tr(context, 'Complete Payment'),
          style: TextStyle(
            color: LynSurface.textPrimary(isDark),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentResultScreen(
                  isSuccess: true,
                  paymentId: state.paymentId,
                  planName: state.planName,
                ),
              ),
            );
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
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
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: LynSurface.surface(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.workspace_premium,
                                color: color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: TextStyle(
                                      color: LynSurface.textPrimary(isDark),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plan.formattedPrice,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: LynSurface.border(isDark),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoItem(
                              icon: Icons.people,
                              text: _translateAgents(context, plan.agents),
                              color: color,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 20),
                            _buildInfoItem(
                              icon: Icons.inbox,
                              text: _translateInboxes(context, plan.inboxes),
                              color: color,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // // ✅ معلومات التجديد التلقائي
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: HexColor('#FEF3C7').withOpacity(0.3),
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(
                  //       color: LynPalette.warning.withOpacity(0.3),
                  //     ),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Icon(
                  //             Icons.autorenew,
                  //             color: HexColor('#D97706'),
                  //             size: 20,
                  //           ),
                  //           const SizedBox(width: 8),
                  //           Text(
                  //             'تجديد تلقائي',
                  //             style: TextStyle(
                  //               color: LynSurface.textPrimary(isDark),
                  //               fontSize: 16,
                  //               fontWeight: FontWeight.w700,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text(
                  //         'هذا الاشتراك يتجدد تلقائياً كل شهر. سيتم خصم ${plan.formattedPrice} من طريقة الدفع المختارة شهرياً.',
                  //         style: TextStyle(
                  //           color: LynSurface.textSecondary(isDark),
                  //           fontSize: 14,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text(
                  //         'يمكنك إلغاء التجديد التلقائي في أي وقت من إعدادات Google Play.',
                  //         style: TextStyle(
                  //           color: HexColor('#D97706'),
                  //           fontSize: 13,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 24),

                  // Payment Method Selection
                  Text(
                    AppLocalizations.tr(context, 'Payment Method:'),
                    style: TextStyle(
                      color: LynSurface.textPrimary(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Google Play Billing Option
                  _buildPaymentMethodCard(
                    context: context,
                    title: 'Google Play',
                    subtitle:AppLocalizations.tr(context, 'Payment via Google Play Billing'),
                    icon: Icons.play_circle_fill,
                    color: HexColor('#4285F4'),
                    isSelected: context.watch<PaymentCubit>().selectedMethod == PaymentMethod.googlePlay,
                    onTap: () => context.read<PaymentCubit>().selectPaymentMethod(PaymentMethod.googlePlay),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // Stripe Option
                  _buildPaymentMethodCard(
                    context: context,
                    title: 'Credit Card (Stripe)',
                    subtitle: AppLocalizations.tr(context, 'Credit card payment'),
                    icon: Icons.credit_card,
                    color: HexColor('#635BFF'),
                    isSelected: context.watch<PaymentCubit>().selectedMethod == PaymentMethod.stripe,
                    onTap: () => context.read<PaymentCubit>().selectPaymentMethod(PaymentMethod.stripe),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 40),

                  // Features
                  Text(
                    AppLocalizations.tr(context, 'Included Features'),
                    style: TextStyle(
                      color: LynSurface.textPrimary(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...plan.features.map(
                        (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: LynPalette.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _translateFeature(context, feature),
                            style: TextStyle(
                              color: LynSurface.textPrimary(isDark),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Payment Info
                  _buildSecurityInfo(context, isDark),
                  const SizedBox(height: 40),

                  // Pay Button
                  if (state is PaymentLoading)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.tr(context, 'Processing payment...'),
                            style: TextStyle(
                              color: LynSurface.textSecondary(isDark),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<PaymentCubit>().completePayment(
                            plan: plan.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.read<PaymentCubit>().selectedMethod == PaymentMethod.googlePlay
                                  ?' ${AppLocalizations.tr(context,'Subscribe via Google Play')}'
                                  : '${AppLocalizations.tr(context, 'Pay ')} ${plan.formattedPrice}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Cancel Button
                  if (state is! PaymentLoading)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.tr(context, 'cancel'),
                          style: TextStyle(
                            color: LynSurface.textSecondary(isDark),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: LynSurface.textSecondary(isDark),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LynSurface.surface(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (LynSurface.border(isDark)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: LynSurface.textPrimary(isDark),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: LynSurface.textSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildSecurityItem(
          context: context,
          isDark: isDark,
          icon: Icons.lock,
          title: AppLocalizations.tr(context, 'Data Encryption'),
          description: AppLocalizations.tr(context, 'All your information is encrypted and protected'),
        ),
        const SizedBox(height: 16),
        _buildSecurityItem(
          context: context,
          isDark: isDark,
          icon: Icons.security,
          title: AppLocalizations.tr(context, 'Stripe Protection'),
          description: AppLocalizations.tr(context, 'We use Stripe to process payments securely'),
        ),
        const SizedBox(height: 16),
    _buildSecurityItem(
          context: context,
          isDark: isDark,
          icon: Icons.cancel,
          title: AppLocalizations.tr(context, 'Easy Cancellation'),
          description: AppLocalizations.tr(context, 'You can cancel your subscription at any time'),
        ),
      ],
    );
  }

  Widget _buildSecurityItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: LynSurface.surface(isDark),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: LynPalette.indigo,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: LynSurface.textPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: LynSurface.textSecondary(isDark),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: LynSurface.canvas(isDark),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.isSuccess
                        ? LynPalette.success.withOpacity(0.2)
                        : LynPalette.danger.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSuccess ? Icons.check_circle : Icons.error,
                    color: widget.isSuccess ? LynPalette.success : LynPalette.danger,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.isSuccess
                      ? AppLocalizations.tr(context, 'Payment Successful!')
                      : AppLocalizations.tr(context, 'Payment Failed'),
                  style: TextStyle(
                    color: LynSurface.textPrimary(isDark),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isSuccess
                      ? AppLocalizations.tr(context, 'Your subscription to plan {plan} has been activated successfully')
                      .replaceFirst('{plan}', widget.planName)
                      : AppLocalizations.tr(context, 'An error occurred while processing the payment. Please try again.'),
                  style: TextStyle(
                    color: LynSurface.textSecondary(isDark),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ✅ معلومات التجديد التلقائي في شاشة النتيجة
                // if (isSuccess)
                //   Container(
                //     width: double.infinity,
                //     padding: const EdgeInsets.all(16),
                //     margin: const EdgeInsets.only(bottom: 16),
                //     decoration: BoxDecoration(
                //       color: HexColor('#FEF3C7').withOpacity(0.3),
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(
                //         color: LynPalette.warning.withOpacity(0.3),
                //       ),
                //     ),
                //     child: Row(
                //       children: [
                //         Icon(
                //           Icons.info_outline,
                //           color: HexColor('#D97706'),
                //           size: 24,
                //         ),
                //         const SizedBox(width: 12),
                //         Expanded(
                //           child: Text(
                //             'سيتم تجديد اشتراكك تلقائياً شهرياً. يمكنك إلغاء التجديد من إعدادات Google Play في أي وقت.',
                //             style: TextStyle(
                //               color: isDark ? HexColor('#E2E8F0') : HexColor('#475569'),
                //               fontSize: 14,
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),

                if (widget.isSuccess)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LynSurface.surface(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: LynSurface.border(isDark),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.tr(context, 'Transaction ID'),
                          style: TextStyle(
                            color: LynSurface.textSecondary(isDark),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.paymentId,
                          style: TextStyle(
                            color: LynSurface.textPrimary(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isSuccess
                          ? LynPalette.success
                          : LynPalette.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isSuccess
                          ? AppLocalizations.tr(context, 'Back to Home')
                          : AppLocalizations.tr(context, 'Try Again'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
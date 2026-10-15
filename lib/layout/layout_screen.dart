// import 'package:chat/layout/cubit/cubit.dart';
//
// import 'package:chat/models/chatwoot_models.dart';
//
// import 'package:chat/modules/inbox_selection/inbox_selection_screen.dart';
//
// import 'package:chat/modules/payment/plan_selection_screen.dart';
// import 'package:chat/modules/payment_history/payment_history_screen.dart';
//
// import 'package:flutter/material.dart';
//
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:url_launcher/url_launcher.dart';
//
//
// import '../modules/language/cubit/cubit.dart';
//
// import '../modules/login/login_screen.dart';
//
// import '../modules/privacy/about_us_screen.dart';
// import '../shared/app_localizations.dart';
//
// import 'cubit/states.dart';
//
//
//
// class LayoutScreen extends StatelessWidget {
//
//   const LayoutScreen({super.key});
//
//
//
//   @override
//
//   Widget build(BuildContext context) {
//
//     final localeCubit = BlocProvider.of<LocaleCubit>(context);
//
//     final appLocalizations = AppLocalizations.of(context);
//
//
//
//
//
//
//
//     return BlocConsumer<AppCubit, AppStates>(
//
//       listener: (context,state){},
//
//       builder: (context,state){
//         final isDark = AppCubit.get(context).isDark;
//
//         return Scaffold(
//
//           appBar: AppBar(
//
//             elevation: 0,
//
//             backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//
//             iconTheme: IconThemeData(
//
//               color: isDark ? Colors.white : const Color(0xFF334155),
//
//             ),
//
//             title: Text(
//
//               AppLocalizations.tr(context, 'Lynomia Chat'),
//
//               style: const TextStyle(
//
//                 fontWeight: FontWeight.w600,
//
//                 fontSize: 18,
//
//               ),
//
//             ),
//
//             centerTitle: true,
//
//           ),
//
//           drawer: _buildDrawer(context, isDark),
//
//           body: Column(
//
//             crossAxisAlignment: CrossAxisAlignment.center,
//
//             mainAxisAlignment: MainAxisAlignment.center,
//
//             children:  [
//
//               Text(
//
//                 '🖖',
//
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
//
//               ),
//
//               SizedBox(height: 16),
//
//               Center(
//
//                  child: Text(
//
//                   AppLocalizations.tr(context, 'welcome'),
//
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
//
//           ),
//
//               ),
//
//             ],
//
//           ),
//
//         );
//
//       },
//
//     );
//
//   }
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
//   // Drawer - الدرج الجانبي الاحترافي
//
//   // ═══════════════════════════════════════════════════════════════
//
//   Widget _buildDrawer(BuildContext context, bool isDark) {
//
//     final cubit = AppCubit.get(context);
//
//     final localeCubit = context.read<LocaleCubit>();
//
//     final isSubscribed = cubit.isSubscribed;
//
//     final subscription = cubit.currentSubscription;
//
//
//
//     return Drawer(
//
//       backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
//
//       child: SafeArea(
//
//         child: Column(
//
//           children: [
//             // ═══════════════════════════════════════════════════════
//             // Header - صورة المستخدم والمعلومات + حالة الاشتراك
//             // ═══════════════════════════════════════════════════════
//             Stack(
//               children: [
//                 _buildDrawerHeader(isDark, context, isSubscribed: isSubscribed, subscription: subscription),
//                 Positioned(
//                   top: 12,
//                   left: localeCubit.isArabic ? 12 : null,
//                   right: localeCubit.isArabic ? null : 12,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey,
//                       shape: BoxShape.circle,
//                     ),
//                     child: IconButton(
//                       icon: AnimatedSwitcher(
//                         duration: const Duration(milliseconds: 300),
//                         transitionBuilder: (child, anim) => RotationTransition(
//                           turns: anim,
//                           child: FadeTransition(opacity: anim, child: child),
//                         ),
//                         child: Icon(
//                           isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
//                           key: ValueKey<bool>(isDark),
//                           color: Colors.black,
//                         ),
//                       ),
//                       onPressed: () {
//                         cubit.changeTheme();
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // ═══════════════════════════════════════════════════════
//             // القائمة الرئيسية - التبويبات
//             // ═══════════════════════════════════════════════════════
//             Expanded(
//               child: ListView(
//
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//
//                 children: [
//
//
//
//
//
//                   _buildMenuItem(
//
//                     icon: Icons.chat_bubble_outline,
//
//                     label: AppLocalizations.tr(context, 'conversations'),
//
//                     isDark: isDark,
//
//                     isEnabled: isSubscribed,  // ✅ تعطيل إذا لا يوجد اشتراك
//
//                     onTap: () {
//
//                       Navigator.push(
//
//                         context,
//
//                         MaterialPageRoute(builder: (_) => const InboxSelectionScreen()),
//
//                       );
//
//                     },
//
//                   ),
//
//
//
//
//
//                   // _buildMenuItem(
//                   //
//                   //   icon: Icons.privacy_tip_outlined,
//                   //
//                   //   label: AppLocalizations.tr(context, 'privacy_policy'),
//                   //
//                   //   isDark: isDark,
//                   //
//                   //   onTap: () {
//                   //
//                   //     Navigator.pop(context);
//                   //
//                   //     // TODO: Navigate to Privacy Policy
//                   //
//                   //   },
//                   //
//                   // ),
//
//
//
//                   // ✅ الاشتراكات - مع فحص الاشتراك
//
//                   _buildMenuItem(
//
//                     icon: Icons.card_membership_outlined,
//
//                     label: AppLocalizations.tr(context, 'subscriptions'),
//
//                     isDark: isDark,
//
//                     isEnabled: true,  // دائماً مفعّل لعرض Dialog
//
//                     trailing: Container(
//
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//
//                       decoration: BoxDecoration(
//
//                         color: isSubscribed
//
//                             ? Colors.green.withOpacity(0.2)
//
//                             : Colors.red.withOpacity(0.2),
//
//                         borderRadius: BorderRadius.circular(8),
//
//                       ),
//
//                       child: Text(
//
//                         isSubscribed ?  AppLocalizations.tr(context, 'active') : AppLocalizations.tr(context, 'inactive') ,
//
//                         style: TextStyle(
//
//                           color: isSubscribed ? Colors.green : Colors.red,
//
//                           fontSize: 12,
//
//                           fontWeight: FontWeight.bold,
//
//                         ),
//
//                       ),
//
//                     ),
//
//                     onTap: () {
//
//                       Navigator.pop(context);
//
//                       // ✅ الانتقال إلى شاشة اختيار الخطط
//
//                       Navigator.push(
//
//                         context,
//
//                         MaterialPageRoute(
//
//                           builder: (_) => const PlanSelectionScreen(),
//
//                         ),
//
//                       );
//
//                     },
//
//                   ),
//
//
//
//                   // ═══════════════════════════════════════════════════════
//
// // سجل الاشتراكات
//
// // ═══════════════════════════════════════════════════════
//
//                   _buildMenuItem(
//
//                     icon: Icons.receipt_long_outlined,
//
//                     label: AppLocalizations.tr(context, 'Payment History'),
//
//                     isDark: isDark,
//
//                     onTap: () {
//
//                       Navigator.pop(context);
//
//                       Navigator.push(
//
//                         context,
//
//                         MaterialPageRoute(
//
//                           builder: (_) => const PaymentHistoryScreen(),
//
//                         ),
//
//                       );
//
//                     },
//
//                   ),
//
//
//
//                   // ═══════════════════════════════════════════════════════
//
// // زر تغيير اللغة
//
// // ═══════════════════════════════════════════════════════
//
//                   _buildMenuItem(
//
//                     icon: Icons.language,
//
//                     label: AppLocalizations.tr(context, 'language'),
//
//                     isDark: isDark,
//
//                     trailing: Container(
//
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//
//                       decoration: BoxDecoration(
//
//                         color: LynPalette.indigo.withOpacity(0.2),
//
//                         borderRadius: BorderRadius.circular(8),
//
//                       ),
//
//                       child: Text(
//
//                         localeCubit.isArabic ? 'العربية' : 'English', // ✅ الآن يعمل
//
//                         style: const TextStyle(
//
//                           color: LynPalette.indigo,
//
//                           fontSize: 12,
//
//                           fontWeight: FontWeight.bold,
//
//                         ),
//
//                       ),
//
//                     ),
//
//                     onTap: () {
//
//                       Navigator.pop(context);
//
//                       _showLanguageDialog(context, isDark);
//
//                     },
//
//                   ),
//
//
//
//                   _buildMenuItem(
//
//                     icon: Icons.help_outline,
//
//                     label: AppLocalizations.tr(context, 'Help'),
//
//                     isDark: isDark,
//
//                     onTap: () {
//
//                       Navigator.pop(context);
//
//                       // TODO: Navigate to Help
//
//                     },
//
//                   ),
//
//                   _buildMenuItem(
//                     icon: Icons.privacy_tip_outlined,
//                     label: AppLocalizations.tr(context, 'privacy_policy'),
//                     isDark: isDark,
//                     onTap: () {
//                       Navigator.pop(context);
//                       Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyHubScreen()));
//                     },
//                   ),
//
//
//                 ],
//
//               ),
//
//             ),
//
//
//
//             // ═══════════════════════════════════════════════════════
//
//             // Footer - تسجيل الخروج
//
//             // ═══════════════════════════════════════════════════════
//
//             _buildDrawerFooter(context, isDark),
//
//           ],
//
//         ),
//
//       ),
//
//     );
//
//   }
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
//   // Header - صورة المستخدم + حالة الاشتراك
//
//   // ═══════════════════════════════════════════════════════════════
//
//   Widget _buildDrawerHeader(bool isDark,BuildContext context,  {required bool isSubscribed, ChatwootSubscription? subscription}) {
//
//     return Container(
//
//       padding: const EdgeInsets.all(24),
//
//       decoration: BoxDecoration(
//
//         // gradient: LinearGradient(
//         //
//         //   begin: Alignment.topLeft,
//         //
//         //   end: Alignment.bottomRight,
//         //
//         //   colors:
//         //   isDark
//         //
//         //       ? [const Color(0xFF312E81), LynPalette.indigo]:
//         //
//         //        [LynPalette.indigo, LynPalette.indigoOnDark],
//         //
//         // ),
//
//       ),
//
//       child: Column(
//
//         children: [
//
//           // ✅ صورة المستخدم
//
//           Image.asset(
//
//             'assets/images/Drawer.png',
//
//             fit: BoxFit.fitWidth,
//
//             errorBuilder: (context, error, stackTrace) {
//
//               return Container(
//
//                 color: Colors.white.withOpacity(0.2),
//
//                 child: const Icon(
//
//                   Icons.person,
//
//                   size: 40,
//
//                   color: Colors.white,
//
//                 ),
//
//               );
//
//             },
//
//           ),
//
//           const SizedBox(height: 16),
//
//
//
//           // ✅ حالة الاشتراك
//
//           Container(
//
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//
//             decoration: BoxDecoration(
//
//               color: isSubscribed
//
//                   ? Colors.green.withOpacity(0.6)
//
//                   : Colors.red.withOpacity(0.3),
//
//               borderRadius: BorderRadius.circular(20),
//
//             ),
//
//             child: Row(
//
//               mainAxisSize: MainAxisSize.min,
//
//               children: [
//
//                 Icon(
//
//                   isSubscribed ? Icons.verified : Icons.warning,
//
//                   size: 16,
//
//                   color: Colors.white,
//
//                 ),
//
//                 const SizedBox(width: 6),
//
//                 Text(
//
//                   isSubscribed
//
//                       ? '${AppLocalizations.tr(context, 'subscriber')} ${subscription?.plan ?? ''}'
//
//                       : AppLocalizations.tr(context, 'not_subscriber'),
//
//                   style: const TextStyle(
//
//                     color: Colors.white,
//
//                     fontSize: 13,
//
//                     fontWeight: FontWeight.bold,
//
//                   ),
//
//                 ),
//
//               ],
//
//             ),
//
//           ),
//
//
//
//           if (isSubscribed && subscription?.endsAt != null) ...[
//
//             const SizedBox(height: 8),
//
//             Text(
//
//               'ينتهي: ${subscription!.endsAt}',
//
//               style: TextStyle(
//
//                 // color: Colors.white.withOpacity(0.8),
//
//                 fontSize: 11,
//
//               ),
//
//             ),
//             SizedBox(height: 10,),
//             Container(height: 2,width: double.infinity,color: Colors.grey,)
//
//           ],
//
//         ],
//
//       ),
//
//     );
//
//   }
//
//
//
//
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
//   // عنصر القائمة
//
//   // ═══════════════════════════════════════════════════════════════
//
//   Widget _buildMenuItem({
//
//     required IconData icon,
//
//     required String label,
//
//     required bool isDark,
//
//     required VoidCallback onTap,
//
//     Widget? trailing,
//
//     bool isEnabled = true,  // ✅ إضافة هذا المعامل
//
//   }) {
//
//     return Padding(
//
//       padding: const EdgeInsets.only(bottom: 4),
//
//       child: Material(
//
//         color: Colors.transparent,
//
//         borderRadius: BorderRadius.circular(12),
//
//         child: InkWell(
//
//           onTap: isEnabled ? onTap : null,  // ✅ تعطيل onTap إذا isEnabled = false
//
//           borderRadius: BorderRadius.circular(12),
//
//           splashColor: isEnabled ? LynPalette.indigo.withOpacity(0.1) : Colors.transparent,
//
//           highlightColor: isEnabled ? LynPalette.indigo.withOpacity(0.05) : Colors.transparent,
//
//           child: Container(
//
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//
//             decoration: BoxDecoration(
//
//               borderRadius: BorderRadius.circular(12),
//
//               color: isEnabled
//
//                   ? Colors.transparent
//
//                   : (isDark
//
//                       ? Colors.white.withOpacity(0.05)  // ✅ لون أفتح للغير مفعّل
//
//                       : Colors.black.withOpacity(0.05)),
//
//             ),
//
//             child: Row(
//
//               children: [
//
//                 Icon(
//
//                   icon,
//
//                   color: isEnabled
//
//                       ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
//
//                       : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),  // ✅ لون أفتح للغير مفعّل
//
//                   size: 22,
//
//                 ),
//
//                 const SizedBox(width: 16),
//
//                 Expanded(
//
//                   child: Text(
//
//                     label,
//
//                     style: TextStyle(
//
//                       color: isEnabled
//
//                           ? (isDark ? Colors.white : const Color(0xFF1E293B))
//
//                           : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),  // ✅ لون أفتح للغير مفعّل
//
//                       fontSize: 16,
//
//                       fontWeight: FontWeight.bold,
//
//                     ),
//
//                   ),
//
//                 ),
//
//                 trailing ??
//
//                     Icon(
//
//                       Icons.arrow_forward_ios,
//
//                       color: isEnabled
//
//                           ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
//
//                           : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
//
//                       size: 14,
//
//                     ),
//
//               ],
//
//             ),
//
//           ),
//
//         ),
//
//       ),
//
//     );
//
//   }
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
//   // Footer - تسجيل الخروج
//
//   // ═══════════════════════════════════════════════════════════════
//
//   Widget _buildDrawerFooter(BuildContext context, bool isDark) {
//
//     return Container(
//
//       padding: const EdgeInsets.all(16),
//
//       decoration: BoxDecoration(
//
//         border: Border(
//
//           top: BorderSide(
//
//             color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
//
//           ),
//
//         ),
//
//       ),
//
//       child: Column(
//         children: [
//           // 🏢 Powered by Lynomia
//           GestureDetector(
//             onTap: () async {
//               final Uri url = Uri.parse('https://lynomia.com');
//               if (await canLaunchUrl(url)) {
//                 await launchUrl(url, mode: LaunchMode.externalApplication);
//               }
//             },
//             child: Row(
//               textDirection: TextDirection.ltr,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Powered by ',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
//                   ),
//                 ),
//                 SizedBox(width: 2,),
//                 Text(
//                   'Lynomia',
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     color: LynPalette.indigo,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Material(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(12),
//             child: InkWell(
//               onTap: () {
//                 Navigator.pop(context);
//                 _showLogoutDialog(context, isDark);
//               },
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: Colors.red.withOpacity(0.2),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.logout,
//                       color: Colors.red,
//                       size: 22,
//                     ),
//                     const SizedBox(width: 16),
//                     Text(
//                       AppLocalizations.tr(context, 'logout_button'),
//                       style: TextStyle(
//                         color: Colors.red,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const Spacer(),
//                     const Icon(
//                       Icons.arrow_forward_ios,
//                       color: Colors.red,
//                       size: 14,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
//   // Dialog تسجيل الخروج
//
//   // ═══════════════════════════════════════════════════════════════
//
//   void _showLogoutDialog(BuildContext context, bool isDark) {
//
//     showDialog(
//
//       context: context,
//
//       builder: (dialogContext) => AlertDialog(
//
//         backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//
//         shape: RoundedRectangleBorder(
//
//           borderRadius: BorderRadius.circular(20),
//
//         ),
//
//         title: Text(
//
//          AppLocalizations.tr(context, 'logout_confirm_title'),
//
//           textAlign: TextAlign.right,
//
//           style: TextStyle(
//
//             color: isDark ? Colors.white : const Color(0xFF1E293B),
//
//             fontWeight: FontWeight.bold,
//
//           ),
//
//         ),
//
//         content: Text(AppLocalizations.tr(context, 'logout_confirm_message'),
//
//           textAlign: TextAlign.right,
//
//           style: TextStyle(
//
//             color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
//
//           ),
//
//         ),
//
//         actions: [
//
//           TextButton(
//
//             onPressed: () => Navigator.of(dialogContext).pop(),
//
//             child: Text(
//
//               AppLocalizations.tr(context, 'cancel'),
//
//               style: TextStyle(
//
//                 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
//
//               ),
//
//             ),
//
//           ),
//
//           ElevatedButton(
//
//             onPressed: () {
//
//               // ✅ تسجيل الخروج + الانتقال لـ Login
//
//               final cubit = context.read<AppCubit>();
//
//               cubit.logout();
//
//
//
//               // إغلاق الـ Dialog
//
//               Navigator.of(dialogContext).pop();
//
//
//
//               // الانتقال لـ Login وحذف كل الـ routes السابقة
//
//               Navigator.of(context).pushAndRemoveUntil(
//
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//
//                     (route) => false,
//
//               );
//
//             },
//
//             style: ElevatedButton.styleFrom(
//
//               backgroundColor: Colors.red,
//
//               foregroundColor: Colors.white,
//
//               shape: RoundedRectangleBorder(
//
//                 borderRadius: BorderRadius.circular(12),
//
//               ),
//
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//
//             ),
//
//             child:  Text( AppLocalizations.tr(context, 'logout_button'),),
//
//           ),
//
//         ],
//
//       ),
//
//     );
//
//   }
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
//   // Dialog الاشتراك - للمستخدم غير المشترك
//
//   // ═══════════════════════════════════════════════════════════════
//
//   void _showSubscriptionDialog(BuildContext context, bool isDark) {
//
//     showDialog(
//
//       context: context,
//
//       builder: (context) => AlertDialog(
//
//         backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//
//         shape: RoundedRectangleBorder(
//
//           borderRadius: BorderRadius.circular(20),
//
//         ),
//
//         title: Row(
//
//           children: [
//
//             Container(
//
//               padding: const EdgeInsets.all(8),
//
//               decoration: BoxDecoration(
//
//                 color: Colors.red.withOpacity(0.1),
//
//                 borderRadius: BorderRadius.circular(12),
//
//               ),
//
//               child: const Icon(
//
//                 Icons.warning_amber_rounded,
//
//                 color: Colors.red,
//
//                 size: 24,
//
//               ),
//
//             ),
//
//             const SizedBox(width: 12),
//
//             Text(
//
//               'غير مشترك',
//
//               textAlign: TextAlign.right,
//
//               style: TextStyle(
//
//                 color: isDark ? Colors.white : const Color(0xFF1E293B),
//
//                 fontWeight: FontWeight.bold,
//
//               ),
//
//             ),
//
//           ],
//
//         ),
//
//         content: Column(
//
//           mainAxisSize: MainAxisSize.min,
//
//           children: [
//
//             Text(
//
//               'أنت غير مشترك في أي خطة مدفوعة حالياً.',
//
//               textAlign: TextAlign.right,
//
//               style: TextStyle(
//
//                 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
//
//                 fontSize: 15,
//
//               ),
//
//             ),
//
//             const SizedBox(height: 12),
//
//             Text(
//
//               AppLocalizations.tr(context, 'subscribe_prompt'),
//
//               textAlign: TextAlign.right,
//
//               style: TextStyle(
//
//                 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
//
//                 fontSize: 14,
//
//               ),
//
//             ),
//
//           ],
//
//         ),
//
//         actions: [
//
//           TextButton(
//
//             onPressed: () => Navigator.pop(context),
//
//             child: Text(
//
//               AppLocalizations.tr(context, 'cancel'),
//
//               style: TextStyle(
//
//                 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
//
//               ),
//
//             ),
//
//           ),
//
//           ElevatedButton(
//
//             onPressed: () {
//
//               Navigator.pop(context);
//
//               // TODO: فتح رابط الاشتراك
//
//               // يمكن استخدام url_launcher لفتح رابط الاشتراك
//
//             },
//
//             style: ElevatedButton.styleFrom(
//
//               backgroundColor: LynPalette.indigo,
//
//               foregroundColor: Colors.white,
//
//               shape: RoundedRectangleBorder(
//
//                 borderRadius: BorderRadius.circular(12),
//
//               ),
//
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//
//             ),
//
//             child: const Row(
//
//               mainAxisSize: MainAxisSize.min,
//
//               children: [
//
//                 Icon(Icons.card_membership, size: 18),
//
//                 SizedBox(width: 8),
//
//                 Text('اشتراك الآن'),
//
//               ],
//
//             ),
//
//           ),
//
//         ],
//
//       ),
//
//     );
//
//   }
//
//
//
//   // ═══════════════════════════════════════════════════════════════
//
// // Dialog تغيير اللغة
//
// // ═══════════════════════════════════════════════════════════════
//
//   void _showLanguageDialog(BuildContext context, bool isDark) {
//
//     final localeCubit = context.read<LocaleCubit>();
//
//
//
//     showDialog(
//
//       context: context,
//
//       builder: (dialogContext) => AlertDialog(
//
//         backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//
//         shape: RoundedRectangleBorder(
//
//           borderRadius: BorderRadius.circular(20),
//
//         ),
//
//         title: Text(
//
//           AppLocalizations.tr(context, 'language'),
//
//           textAlign: TextAlign.center,
//
//           style: TextStyle(
//
//             color: isDark ? Colors.white : const Color(0xFF1E293B),
//
//             fontWeight: FontWeight.bold,
//
//           ),
//
//         ),
//
//         content: Column(
//
//           mainAxisSize: MainAxisSize.min,
//
//           children: [
//
//             // ✅ العربية
//
//             _buildLanguageOption(
//
//               context: context,
//
//               isDark: isDark,
//
//               languageCode: 'ar',
//
//               label: 'العربية',
//
//               flag: '🇸🇦',
//
//               isSelected: localeCubit.isArabic,
//
//               onTap: () {
//
//                 localeCubit.changeLocale('ar');
//
//                 Navigator.pop(dialogContext);
//
//               },
//
//             ),
//
//             const SizedBox(height: 8),
//
//
//
//             // ✅ English
//
//             _buildLanguageOption(
//
//               context: context,
//
//               isDark: isDark,
//
//               languageCode: 'en',
//
//               label: 'English',
//
//               flag: '🇬🇧',
//
//               isSelected: !localeCubit.isArabic,
//
//               onTap: () {
//
//                 localeCubit.changeLocale('en');
//
//                 Navigator.pop(dialogContext);
//
//               },
//
//             ),
//
//           ],
//
//         ),
//
//       ),
//
//     );
//
//   }
//
//
//
// // ═══════════════════════════════════════════════════════════════
//
// // عنصر اختيار اللغة
//
// // ═══════════════════════════════════════════════════════════════
//
//   Widget _buildLanguageOption({
//
//     required BuildContext context,
//
//     required bool isDark,
//
//     required String languageCode,
//
//     required String label,
//
//     required String flag,
//
//     required bool isSelected,
//
//     required VoidCallback onTap,
//
//   }) {
//
//     return Material(
//
//       color: Colors.transparent,
//
//       borderRadius: BorderRadius.circular(12),
//
//       child: InkWell(
//
//         onTap: onTap,
//
//         borderRadius: BorderRadius.circular(12),
//
//         child: Container(
//
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//
//           decoration: BoxDecoration(
//
//             color: isSelected
//
//                 ? LynPalette.indigo.withOpacity(0.1)
//
//                 : Colors.transparent,
//
//             borderRadius: BorderRadius.circular(12),
//
//             border: Border.all(
//
//               color: isSelected
//
//                   ? LynPalette.indigo
//
//                   : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
//
//               width: 1,
//
//             ),
//
//           ),
//
//           child: Row(
//
//             children: [
//
//               Text(
//
//                 flag,
//
//                 style: const TextStyle(fontSize: 24),
//
//               ),
//
//               const SizedBox(width: 16),
//
//               Expanded(
//
//                 child: Text(
//
//                   label,
//
//                   style: TextStyle(
//
//                     color: isDark ? Colors.white : const Color(0xFF1E293B),
//
//                     fontSize: 16,
//
//                     fontWeight: FontWeight.w600,
//
//                   ),
//
//                 ),
//
//               ),
//
//               if (isSelected)
//
//                 const Icon(
//
//                   Icons.check_circle,
//
//                   color: LynPalette.indigo,
//
//                   size: 24,
//
//                 ),
//
//             ],
//
//           ),
//
//         ),
//
//       ),
//
//     );
//
//   }
//
// }


import 'package:chat/layout/cubit/cubit.dart';
import 'package:chat/models/chatwoot_models.dart';
import 'package:chat/modules/inbox_selection/inbox_selection_screen.dart';
import 'package:chat/modules/payment/plan_selection_screen.dart';
import 'package:chat/modules/payment_history/payment_history_screen.dart';
import 'package:chat/modules/api_documentation/api_documentation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../modules/language/cubit/cubit.dart';
import '../modules/login/login_screen.dart';
import '../modules/privacy/about_us_screen.dart';
import '../shared/app_localizations.dart';
import 'cubit/states.dart';
import '../shared/styles/lyn_palette.dart';

class LayoutScreen extends StatelessWidget {
  const LayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCubit = BlocProvider.of<LocaleCubit>(context);
    final appLocalizations = AppLocalizations.of(context);

    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {},
      builder: (context, state) {
        final isDark = AppCubit.get(context).isDark;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
            title: Text(
              AppLocalizations.tr(context, 'Lynomia Chat'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          drawer: _buildDrawer(context, isDark),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🖖',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  AppLocalizations.tr(context, 'welcome'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Drawer - الدرج الجانبي الاحترافي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDrawer(BuildContext context, bool isDark) {
    final cubit = AppCubit.get(context);
    final localeCubit = context.read<LocaleCubit>();
    final isSubscribed = cubit.isSubscribed;
    final subscription = cubit.currentSubscription;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════
            // Header - صورة المستخدم والمعلومات + حالة الاشتراك
            // ═══════════════════════════════════════════════════════
            Stack(
              children: [
                _buildDrawerHeader(isDark, context, isSubscribed: isSubscribed, subscription: subscription),
                Positioned(
                  top: 12,
                  left: localeCubit.isArabic ? 12 : null,
                  right: localeCubit.isArabic ? null : 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          key: ValueKey<bool>(isDark),
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        cubit.changeTheme();
                      },
                    ),
                  ),
                ),
              ],
            ),

            // ═══════════════════════════════════════════════════════
            // القائمة الرئيسية - التبويبات
            // ═══════════════════════════════════════════════════════
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline,
                    label: AppLocalizations.tr(context, 'conversations'),
                    isDark: isDark,
                    isEnabled: isSubscribed,
                    onTap: () {
                      if (isSubscribed) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InboxSelectionScreen()),
                        );
                      } else {
                        _showSubscriptionPromptDialog(context, isDark);
                      }
                    },
                  ),

                  // ✅ الاشتراكات - مع فحص الاشتراك
                  _buildMenuItem(
                    icon: Icons.card_membership_outlined,
                    label: AppLocalizations.tr(context, 'subscriptions'),
                    isDark: isDark,
                    isEnabled: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSubscribed
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSubscribed ? AppLocalizations.tr(context, 'active') : AppLocalizations.tr(context, 'inactive'),
                        style: TextStyle(
                          color: isSubscribed ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlanSelectionScreen(),
                        ),
                      );
                    },
                  ),

                  // ═══════════════════════════════════════════════════════
                  // سجل الاشتراكات
                  // ═══════════════════════════════════════════════════════
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    label: AppLocalizations.tr(context, 'Payment History'),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentHistoryScreen(),
                        ),
                      );
                    },
                  ),

                  // ═══════════════════════════════════════════════════════
                  // زر تغيير اللغة
                  // ═══════════════════════════════════════════════════════
                  _buildMenuItem(
                    icon: Icons.language,
                    label: AppLocalizations.tr(context, 'language'),
                    isDark: isDark,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: LynPalette.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localeCubit.isArabic ? 'العربية' : 'English',
                        style: const TextStyle(
                          color: LynPalette.indigo,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguageDialog(context, isDark);
                    },
                  ),

                  // _buildMenuItem(
                  //   icon: Icons.help_outline,
                  //   label: AppLocalizations.tr(context, 'Help'),
                  //   isDark: isDark,
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //   },
                  // ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: AppLocalizations.tr(context, 'privacy_policy'),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyHubScreen()));
                    },
                  ),
                  
                  // ═══════════════════════════════════════════════════════
                  // API Documentation
                  // ═══════════════════════════════════════════════════════
                  _buildMenuItem(
                    icon: Icons.code,
                    label: AppLocalizations.tr(context, 'api_documentation'),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApiDocumentationScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════════
            // Footer - تسجيل الخروج
            // ═══════════════════════════════════════════════════════
            _buildDrawerFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialog الاشتراك - للمستخدم غير المشترك (محدث ومحترف)
  // ═══════════════════════════════════════════════════════════════
  void _showSubscriptionPromptDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══════════════════════════════════════════════════════
              // Header with gradient icon
              // ═══════════════════════════════════════════════════════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      LynPalette.indigo.withOpacity(0.15),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [LynPalette.indigo, Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: LynPalette.indigo.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_membership_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.tr(context, 'not_subscribed'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ═══════════════════════════════════════════════════════
              // Body with message
              // ═══════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155).withOpacity(0.5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF475569).withOpacity(0.3)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: LynPalette.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: LynPalette.indigo,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.tr(context, 'subscribe_prompt'),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                fontSize: 14,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // Action Buttons
                    // ═══════════════════════════════════════════════════════
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlanSelectionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: Text(
                          AppLocalizations.tr(context, 'subscribe_now'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LynPalette.indigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: LynPalette.indigo.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          AppLocalizations.tr(context, 'cancel'),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Header - صورة المستخدم + حالة الاشتراك
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDrawerHeader(bool isDark, BuildContext context, {required bool isSubscribed, ChatwootSubscription? subscription}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(),
      child: Column(
        children: [
          Image.asset(
            'assets/images/Drawer.png',
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSubscribed
                  ? Colors.green.withOpacity(0.6)
                  : Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSubscribed ? Icons.verified : Icons.warning,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  isSubscribed
                      ? '${AppLocalizations.tr(context, 'subscriber')} ${subscription?.plan ?? ''}'
                      : AppLocalizations.tr(context, 'not_subscriber'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isSubscribed && subscription?.endsAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'ينتهي: ${subscription!.endsAt}',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
            SizedBox(height: 10),
            Container(height: 2, width: double.infinity, color: Colors.grey)
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // عنصر القائمة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
    bool isEnabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: isEnabled ? LynPalette.indigo.withOpacity(0.1) : Colors.transparent,
          highlightColor: isEnabled ? LynPalette.indigo.withOpacity(0.05) : Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isEnabled
                  ? Colors.transparent
                  : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isEnabled
                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isEnabled
                          ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      size: 14,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Footer - تسجيل الخروج
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDrawerFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final Uri url = Uri.parse('https://lynomia.com');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(width: 2),
                Text(
                  'Lynomia',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: LynPalette.indigo,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context, isDark);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.tr(context, 'logout_button'),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialog تسجيل الخروج
  // ═══════════════════════════════════════════════════════════════
  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.tr(context, 'logout_confirm_title'),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.tr(context, 'logout_confirm_message'),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final cubit = context.read<AppCubit>();
              cubit.logout();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(AppLocalizations.tr(context, 'logout_button')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialog الاشتراك - القديم (يمكن حذفه أو الاحتفاظ به)
  // ═══════════════════════════════════════════════════════════════
  void _showSubscriptionDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'غير مشترك',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أنت غير مشترك في أي خطة مدفوعة حالياً.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tr(context, 'subscribe_prompt'),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LynPalette.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_membership, size: 18),
                SizedBox(width: 8),
                Text('اشتراك الآن'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialog تغيير اللغة
  // ═══════════════════════════════════════════════════════════════
  void _showLanguageDialog(BuildContext context, bool isDark) {
    final localeCubit = context.read<LocaleCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.tr(context, 'language'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context: context,
              isDark: isDark,
              languageCode: 'ar',
              label: 'العربية',
              flag: '🇸🇦',
              isSelected: localeCubit.isArabic,
              onTap: () {
                localeCubit.changeLocale('ar');
                Navigator.pop(dialogContext);
              },
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              context: context,
              isDark: isDark,
              languageCode: 'en',
              label: 'English',
              flag: '🇬🇧',
              isSelected: !localeCubit.isArabic,
              onTap: () {
                localeCubit.changeLocale('en');
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // عنصر اختيار اللغة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLanguageOption({
    required BuildContext context,
    required bool isDark,
    required String languageCode,
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? LynPalette.indigo.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? LynPalette.indigo
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: LynPalette.indigo,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
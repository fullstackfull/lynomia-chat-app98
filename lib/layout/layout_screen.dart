import 'package:chat/layout/cubit/cubit.dart';
import 'package:chat/models/chatwoot_models.dart';
import 'package:chat/modules/inbox_selection/inbox_selection_screen.dart';
import 'package:chat/modules/payment/plan_selection_screen.dart';
import 'package:chat/modules/payment_history/payment_history_screen.dart';
import 'package:chat/modules/api_documentation/api_documentation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import '../modules/language/cubit/cubit.dart';
import '../modules/login/login_screen.dart';
import '../modules/privacy/about_us_screen.dart';
import '../shared/app_localizations.dart';
import 'cubit/states.dart';
import 'home_view.dart';
import '../shared/styles/lyn_controls.dart';
import '../shared/styles/lyn_palette.dart';
import '../shared/styles/lyn_type.dart';

class LayoutScreen extends StatelessWidget {
  const LayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {},
      builder: (context, state) {
        final isDark = AppCubit.get(context).isDark;

        final cubit = AppCubit.get(context);

        return Scaffold(
          backgroundColor: LynSurface.canvas(isDark),
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: LynSurface.surface(isDark),
            shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
            iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
            title: Text(
              AppLocalizations.tr(context, 'Lynomia Chat'),
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark)),
            ),
            centerTitle: true,
          ),
          drawer: _buildDrawer(context, isDark),
          body: HomeView(
            isDark: isDark,
            isSubscribed: cubit.isSubscribed,
            subscription: cubit.currentSubscription,
            onOpenConversations: () {
              if (cubit.isSubscribed) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const InboxSelectionScreen()));
              } else {
                _showSubscriptionPromptDialog(context, isDark);
              }
            },
            onOpenPlans: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PlanSelectionScreen())),
            onOpenPaymentHistory: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
            onOpenApiDocumentation: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ApiDocumentationScreen())),
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
      backgroundColor: LynSurface.canvas(isDark),
      child: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════
            // Header - صورة المستخدم والمعلومات + حالة الاشتراك
            // ═══════════════════════════════════════════════════════
            Stack(
              children: [
                _buildDrawerHeader(isDark, context, isSubscribed: isSubscribed, subscription: subscription),
                PositionedDirectional(
                  top: LynSpace.md,
                  end: LynSpace.md,
                  child: Container(
                    decoration: BoxDecoration(
                      color: LynSurface.surfaceRaised(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(color: LynSurface.border(isDark)),
                    ),
                    child: IconButton(
                      tooltip: AppLocalizations.tr(context, isDark ? 'light_mode' : 'dark_mode'),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          key: ValueKey<bool>(isDark),
                          size: 20,
                          color: LynSurface.textPrimary(isDark),
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
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.md),
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
                    trailing: LynStatusPill(isActive: isSubscribed, isDark: isDark),
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
                      padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: LynPalette.indigo.withOpacity(isDark ? 0.22 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        localeCubit.isArabic ? 'العربية' : 'English',
                        style: LynType.micro.copyWith(
                          color: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep,
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
            color: LynSurface.surface(isDark),
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
                      style: LynType.title.copyWith(
                        color: LynSurface.textPrimary(isDark),
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
                              style: LynType.callout.copyWith(
                                color: LynSurface.textSecondary(isDark),
                                height: 1.6,
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
                          style: LynType.subtitle,
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
                          style: LynType.body.copyWith(
                            color: LynSurface.textSecondary(isDark),
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
    final endsAt = subscription?.endsAt;
    final parsed = endsAt == null ? null : DateTime.tryParse(endsAt);
    final ends = parsed != null
        ? intl.DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(parsed.toLocal())
        : endsAt;

    return Container(
      padding: const EdgeInsets.fromLTRB(LynSpace.xl, LynSpace.xl, LynSpace.xl, LynSpace.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/Drawer.png',
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) => Text(
              AppLocalizations.tr(context, 'Lynomia Chat'),
              style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
            ),
          ),
          const SizedBox(height: LynSpace.lg),
          Row(
            children: [
              LynStatusPill(isActive: isSubscribed, isDark: isDark),
              const SizedBox(width: LynSpace.sm),
              Expanded(
                child: Text(
                  isSubscribed
                      ? (subscription?.plan ?? AppLocalizations.tr(context, 'subscriber'))
                      : AppLocalizations.tr(context, 'not_subscriber'),
                  style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isSubscribed && ends != null) ...[
            const SizedBox(height: LynSpace.xs),
            Text(
              // Was a hardcoded Arabic "ينتهي:", which the English app showed as-is.
              '${AppLocalizations.tr(context, 'renews_on')} $ends',
              style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
            ),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LynSpace.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LynSpace.md),
          splashColor: isEnabled ? LynPalette.indigo.withOpacity(0.1) : Colors.transparent,
          highlightColor: isEnabled ? LynPalette.indigo.withOpacity(0.05) : Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.md + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LynSpace.md),
              color: isEnabled ? Colors.transparent : LynSurface.surfaceMuted(isDark),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? (LynSurface.textSecondary(isDark))
                      : (LynSurface.textTertiary(isDark)),
                  size: 20,
                ),
                const SizedBox(width: LynSpace.lg),
                Expanded(
                  child: Text(
                    label,
                    style: LynType.callout.copyWith(
                      color: isEnabled
                          ? (LynSurface.textPrimary(isDark))
                          : (LynSurface.textTertiary(isDark)),
                    ),
                  ),
                ),
                trailing ?? LynChevron(color: LynSurface.borderStrong(isDark), size: 14),
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
                  style: LynType.micro.copyWith(
                    color: LynSurface.textTertiary(isDark),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 2),
                Text(
                  'Lynomia',
                  style: LynType.micro.copyWith(
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
                      style: LynType.body.copyWith(
                        color: Colors.red,
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
        backgroundColor: LynSurface.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.tr(context, 'logout_confirm_title'),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: LynSurface.textPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.tr(context, 'logout_confirm_message'),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: LynSurface.textSecondary(isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: LynSurface.textSecondary(isDark),
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
  // Dialog تغيير اللغة
  // ═══════════════════════════════════════════════════════════════
  void _showLanguageDialog(BuildContext context, bool isDark) {
    final localeCubit = context.read<LocaleCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LynSurface.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.tr(context, 'language'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LynSurface.textPrimary(isDark),
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
                  : (LynSurface.border(isDark)),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: LynType.title.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: LynType.subtitle.copyWith(
                    color: LynSurface.textPrimary(isDark),
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

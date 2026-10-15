import 'package:chat/layout/cubit/cubit.dart';
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
import 'widgets/app_drawer.dart';
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
  /// The drawer's content, decided here; how it looks lives in `widgets/app_drawer.dart`.
  ///
  /// Three groups rather than one flat list of six: the one destination an agent opens forty times a
  /// day was sitting between the payment history and the privacy policy. EVERY item closes the drawer
  /// before it navigates -- "Conversations" did not, so the destination people actually use left the
  /// drawer standing open behind it.
  Widget _buildDrawer(BuildContext context, bool isDark) {
    final cubit = AppCubit.get(context);
    final localeCubit = context.read<LocaleCubit>();
    final isSubscribed = cubit.isSubscribed;
    final subscription = cubit.currentSubscription;

    final parsed = subscription?.endsAt == null ? null : DateTime.tryParse(subscription!.endsAt!);
    final renewsOn = parsed != null
        ? intl.DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(parsed.toLocal())
        : subscription?.endsAt;

    void go(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return AppDrawer(
      isDark: isDark,
      isSubscribed: isSubscribed,
      planLabel: isSubscribed
          ? (subscription?.plan ?? AppLocalizations.tr(context, 'subscriber'))
          : AppLocalizations.tr(context, 'not_subscriber'),
      renewsOn: isSubscribed ? renewsOn : null,
      onToggleTheme: cubit.changeTheme,
      onBrandTap: () async {
        final Uri url = Uri.parse('https://lynomia.com');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      onLogout: () {
        Navigator.pop(context);
        _showLogoutDialog(context, isDark);
      },
      sections: [
        DrawerSection(
          labelKey: 'section_workspace',
          destinations: [
            DrawerDestination(
              icon: Icons.chat_bubble_outline,
              label: AppLocalizations.tr(context, 'conversations'),
              isLocked: !isSubscribed,
              onTap: () {
                Navigator.pop(context);
                if (isSubscribed) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const InboxSelectionScreen()));
                } else {
                  _showSubscriptionPromptDialog(context, isDark);
                }
              },
            ),
          ],
        ),
        DrawerSection(
          labelKey: 'section_account',
          destinations: [
            DrawerDestination(
              icon: Icons.card_membership_outlined,
              label: AppLocalizations.tr(context, 'subscriptions'),
              trailing: LynStatusPill(isActive: isSubscribed, isDark: isDark),
              onTap: () => go(const PlanSelectionScreen()),
            ),
            DrawerDestination(
              icon: Icons.receipt_long_outlined,
              label: AppLocalizations.tr(context, 'Payment history'),
              onTap: () => go(const PaymentHistoryScreen()),
            ),
          ],
        ),
        DrawerSection(
          labelKey: 'section_app',
          destinations: [
            DrawerDestination(
              icon: Icons.language,
              label: AppLocalizations.tr(context, 'language'),
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
            DrawerDestination(
              icon: Icons.privacy_tip_outlined,
              label: AppLocalizations.tr(context, 'privacy_policy'),
              onTap: () => go(const PrivacyHubScreen()),
            ),
            DrawerDestination(
              icon: Icons.code,
              label: AppLocalizations.tr(context, 'api_documentation'),
              onTap: () => go(const ApiDocumentationScreen()),
            ),
          ],
        ),
      ],
    );
  }

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
                      LynPalette.indigoDeep.withOpacity(0.05),
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
                          colors: [LynPalette.indigo, LynPalette.indigoDeep],
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
                        color: LynSurface.surfaceMuted(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LynSurface.border(isDark)),
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
        // Localized text in a dialog that already follows the ambient direction; the physical
        // override only mis-aligned the English copy.
        title: Text(
          AppLocalizations.tr(context, 'logout_confirm_title'),
          style: TextStyle(
            color: LynSurface.textPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.tr(context, 'logout_confirm_message'),
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
              backgroundColor: LynPalette.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LynSpace.md),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: LynSpace.xl, vertical: LynSpace.md),
            ),
            child: Text(AppLocalizations.tr(context, 'logout_button'),
                style: LynType.callout.copyWith(color: Colors.white)),
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

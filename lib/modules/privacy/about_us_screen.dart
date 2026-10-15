import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../language/cubit/cubit.dart';
import '../../shared/app_localizations.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

class PrivacyHubScreen extends StatefulWidget {
  const PrivacyHubScreen({super.key});

  @override
  State<PrivacyHubScreen> createState() => _PrivacyHubScreenState();
}

class _PrivacyHubScreenState extends State<PrivacyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTerms();
    });
  }

  // ✅ NEW: Detect locale changes and reload terms
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context).languageCode;
    if (_lastLocale != null && _lastLocale != currentLocale) {
      print('🌍 Locale changed from $_lastLocale to $currentLocale, reloading...');
      context.read<AppCubit>().clearTermsCache();
      _loadTerms();
    }
    _lastLocale = currentLocale;
  }

  void _loadTerms() {
    final localeCubit = context.read<LocaleCubit>();
    final lang = localeCubit.isArabic ? 'ar' : 'eng';
    print('🔄 Loading terms with lang: $lang');
    context.read<AppCubit>().fetchTerms(lang: lang, forceRefresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = LynSurface.textPrimary(isDark);
    final subTextColor = LynSurface.textSecondary(isDark);
    final cardColor = LynSurface.surface(isDark);

    return BlocBuilder<AppCubit, AppStates>(
      builder: (context, state) {
        Map<String, String>? termsData;
        bool isLoading = false;
        String? error;
        bool isOffline = false; // ✅ NEW

        if (state is AppFetchTermsSuccessState) {
          termsData = state.termsData;
          isOffline = state.isOffline; // ✅ NEW
        } else if (state is AppFetchTermsLoadingState) {
          isLoading = true;
        } else if (state is AppFetchTermsErrorState) {
          error = state.error;
        } else {
          final cubit = context.read<AppCubit>();
          termsData = cubit.cachedTerms;
          if (termsData == null) isLoading = true;
        }

        return Scaffold(
          backgroundColor: LynSurface.canvas(isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: LynSurface.canvas(isDark),
            iconTheme: IconThemeData(
              color: LynSurface.textPrimary(isDark),
            ),
            title: Text(
              AppLocalizations.tr(context, 'legal_info'),
              style: LynType.headline.copyWith(
                color: textColor,
              ),
            ),
            centerTitle: true,
            bottom: isLoading || error != null || termsData == null
                ? null
                : TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: LynPalette.indigo,
              indicatorWeight: 3,
              labelColor: LynPalette.indigo,
              unselectedLabelColor: subTextColor,
              labelStyle: LynType.callout.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: LynType.callout,
              tabs: [
                _buildTab(icon: Icons.privacy_tip_outlined, label: AppLocalizations.tr(context, 'privacy_policy')),
                _buildTab(icon: Icons.gavel_outlined, label: AppLocalizations.tr(context, 'terms_of_service')),
                _buildTab(icon: Icons.info_outline, label: AppLocalizations.tr(context, 'about_us')),
              ],
            ),
            actions: [
              if (!isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadTerms,
                  color: LynPalette.indigo,
                ),
            ],
          ),
          body: _buildBody(isDark, cardColor, textColor, subTextColor, isLoading, error, termsData,isOffline),
        );
      },
    );
  }

  Widget _buildTab({required IconData icon, required String label}) {
    return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)]));
  }

  Widget _buildBody(
      bool isDark,
      Color cardColor,
      Color textColor,
      Color subTextColor,
      bool isLoading,
      String? error,
      Map<String, String>? termsData,
      bool isOffline, // ✅ NEW
      ) {
    if (isLoading) return _buildLoadingState(isDark);
    if (error != null) return _buildErrorState(isDark, subTextColor, error);
    if (termsData == null) return _buildEmptyState(isDark, subTextColor);

    return RefreshIndicator(
      onRefresh: () async {
        final localeCubit = context.read<LocaleCubit>();
        final lang = localeCubit.isArabic ? 'ar' : 'eng';
        await context.read<AppCubit>().fetchTerms(lang: lang, forceRefresh: true);
      },
      color: LynPalette.indigo,
      backgroundColor: cardColor,
      displacement: 40,
      child: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _buildContentTab(
            title: AppLocalizations.tr(context, 'privacy_policy'),
            content: termsData['privacy'] ?? '',
            icon: Icons.privacy_tip_outlined,
            accentColor: LynPalette.success,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
            isOffline: isOffline, // ✅ NEW
          ),
          _buildContentTab(
            title: AppLocalizations.tr(context, 'terms_of_service'),
            content: termsData['terms'] ?? '',
            icon: Icons.gavel_outlined,
            accentColor: LynPalette.indigo,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
            isOffline: isOffline, // ✅ NEW
          ),
          _buildContentTab(
            title: AppLocalizations.tr(context, 'about_us'),
            content: termsData['aboutus'] ?? '',
            icon: Icons.info_outline,
            accentColor: LynPalette.warning,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
            isOffline: isOffline, // ✅ NEW
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    bool isOffline = false, // ✅ NEW
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
          children: [
            // ✅ NEW: Banner Offline
            if (isOffline) _buildOfflineBanner(isDark),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 28, color: accentColor)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: LynType.headline.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 4),
                Container(width: 40, height: 3, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
              ])),
            ]),
            const SizedBox(height: 24),
            _buildRichContent(content, subTextColor, accentColor),
          ]),
        ),
        const SizedBox(height: 24),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        //   decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
        //   child: Row(mainAxisSize: MainAxisSize.min, children: [
        //     Icon(Icons.update_outlined, size: 16, color: accentColor.withOpacity(0.7)),
        //     const SizedBox(width: 8),
        //     Text(AppLocalizations.tr(context, 'last_updated'), style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
        //   ]),
        // ),
        // const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildRichContent(String text, Color textColor, Color accentColor) {
    final sections = text.split('\r\n\r\n');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections.map((section) {
      section = section.trim();
      if (section.isEmpty) return const SizedBox.shrink();
      final colonIndex = section.indexOf(':');
      if (colonIndex > 0 && colonIndex < 50) {
        final title = section.substring(0, colonIndex).trim();
        final body = section.substring(colonIndex + 1).trim();
        return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(title, style: LynType.callout.copyWith(
            color: accentColor,
            fontWeight: FontWeight.bold,
          ))),
          const SizedBox(height: 10),
          Text(body, style: LynType.body.copyWith(
            color: textColor,
            height: 1.8,
          ), textAlign: TextAlign.start),
        ]));
      }
      return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(section, style: LynType.body.copyWith(
        color: textColor,
        height: 1.8,
      ), textAlign: TextAlign.start));
    }).toList());
  }

  Widget _buildLoadingState(bool isDark) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: LynSurface.surface(isDark), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]), child: Column(children: [
      SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, valueColor: const AlwaysStoppedAnimation<Color>(LynPalette.indigo), backgroundColor: LynSurface.border(isDark))),
      const SizedBox(height: 20),
      Text(AppLocalizations.tr(context, 'loading'), style: LynType.subtitle.copyWith(
        color: LynSurface.textSecondary(isDark),
        fontWeight: FontWeight.w500,
      )),
    ])),
  ]));


  Widget _buildEmptyState(bool isDark, Color subTextColor) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.description_outlined, size: 64, color: subTextColor.withOpacity(0.5)),
    const SizedBox(height: 16),
    Text(AppLocalizations.tr(context, 'no_data'), style: LynType.subtitle.copyWith(
      color: subTextColor,
      fontWeight: FontWeight.w400,
    )),
  ]));

  // ✅ NEW: Banner للـ Offline Mode
  Widget _buildOfflineBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF92400E) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? LynPalette.warning : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.tr(context, 'offline_mode'),
              style: LynType.callout.copyWith(
                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Error State مع رسائل ودية
  Widget _buildErrorState(bool isDark, Color subTextColor, String errorKey) {
    // ✅ ترجمة رسالة الخطأ
    final errorMessage = AppLocalizations.tr(context, errorKey);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ أيقونة مناسبة للخطأ
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorKey == 'no_internet_connection'
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline,
                size: 48,
                color: LynSurface.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ عنوان الخطأ
            Text(
              errorMessage,
              style: LynType.headline.copyWith(
                color: LynSurface.textPrimary(isDark),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ✅ وصف إضافي
            Text(
              AppLocalizations.tr(context, 'check_connection'),
              style: LynType.callout.copyWith(
                color: subTextColor,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ✅ زر إعادة المحاولة
            ElevatedButton.icon(
              onPressed: _loadTerms,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.tr(context, 'retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: LynPalette.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


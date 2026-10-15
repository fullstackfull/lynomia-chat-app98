import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/chatwoot_models.dart';
import '../shared/app_localizations.dart';
import '../shared/styles/lyn_controls.dart';
import '../shared/styles/lyn_palette.dart';
import '../shared/styles/lyn_type.dart';

/// The app's first screen after signing in.
///
/// WHAT IT REPLACES. This was the Vulcan-salute emoji over the word "welcome", centred on an empty
/// canvas — the first thing anyone saw after signing in, and it said nothing and did nothing.
///
/// What is here answers the two questions an agent opens the app with: can I work, and where is the
/// work. Nothing else. Every value on it comes from state the cubit already holds — there are no
/// counts, no averages and no activity feed, because no inbox has been chosen yet and the app does not
/// know them, and a number that is not true is worse than no number.
///
/// It takes plain values and callbacks rather than reaching for the cubit, so a golden test can render
/// the real widget instead of a reconstruction of it.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.isDark,
    required this.isSubscribed,
    required this.subscription,
    required this.onOpenConversations,
    required this.onOpenPlans,
    required this.onOpenPaymentHistory,
    required this.onOpenApiDocumentation,
  });

  final bool isDark;
  final bool isSubscribed;
  final ChatwootSubscription? subscription;

  /// Called whether or not there is a subscription: the card is a destination in both states, and the
  /// layout decides whether that means the inbox or the prompt to subscribe.
  final VoidCallback onOpenConversations;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenPaymentHistory;
  final VoidCallback onOpenApiDocumentation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(LynSpace.xl, LynSpace.xl, LynSpace.xl, LynSpace.xxl),
      children: [
        Text(
          AppLocalizations.tr(context, 'welcome'),
          style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
        ),
        const SizedBox(height: LynSpace.sm),
        Text(
          AppLocalizations.tr(context, 'home_subtitle'),
          style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
        ),
        const SizedBox(height: LynSpace.xl),
        _conversationsCard(context),
        const SizedBox(height: LynSpace.lg),
        _planStrip(context),
        const SizedBox(height: LynSpace.xl),
        Divider(height: 1, thickness: 1, color: LynSurface.border(isDark)),
        const SizedBox(height: LynSpace.sm),
        _row(
          context,
          icon: Icons.receipt_long_outlined,
          label: AppLocalizations.tr(context, 'Payment History'),
          onTap: onOpenPaymentHistory,
        ),
        _row(
          context,
          icon: Icons.code,
          label: AppLocalizations.tr(context, 'api_documentation'),
          onTap: onOpenApiDocumentation,
        ),
      ],
    );
  }

  /// The one bold element on the screen, because opening the inbox is the one thing this app is for.
  ///
  /// Without a subscription it keeps its size and loses its colour. Hiding it would be the easy move
  /// and the wrong one: the destination staying visible and legible is what tells someone what they
  /// are being asked to pay for.
  Widget _conversationsCard(BuildContext context) {
    final open = isSubscribed;

    return Material(
      color: open ? LynPalette.indigo : LynSurface.surface(isDark),
      borderRadius: BorderRadius.circular(LynSpace.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(LynSpace.lg),
        onTap: onOpenConversations,
        child: Container(
          padding: const EdgeInsets.all(LynSpace.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LynSpace.lg),
            border: open ? null : Border.all(color: LynSurface.border(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: open
                      ? Colors.white.withOpacity(0.18)
                      : LynPalette.indigo.withOpacity(isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(LynSpace.md),
                ),
                child: Icon(
                  open ? Icons.forum_outlined : Icons.lock_outline_rounded,
                  color: open ? Colors.white : LynPalette.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: LynSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.tr(context, 'conversations'),
                      style: LynType.headline
                          .copyWith(color: open ? Colors.white : LynSurface.textPrimary(isDark)),
                    ),
                    const SizedBox(height: LynSpace.xs),
                    Text(
                      AppLocalizations.tr(
                          context, open ? 'home_conversations_open' : 'home_conversations_locked'),
                      style: LynType.callout.copyWith(
                        color:
                            open ? Colors.white.withOpacity(0.92) : LynSurface.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LynSpace.md),
              LynChevron(color: open ? Colors.white : LynSurface.textSecondary(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  /// The subscription, stated plainly. `endsAt` arrives from the API as a string of unstated shape;
  /// when it parses as a date it is shown as one, and when it does not it is shown as it came rather
  /// than dropped.
  Widget _planStrip(BuildContext context) {
    final endsAt = subscription?.endsAt;
    final parsed = endsAt == null ? null : DateTime.tryParse(endsAt);
    // The locale, not the default. `DateFormat.yMMMd()` with no argument formats in English whatever
    // the app is set to, so the Arabic build showed "Apr 30, 2026" inside an otherwise Arabic screen.
    final ends = parsed != null
        ? intl.DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(parsed.toLocal())
        : endsAt;

    return Container(
      padding: const EdgeInsets.fromLTRB(LynSpace.lg, LynSpace.md, LynSpace.sm, LynSpace.md),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.md),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isSubscribed
                            ? (subscription?.plan ?? AppLocalizations.tr(context, 'subscriber'))
                            : AppLocalizations.tr(context, 'not_subscriber'),
                        style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: LynSpace.sm),
                    LynStatusPill(isActive: isSubscribed, isDark: isDark),
                  ],
                ),
                if (isSubscribed && ends != null) ...[
                  const SizedBox(height: LynSpace.xs),
                  Text(
                    '${AppLocalizations.tr(context, 'renews_on')} $ends',
                    style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onOpenPlans,
            style: TextButton.styleFrom(foregroundColor: LynPalette.indigo),
            child: Text(
              AppLocalizations.tr(context, isSubscribed ? 'manage_plan' : 'see_plans'),
              style: LynType.callout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LynSpace.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LynSpace.md, horizontal: LynSpace.sm),
          child: Row(
            children: [
              Icon(icon, size: 20, color: LynSurface.textSecondary(isDark)),
              const SizedBox(width: LynSpace.lg),
              Expanded(
                child: Text(label,
                    style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark))),
              ),
              LynChevron(color: LynSurface.borderStrong(isDark), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

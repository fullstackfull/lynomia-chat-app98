import 'package:flutter/material.dart';

import '../../shared/app_localizations.dart';
import '../../shared/styles/lyn_controls.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

/// One destination in the drawer.
class DrawerDestination {
  const DrawerDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isLocked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// A status pill, a language badge: whatever this row wants to say about itself.
  final Widget? trailing;

  /// The destination exists but the subscription does not reach it yet. The row stays tappable --
  /// tapping it is how anyone finds out why -- so this draws a padlock rather than greying it into
  /// something that looks broken.
  final bool isLocked;
}

/// A named group of destinations.
class DrawerSection {
  const DrawerSection({required this.labelKey, required this.destinations});

  final String labelKey;
  final List<DrawerDestination> destinations;
}

/// The app's navigation drawer.
///
/// WHY IT IS ITS OWN FILE. It was four private methods on `LayoutScreen` reaching into two Cubits, a
/// Navigator and three dialogs, so the product's main navigation could not be rendered by a test at
/// all. Everything it shows is passed in now, and the screen keeps the decisions: what the sections
/// are, where each destination goes, and what a locked one does when it is tapped.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.isDark,
    required this.isSubscribed,
    required this.planLabel,
    required this.sections,
    required this.onToggleTheme,
    required this.onBrandTap,
    required this.onLogout,
    this.renewsOn,
  });

  final bool isDark;
  final bool isSubscribed;

  /// The plan's name, or the words for "no subscription". Already resolved by the caller.
  final String planLabel;

  /// Already formatted in the reader's own locale, or null when there is nothing to renew.
  final String? renewsOn;

  final List<DrawerSection> sections;
  final VoidCallback onToggleTheme;
  final VoidCallback onBrandTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: LynSurface.canvas(isDark),
      child: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                _Header(
                  isDark: isDark,
                  isSubscribed: isSubscribed,
                  planLabel: planLabel,
                  renewsOn: renewsOn,
                ),
                PositionedDirectional(
                  top: LynSpace.md,
                  end: LynSpace.md,
                  child: _ThemeToggle(isDark: isDark, onTap: onToggleTheme),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    LynSpace.md, LynSpace.md, LynSpace.md, LynSpace.lg),
                children: [
                  for (final section in sections) ...[
                    _SectionLabel(labelKey: section.labelKey, isDark: isDark),
                    for (final destination in section.destinations)
                      DrawerTile(destination: destination, isDark: isDark),
                  ],
                ],
              ),
            ),
            _Footer(isDark: isDark, onBrandTap: onBrandTap, onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.isSubscribed,
    required this.planLabel,
    required this.renewsOn,
  });

  final bool isDark;
  final bool isSubscribed;
  final String planLabel;
  final String? renewsOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(LynSpace.xl, LynSpace.xl, LynSpace.xl, LynSpace.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CAPPED. At `fitWidth` the mark rendered about 300px tall and took nearly half the drawer,
          // which pushed two of the six destinations below the footer -- so the brand was costing the
          // navigation the space it exists to provide. 88 keeps it legible and lets the whole menu fit.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Image.asset(
              'assets/images/Drawer.png',
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                AppLocalizations.tr(context, 'Lynomia Chat'),
                style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
              ),
            ),
          ),
          const SizedBox(height: LynSpace.lg),
          Row(
            children: [
              LynStatusPill(isActive: isSubscribed, isDark: isDark),
              const SizedBox(width: LynSpace.sm),
              Expanded(
                child: Text(
                  planLabel,
                  style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (renewsOn != null) ...[
            const SizedBox(height: LynSpace.xs),
            Text(
              // Was a hardcoded Arabic "ينتهي:", which the English app showed as-is.
              '${AppLocalizations.tr(context, 'renews_on')} $renewsOn',
              style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.tr(context, isDark ? 'light_mode' : 'dark_mode');

    return Container(
      decoration: BoxDecoration(
        color: LynSurface.surfaceRaised(isDark),
        shape: BoxShape.circle,
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: IconButton(
        tooltip: label,
        // An icon that swaps between a sun and a moon says nothing to a screen reader on its own.
        icon: Semantics(
          button: true,
          label: label,
          child: AnimatedSwitcher(
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
        ),
        onPressed: onTap,
      ),
    );
  }
}

/// The quiet line above a group of destinations.
///
/// Sentence case, not the tracked-out capitals this pattern usually gets: these labels sit beside
/// Arabic, which has no case at all, so capitals would mark the English side and leave the Arabic one
/// looking unlabelled.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.labelKey, required this.isDark});

  final String labelKey;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(LynSpace.md, LynSpace.lg, LynSpace.md, LynSpace.sm),
      child: Text(
        AppLocalizations.tr(context, labelKey),
        style: LynType.caption.copyWith(color: LynSurface.textTertiary(isDark)),
      ),
    );
  }
}

/// One row in the drawer.
class DrawerTile extends StatelessWidget {
  const DrawerTile({super.key, required this.destination, required this.isDark});

  final DrawerDestination destination;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final locked = destination.isLocked;
    final ink = locked ? LynSurface.textTertiary(isDark) : LynSurface.textPrimary(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LynSpace.md),
        child: InkWell(
          onTap: destination.onTap,
          borderRadius: BorderRadius.circular(LynSpace.md),
          child: Container(
            // 48 high before padding, like every other control in the app that takes a tap.
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
                horizontal: LynSpace.md, vertical: LynSpace.md + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LynSpace.md),
              color: locked ? LynSurface.surfaceMuted(isDark) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(destination.icon,
                    size: 20,
                    color: locked
                        ? LynSurface.textTertiary(isDark)
                        : LynSurface.textSecondary(isDark)),
                const SizedBox(width: LynSpace.lg),
                Expanded(
                  child: Text(destination.label, style: LynType.callout.copyWith(color: ink)),
                ),
                // A padlock, not a greyed-out chevron. The row still responds -- tapping it is how
                // anyone finds out what the subscription would unlock -- so it must not read as dead.
                if (locked)
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: LynSurface.textTertiary(isDark))
                else
                  destination.trailing ??
                      LynChevron(color: LynSurface.borderStrong(isDark), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.isDark, required this.onBrandTap, required this.onLogout});

  final bool isDark;
  final VoidCallback onBrandTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LynSpace.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: Column(
        children: [
          // This row was written out a third time here, in a third type rank and a third indigo. It is
          // the shared component, which the splash screen and the payment history already use.
          LynPoweredBy(isDark: isDark, onTap: onBrandTap),
          const SizedBox(height: LynSpace.lg),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(LynSpace.md),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(LynSpace.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg),
                decoration: BoxDecoration(
                  // The danger tokens, not `Colors.red` at three different opacities. The text tone is
                  // the one measured against its own tint; raw red on it does not carry.
                  color: LynSurface.dangerSurface(isDark),
                  borderRadius: BorderRadius.circular(LynSpace.md),
                  border: Border.all(color: LynPalette.dangerSoft),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: LynSurface.dangerText(isDark), size: 20),
                    const SizedBox(width: LynSpace.lg),
                    Expanded(
                      child: Text(
                        AppLocalizations.tr(context, 'logout_button'),
                        style: LynType.callout.copyWith(color: LynSurface.dangerText(isDark)),
                      ),
                    ),
                    LynChevron(color: LynSurface.dangerText(isDark), size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

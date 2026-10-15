import 'package:flutter/material.dart';

import 'lyn_palette.dart';
import 'lyn_type.dart';
import '../app_localizations.dart';

/// A chevron that points the way the script runs.
///
/// `Icons.arrow_forward_ios` does not mirror itself, so a row that ends in one shows Arabic readers a
/// "more" arrow pointing back the way they came. This picks the glyph from the ambient direction.
class LynChevron extends StatelessWidget {
  const LynChevron({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.arrow_back_ios_new
            : Icons.arrow_forward_ios,
        size: size,
        color: color,
      );
}

/// Subscription state as a dot AND a word.
///
/// The app previously drew this as a green pill or a red pill with no other difference between them,
/// which is the same pill to the one man in twelve who cannot separate those two hues — and in this
/// product that pill is what says whether the inbox opens at all. The dot keeps the colour, the word
/// carries the meaning, and the text tone is the measured one for its own tint rather than the raw
/// status colour, which fails on it (2.96:1 for success, 3.29:1 for danger).
class LynStatusPill extends StatelessWidget {
  const LynStatusPill({super.key, required this.isActive, required this.isDark});

  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dot = isActive ? LynPalette.success : LynPalette.danger;
    final ink = isActive ? LynSurface.successText(isDark) : LynSurface.dangerText(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? LynSurface.successSurface(isDark) : LynSurface.dangerSurface(isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: LynSpace.xs + 2),
          Text(
            AppLocalizations.tr(context, isActive ? 'active' : 'inactive'),
            style: LynType.micro.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}

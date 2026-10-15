import 'package:flutter/material.dart';

import '../app_localizations.dart';
import 'lyn_palette.dart';

/// A plan's identity: the colour it is known by, and the words its limits and features are set in.
///
/// WHY THIS IS SHARED. The plan selection screen and the payment screen each carried their own copy of
/// this, and the copies disagreed: `startup` was blue on the first screen and indigo on the second, so a
/// plan changed colour between the two steps of one purchase. They also each held their own identical
/// `_translateFeature` / `_formatFeatureKey` / `_translateAgents` / `_translateInboxes`. One source now.
class LynPlan {
  const LynPlan._();

  /// The plan the pricing page recommends. The API does not mark one, so the product does.
  static const String recommendedId = 'growth';

  static bool isRecommended(String planId) => planId == recommendedId;

  /// A plan's accent, as a PAIR: the hue that identifies the plan, and the tone its words are set in.
  ///
  /// One value cannot do both jobs. The brand indigo measures 5.00:1 on paper and 3.18:1 on the dark
  /// card, so a single colour is readable in one theme and fails in the other — and the price, the
  /// limit chips and the feature ticks were all painted in the fill colour straight. `fill` sits under
  /// white, on a border, a flag or a button; `ink` is used wherever the accent has to carry text, and
  /// measures 6.8:1 and up on both fields.
  ///
  /// The three hues were a violet and a pink picked outside the palette. These are the product's own
  /// blue, indigo and magenta, which is also the order they read in: trial, standard, top.
  static ({Color fill, Color ink}) accent(String planId, bool isDark) {
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
      case recommendedId:
      default:
        return (
          fill: LynPalette.indigo,
          ink: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep,
        );
    }
  }

  /// A feature's label. The API sends snake_case keys; the catalogue holds `feature_<key>` for the ones
  /// the product has copy for, and an unknown key is title-cased rather than shown raw.
  static String feature(BuildContext context, String featureKey) {
    final translated = AppLocalizations.tr(context, 'feature_$featureKey');
    if (translated == 'feature_$featureKey') return _sentenceCase(featureKey);
    return translated;
  }

  static String agents(BuildContext context, int count) =>
      AppLocalizations.tr(context, 'limit_agents').replaceFirst('{count}', count.toString());

  static String inboxes(BuildContext context, int count) =>
      AppLocalizations.tr(context, 'limit_inboxes').replaceFirst('{count}', count.toString());

  /// `shared_inbox` -> `Shared inbox`. Sentence case, not Title Case: the catalogue's own feature
  /// names are written that way, and a fallback that shouted would be visibly a fallback.
  static String _sentenceCase(String key) {
    final words = key.split('_').where((w) => w.isNotEmpty).join(' ');
    if (words.isEmpty) return key;
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
}

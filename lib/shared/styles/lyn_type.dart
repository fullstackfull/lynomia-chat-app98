import 'package:flutter/material.dart';

/// The Lynomia type scale.
///
/// WHAT IT REPLACES. The application set type inline at every call site and had drifted to **seventeen**
/// distinct sizes — 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 25, 28, 32, 36, 40 — and **seven** weight
/// spellings for five actual weights, with `FontWeight.bold` (67 uses) and `FontWeight.w700` (10) naming the
/// same thing, and `normal` and `w400` likewise. Sizes one pixel apart cannot express a hierarchy: 13 beside
/// 14 beside 15 reads as noise, not as three ranks.
///
/// This is eight ranks on a ~1.2 modular progression anchored on a 15px body, which is the size the message
/// bubbles already used and the size Arabic sets comfortably at on a phone. Each rank is named for the JOB
/// it does, so a call site asks for a role rather than picking a number, and two screens asking for the same
/// job get the same answer.
///
/// LINE HEIGHT IS PART OF THE RANK, not an afterthought. Every style carries its own `height`, generous at
/// body sizes because half this product's text is Arabic — IBM Plex Sans Arabic's marks need the room, and
/// leading tuned on a Latin cut alone collides them. Display ranks tighten because long lines are rare there.
///
/// Colour is NOT set here. A style is combined with `LynSurface.textPrimary(isDark)` and friends at the call
/// site, so one scale serves both themes.
class LynType {
  const LynType._();

  /// The one big figure on a screen: a price, a plan headline, a count that is the point of the view.
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  /// A screen title.
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// A section head inside a screen.
  static const TextStyle headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// A card title, a list row's name, a dialog's question.
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Running text: a message, a paragraph, an answer.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// The supporting line under a title, and the label inside a button.
  static const TextStyle callout = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Metadata: a timestamp, a channel name, a helper line under a field.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// The smallest rank that is still allowed to carry words: a badge, a counter,
  /// a status pill. Never a sentence.
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}

/// The spacing ladder.
///
/// A 4pt grid, which is what both Material and the Apple HIG lay out on, and what the web side of this
/// product already uses through Tailwind's scale. The app had padding and gap values at 3, 5, 6, 7, 9, 10,
/// 11, 13, 14, 15, 17, 18, 22 and 26 — off-grid numbers that cannot line up with each other because nothing
/// says they should.
class LynSpace {
  const LynSpace._();

  /// 4 — the gap inside a chip, between an icon and its label.
  static const double xs = 4;

  /// 8 — between tightly related things.
  static const double sm = 8;

  /// 12 — the inside of a compact control.
  static const double md = 12;

  /// 16 — the standard screen gutter and card padding.
  static const double lg = 16;

  /// 24 — between groups.
  static const double xl = 24;

  /// 32 — between sections.
  static const double xxl = 32;
}

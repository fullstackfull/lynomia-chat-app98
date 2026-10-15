import 'package:flutter/material.dart';

/// The Lynomia palette, as the web products define it.
///
/// WHY THIS FILE EXISTS. This application had no palette. It had 53 copies of `Color(0xFF6366F1)`, 48 of
/// `Color(0xFF1E293B)`, 38 of `Color(0xFF94A3B8)` and so on down a long tail -- every one of them a raw
/// Tailwind default (indigo-500, slate-800, slate-400 ...) pasted at the call site. So the app's "brand
/// colour" was Tailwind's indigo, not Lynomia's, and nothing could be changed in one place.
///
/// AND THE BRAND COLOUR WAS WRONG, which is worth stating plainly because the redesign notes had it the
/// other way round: `0xFF6366F1` is Tailwind indigo-500. Lynomia's indigo is `0xFF5B5BF0`. They are close
/// enough to look like the same decision and far enough apart to prove nobody made one.
///
/// The values below are the Lynomia ramp exactly as `theme/colors.js` in the web repository defines it,
/// plus the neutral steps the dashboard resolves its `slate` tokens to. Flutter and the web now name the
/// same colours, so a change to the identity is a change in two files rather than in six hundred call sites.
///
/// NOTHING HERE IS APPLIED BY EXISTING. `themes.dart` consumes it; screens are migrated one at a time, and
/// a screen still holding literals is simply a screen not yet reached.
class LynPalette {
  const LynPalette._();

  // ── Brand ────────────────────────────────────────────────────────────────
  /// The deep field the marketing site opens on, and this app's dark background.
  static const Color ink = Color(0xFF0A1733);

  /// One step above `ink`: cards, sheets and the drawer on the dark theme.
  static const Color inkRaised = Color(0xFF14213F);

  /// Body text on paper. The readable mid-tone, not a grey.
  static const Color inkSoft = Color(0xFF2A3A5C);

  /// Structure and depth in the dark: hairlines, dividers, inactive chrome.
  static const Color lineDark = Color(0xFF1C2E55);

  /// The considered blue. Headings and links on paper.
  static const Color royal = Color(0xFF1D3FA8);

  /// The action colour: primary buttons, the sending state, the active tab.
  static const Color indigo = Color(0xFF5B5BF0);

  /// Pressed and hovered states of `indigo`.
  static const Color indigoDeep = Color(0xFF4038C9);

  /// `indigo` lifted for legibility ON a dark field -- iris-8 in the dashboard ramp.
  /// Never use this on paper: it is 2.6:1 there.
  static const Color indigoOnDark = Color(0xFF9B9EF0);

  /// The quiet brand wash: selected rows, the agent's own message bubble.
  static const Color indigoWash = Color(0xFFE6E7FF);

  /// Text on `indigoWash`.
  static const Color indigoInk = Color(0xFF272962);

  /// Electric blue. The focus ring and the live indicator, and nothing else --
  /// on paper it is 3.3:1 and fails as body text.
  static const Color blue = Color(0xFF0090FF);

  /// The single bold note. One per screen.
  static const Color magenta = Color(0xFFD6246E);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const Color paper = Color(0xFFFFFFFF);

  /// The page behind the cards on the light theme.
  static const Color paperSoft = Color(0xFFF8FAFE);

  /// The tinted field: alternating bands, input fills, pressed rows.
  static const Color mist = Color(0xFFF3F5FB);

  /// The hairline between surfaces on paper.
  static const Color line = Color(0xFFE2E7F3);

  // ── Neutral text ─────────────────────────────────────────────────────────
  /// Secondary text on paper. 5.4:1 on white -- passes AA for body copy.
  static const Color muted = Color(0xFF60646C);

  /// Tertiary text and icons on paper. 3.8:1 on white, so it passes AA for
  /// large text and for icons, and must not carry body copy.
  static const Color subtle = Color(0xFF80838D);

  /// Secondary text ON a dark field.
  static const Color onDarkSoft = Color(0xFFC6CAD6);

  /// Primary text ON a dark field.
  static const Color onDark = Color(0xFFF1F3F9);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFCD34D);
  static const Color warningInk = Color(0xFF92400E);
  static const Color success = Color(0xFF16A34A);
}

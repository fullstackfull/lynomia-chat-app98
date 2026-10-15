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

  /// A surface one step above `inkRaised`: menus, pressed rows, raised tiles.
  static const Color inkElevated = Color(0xFF1E2A4D);

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

  /// A line on paper that has to be seen rather than merely felt.
  static const Color lineStrong = Color(0xFFCBD2E4);

  // ── Neutral text ─────────────────────────────────────────────────────────
  /// Secondary text on paper. 5.4:1 on white -- passes AA for body copy.
  static const Color muted = Color(0xFF60646C);

  /// Tertiary text and icons on paper. 3.8:1 on white, so it passes AA for
  /// large text and for icons, and must not carry body copy.
  static const Color subtle = Color(0xFF80838D);

  /// Secondary text ON a dark field.
  static const Color onDarkSoft = Color(0xFFC6CAD6);

  /// The supporting line ON a dark field -- quieter than `onDarkSoft`, still
  /// comfortably readable on `ink`.
  static const Color onDarkMuted = Color(0xFF94A0B8);

  /// Primary text ON a dark field.
  static const Color onDark = Color(0xFFF1F3F9);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFEF4444);

  /// Danger lifted for a dark field, where `danger` itself is too close to it.
  static const Color dangerSoft = Color(0xFFFCA5A5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFCD34D);
  static const Color warningInk = Color(0xFF92400E);
  static const Color success = Color(0xFF16A34A);

  /// Success as TEXT. `success` itself measures 2.96:1 on its own 10% tint over paper and 3.81:1 on the
  /// dark one, so neither can carry a word. These two measure 6.40:1 and 7.21:1 on the same fields.
  static const Color successInk = Color(0xFF166534);
  static const Color successSoft = Color(0xFF4ADE80);
}

/// The theme-aware surfaces, resolved from `LynPalette` for the brightness in play.
///
/// WHY THIS EXISTS, AND WHY IT IS NOT A COLOUR MAP. The screens express every surface as a ternary on a
/// local `isDark` -- `isDark ? HexColor('#0F172A') : HexColor('#F8FAFC')` -- 207 of them in the chat screen
/// alone. The two sides are not the same colour in two shades: they are the SAME ROLE resolved for opposite
/// fields, and the roles repeat. Twelve places ask for "secondary text", nine for "a hairline", six for "a
/// muted fill".
///
/// So the migration is not a find-and-replace of hex values, which would be unsafe in both directions:
/// `#94A3B8` is secondary text on the dark field and TERTIARY text on paper, and `#64748B` is the exact
/// reverse. Mapping either literal to one token silently inverts half its call sites. Naming the ROLE and
/// resolving it per brightness is the only transform that cannot do that, and it deletes the ternary at the
/// call site as well as the literal.
///
/// Every getter is a pure function of `isDark`, so a call site reads `LynSurface.canvas(isDark)` and keeps
/// the variable it already had in scope.
class LynSurface {
  const LynSurface._();

  // ── Fields ───────────────────────────────────────────────────────────────
  /// The scaffold behind everything.
  static Color canvas(bool isDark) => isDark ? LynPalette.ink : LynPalette.paperSoft;

  /// The scaffold on screens that sit a step tinted, such as the message list.
  static Color canvasAlt(bool isDark) => isDark ? LynPalette.ink : LynPalette.mist;

  /// A card, a sheet, an app bar: the surface that sits ON the canvas.
  static Color surface(bool isDark) => isDark ? LynPalette.inkRaised : LynPalette.paper;

  /// A surface one step above `surface`: menus, a raised tile, a pressed row.
  static Color surfaceRaised(bool isDark) => isDark ? LynPalette.inkElevated : LynPalette.mist;

  /// A quiet fill inside a surface: an input, a chip, an inactive segment.
  static Color surfaceMuted(bool isDark) => isDark ? LynPalette.lineDark : LynPalette.mist;

  // ── Lines ────────────────────────────────────────────────────────────────
  /// The ordinary hairline between things.
  static Color border(bool isDark) => isDark ? LynPalette.lineDark : LynPalette.line;

  /// A line that has to be seen: a focused field, a selected tile, a divider
  /// that carries structure rather than decoration.
  static Color borderStrong(bool isDark) => isDark ? LynPalette.inkSoft : LynPalette.lineStrong;

  // ── Type ─────────────────────────────────────────────────────────────────
  /// Headings and body copy.
  static Color textPrimary(bool isDark) => isDark ? LynPalette.onDark : LynPalette.ink;

  /// The supporting line under a title: a timestamp, a channel name, a count.
  static Color textSecondary(bool isDark) => isDark ? LynPalette.onDarkMuted : LynPalette.muted;

  /// The quietest readable text: a placeholder, a disabled label, an icon that
  /// is present but not being offered.
  static Color textTertiary(bool isDark) => isDark ? LynPalette.muted : LynPalette.subtle;

  // ── Status ───────────────────────────────────────────────────────────────
  /// The field behind a destructive or failed state.
  static Color dangerSurface(bool isDark) =>
      isDark ? const Color(0xFF3B1620) : const Color(0xFFFDE8EC);

  /// Text and icons on `dangerSurface`.
  static Color dangerText(bool isDark) =>
      isDark ? const Color(0xFFFFB4C0) : const Color(0xFF8E1B2E);

  /// The field behind a healthy or active state, and the text that sits on it.
  static Color successSurface(bool isDark) =>
      LynPalette.success.withOpacity(isDark ? 0.18 : 0.10);

  static Color successText(bool isDark) =>
      isDark ? LynPalette.successSoft : LynPalette.successInk;
}

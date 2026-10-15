# The Lynomia Chat redesign

One identity across the app, the dashboard and the marketing site: the Lynomia indigo, one type
scale, one spacing ladder, and layouts that mirror properly in Arabic — which is half this product's
traffic, not an afterthought.

This document is the record of what changed in the Flutter app and why. The before and after images
are in `evidence/`.

## The foundation

| | |
|---|---|
| `lib/shared/styles/lyn_palette.dart` | `LynPalette` — the raw values. `LynSurface` — the theme-aware pairs, so a call site asks for `textSecondary(isDark)` rather than picking a hex. |
| `lib/shared/styles/lyn_type.dart` | `LynType` — eight named ranks on a ~1.2 modular scale anchored on a 15px body, each carrying its own line height. `LynSpace` — a 4pt ladder. |
| `lib/shared/styles/lyn_controls.dart` | `LynChevron` (points the way the script runs) and `LynStatusPill` (a dot **and** a word). |
| `lib/shared/styles/lyn_channel.dart` | A channel's name, icon and colour, in one place, keyed off the stripped class name. |

The app had **seventeen** distinct font sizes and **seven** weight spellings for five weights before
this; padding and gaps at 3, 5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 18, 22 and 26. Sizes one pixel apart
cannot express a hierarchy.

## Three things that were not true

The app showed state it did not have.

1. **A green presence dot on every conversation row.** `ChatwootConversation` carries no presence
   field, so nothing could ever turn it off: every agent was told every customer was online, always.
   Replaced with the conversation's own `status`, which is real and was displayed nowhere.
2. **`Channel::Whatsapp` as a channel name.** Two screens switched on `'whatsapp'` against a value
   the API sends as a Rails class name, so no case ever matched. Every inbox in the picker drew the
   grey default icon and showed the raw string.
3. **`apple_sign_in` as a button label.** The key was in neither catalogue, so the Apple button
   rendered its own key, in both languages. A sweep of every `AppLocalizations.tr` call found nine
   more keys referenced in code and present in neither file.

## RTL

The chat screen was built out of physical left and right. In Arabic the agent's own replies stayed
pinned to the same side as in English, a hard `TextAlign.right` set every English message ragged-left
inside a left-aligned bubble, and the back chevron pointed forward. Alignment, padding, the bubble's
tail corner and text alignment are directional now, the chevron follows the script, and
`DateFormat` is given the active locale at all four call sites — the Arabic build was printing
"Apr 30, 2026" in the middle of an Arabic screen.

## Contrast, measured

Every figure below is a computed WCAG ratio against the exact field the text sits on, not a guess.

| | was | now |
|---|---|---|
| Timestamp, dark incoming bubble | 2.68:1 | 6.05:1 |
| Timestamp, outgoing bubble | 2.62:1 | 4.50:1 |
| Composer placeholder, light / dark | 3.47 / 2.25:1 | 5.45 / 5.08:1 |
| Status pill text (success, danger) on its own tint | 2.96 / 3.29:1 | 6.11–9.17:1 |
| Plan price and chips | one colour, 5.00:1 light and 3.18:1 dark | a fill/ink pair, 6.8–7.9:1 both |

The timestamp still recedes — through the type scale, 11px w500 against 15px w400, which an eye in
daylight can resolve, rather than through transparency, which it cannot.

## What was removed

4,100 lines of commented-out code: `layout_screen.dart` opened with 1,459 lines of a copy of itself
(60% of the file), `payment_screen.dart` with 688 (47%), `plan_selection_screen.dart` with 402 (44%).
Plus a superseded subscription dialog whose own comment called it "القديم (يمكن حذفه)", an unused
logout dialog, and ten dead imports. `hexcolor` is now imported by no file in `lib/`.

## Open, for a decision

**The auto-renewal disclosure.** "Renews automatically monthly; cancel in Google Play" exists in this
app only inside commented-out code — no live path shows it. Both stores require that disclosure on an
auto-renewing subscription. The wording is a commercial statement, and the app also bills through
Stripe, so the copy is not a thing to restore blind.

## The evidence

See `evidence/README.md`. Short version: there is no Android emulator and no KVM in the build
environment, so `flutter screenshot` is closed. These are Flutter's own golden files — the real
widgets, laid out by the real engine, at phone size, written to PNG. Where a golden and a device
disagree, the device is right.

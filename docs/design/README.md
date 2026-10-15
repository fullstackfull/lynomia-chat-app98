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
| `lib/shared/styles/lyn_plan.dart` | A plan's accent pair, and the labels for its limits and features. The two payment screens each had their own copy, and they disagreed. |

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

## The purchase

Two screens, and between them the only part of this product that takes money.

**Choosing a plan** was three cards of about 420 pixels each, stacked. A phone shows one. Comparing
plans — the only thing the screen exists for — meant scrolling down, scrolling back, and holding the
first price in your head; and "Subscribe" appeared three times, once per card, so the action moved as
you scrolled. Every plan's name and price now sit on one row, visible together. Tapping one shows its
limits and features below. One button, pinned, naming the plan it will buy.

**Paying** was 1,116 pixels of scroll: a hero card, two payment methods, then the plan's entire
feature list AGAIN — the list just read on the previous screen — then three security panels, and only
then the button. The amount scrolled out of sight long before the thing you pressed to agree to it.
The amount and the button are now pinned together at the bottom. The features are still here and still
complete, folded shut, because on this screen they are reassurance rather than the point.

Measured at 390 wide: 1,519 px of content before on the plan screen and 1,116 on the payment screen,
against a body of 788. Both now fit with nothing to scroll, the eight-feature plan included.

### Four more things that were not true

4. **Nine Arabic sentences shown to English users.** `PaymentCubit` emitted its own failures as
   hardcoded Arabic — "Google Play Billing غير متاح", "فشل التحقق من الشراء في السيرفر", and seven
   more — into a SnackBar that prints `state.message` as it stands. The worst was `'الجديدة'`, the
   fallback plan name, which landed mid-sentence in "Your subscription to plan _____ has been
   activated successfully" whenever the entitlements call had not caught up. The cubit has no
   `BuildContext`, so it emits a catalogue key now and the view translates it; `tr` returns anything
   it does not recognise unchanged, which keeps server-relayed messages working. The missing plan
   name picks the sentence that does not need one.
5. **Google Play offered on iPhones.** The card was unconditional, and paying through it on iOS hit
   `isAvailable == false` and raised an error. It is `Platform.isAndroid` now — as is the new
   "Manage subscription" link, which opens Google Play's own subscription page and was previously a
   `SubscriptionManager` class that nothing called.
6. **A plan that changed colour between the two steps of buying it.** `_planAccent` on one screen and
   `_getPlanColor` on the other: `startup` was blue on the first and indigo on the second.
7. **"Stripe Protection" promised while paying through Google Play.** The security panel claimed it
   whichever processor was selected.

### And one that was not a lie, just broken

Picking a payment method emitted `PaymentMethodChanged` on the cubit the plan screen shares. That
screen's builder had no case for it and fell through to its loading spinner — so pressing back from
the payment screen landed on a spinner that never resolved, because nothing would emit `PlansLoaded`
again. It only rebuilds on plan states now.

**The purchase flow itself is untouched.** `PaymentCubit`'s lifecycle, the Stripe deep-link handler,
the Google Play verification round trip and `completePayment` are the same code; what changed is which
string is emitted and which widget draws it.

## The receipts

`PaymentHistoryCubit` carried the same defect as `PaymentCubit`, eight more times: every failure it
could report was a hardcoded Arabic sentence, printed to the reader as it stood. The screen itself had
three more problems of its own.

- **The date was hand-rolled.** `'${createdAt.day}/${createdAt.month}/${createdAt.year}'` — unpadded,
  ambiguous between day-first and month-first, and set in Latin digits and slashes in the middle of an
  Arabic screen. `DateFormat.yMMMd` with the active locale now, like the four call sites fixed in the
  chat screen.
- **A row with no plan name in the server's note titled itself "Unknown"**, in English, in both
  languages. The model returns an empty name now and the view names it generically.
- **The transaction reference did not fit.** A Stripe intent id is 27 characters and shared a row with
  the payment method, about 150 pixels each, so it wrapped to three lines and left the two columns
  ragged. It has its own full-width line now, left-to-right so the bidi algorithm cannot reorder its
  segments on an Arabic screen, and in tabular figures because it is compared character by character.

Also: `way.toUpperCase()` printed the database value, so the screen said "GOOGLE_PLAY". And the
processor was coloured success-green for Google Play and warning-amber for anything else — which reads
as the state of the payment, on a list where every row is a settled payment and none is a warning.

## A credential that was being written to the log

`_verifyWithBackend` printed `purchase.verificationData.serverVerificationData` — the Google Play
purchase token, the bearer credential the server presents to Google to verify and acknowledge the
purchase — through `print`, which goes to the device log and leaves the device inside any bug report
or crash dump. It logs the token's length now, which is enough to confirm it arrived.

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

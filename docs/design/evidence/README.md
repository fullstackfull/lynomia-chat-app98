# Evidence

## What these images are

Flutter's own golden files. `flutter test test/visual --update-goldens` builds the widgets, lays them
out with the real engine at 390×844 — an iPhone 14 / Pixel 7 — and writes exactly what it painted.
Nothing here is a mockup, a drawing, or a theme preview.

**They are not device screenshots, and this file does not claim they are.** There is no Android or
iOS emulator in this build environment and no KVM to host one, so `flutter screenshot` is closed.
Where a golden and a device disagree, the device is right.

## How close each one is to the running app

| Shot | What is rendered |
|---|---|
| `*-home-*` | **The production widget.** `HomeView` straight out of `lib/layout/`, pumped whole. |
| `*-login-*` | **The production screen.** `LoginScreen` pumped whole, with its real Cubit and an empty SharedPreferences store. |
| `*-conversations-*` | **The production row.** `ConversationItem` straight out of `lib/modules/conversations_list/`. |
| `*-inboxes-*` | The inbox card, rebuilt from the same `LynChannel` and `LynSurface` calls the screen makes. Its own screen cannot be pumped — it fetches on `initState`. |
| `*-composer-*` | **The production widget.** `ChatComposer` straight out of `lib/modules/chat/widgets/`, in all eight of its states. |
| `*-drawer-*` | **The production widget.** `AppDrawer` straight out of `lib/layout/widgets/`, opened through a real `Scaffold`. |
| `typing-indicator-*` | **The production widget.** `TypingIndicator` straight out of `lib/modules/chat/widgets/`, mounted in a `Column` the way the chat screen mounts it. The light, dark and Arabic shots are a single frame out of a running animation, so the three dots sit at three different heights; `-reduced-motion` is the same widget with the system's reduce-motion switch on, which is why it holds still. |
| `feedback-*` | **The production widget.** `LynFeedback` out of `lib/shared/styles/`, raised by a real tap and shot once the bar is in place. `feedback-error-ar` is the sentence that used to be hardcoded Arabic for every reader, now in Arabic because the reader is. |
| `*-chat-*` | The chat screen's app bar and bubbles, rebuilt from the same tokens and the same geometry — the run-aware tail, the directional alignment. `chat_screen.dart` builds these inside private methods on a `State` that needs a Cubit, a socket and a live conversation. Its composer no longer belongs here -- see `*-composer-*` above, which is the real thing. |
| `*-plans-*` | **The production widget.** `PlanPicker` out of `lib/modules/payment/`, pumped whole, under the screen's own app bar. |
| `*-payment-*` | **The production widgets.** `PaymentForm` and `PaymentResultView`, pumped whole. |
| `*-history-*` | **The production widgets.** `PaymentHistoryList`, `PaymentHistoryEmpty` and `PaymentHistoryFailure`, pumped whole. |
| `*-policy-*` | **The production widget.** `PolicyCard`, pumped whole. The policy text in it is invented for the test and is not Lynomia's. |
| `*-api-*` | **The production widgets**, but the PARTS rather than the page: `ApiMethodBadge`, `ApiCodeBlock` and `ApiParameterRow`. The screen around them reads two cubits from above it and carries 730 lines of its own content. |

## One limitation of the harness

No emoji face is registered — the colour one is 4.7MB — so an emoji inside a string paints as a box.
That is the test engine, not the app. Everything else, Arabic included, renders: the harness loads
Roboto and Noto Naskh Arabic from the SDK and appends the Arabic face as a `fontFamilyFallback`.

A golden that paints nothing now **fails** instead of being written. It used to be written and
reported as a pass, which is how four of these were briefly blank rectangles.

Monospace is registered too, under the name Android's own alias uses, in three weights. Without it
the engine has no monospace family at all and paints every identifier in the API reference as a
filled rectangle — and with only its regular cut, it does the same to anything set above w500.

## Privacy

No shot touches a server, and none contains a real customer. The contacts, inbox names, plan and
dates in them are invented for the tests and live in the test files.

## The files

Each screen has a `before-` and an `after-` pair where there was something to compare.

```
before-chat-light.png          after-chat-light.png
before-chat-dark.png           after-chat-dark.png
before-chat-arabic-rtl.png     after-chat-arabic-rtl.png
                               after-home-light.png
                               after-home-dark.png
                               after-home-locked.png        (no subscription)
                               after-home-arabic-rtl.png
                               after-conversations-light.png
                               after-conversations-dark.png
                               after-conversations-arabic-rtl.png
                               after-login-light.png
                               after-login-dark.png
                               after-login-arabic-rtl.png
                               after-inboxes-light.png
                               after-inboxes-arabic-rtl.png
                               after-plans-light.png
                               after-plans-dark.png
                               after-plans-enterprise-light.png      (the top plan selected)
                               after-plans-arabic-rtl.png
                               after-payment-light.png
                               after-payment-dark.png
                               after-payment-arabic-rtl.png
                               after-payment-processing-light.png    (mid-payment)
                               after-payment-result-success-light.png
                               after-payment-result-success-unnamed-light.png
                               after-payment-result-failure-dark.png
                               after-history-light.png
                               after-history-dark.png
                               after-history-arabic-rtl.png
                               after-history-empty-light.png
                               after-history-error-light.png
                               after-policy-light.png
                               after-policy-dark.png
                               after-policy-arabic-rtl.png
                               after-api-light.png
                               after-api-dark.png
                               after-api-arabic-rtl.png
```

Two of these are there to show a specific thing rather than a screen. `after-payment-result-success-unnamed-light.png`
is the success message when the server has not named the plan yet — the case that used to print an Arabic
word into an English sentence. `after-payment-processing-light.png` is the frame mid-payment, where the
button carries the progress and is disabled and the cancel link is gone, so there is nothing to press twice.

**No Google Play card appears in the payment goldens.** The test engine is not Android, and that card is
now `Platform.isAndroid`-only. On a phone running Android it is there, above the card you can see.

The plan and payment screens have no `before-`, because what changed about them does not fit in a
frame. Measured at 390 wide, by laying each one out against an unbounded height and reading the
content's height off the render object:

| | content height, before | scroll left to do, after |
|---|---|---|
| Choosing a plan | 1,519 px | **0** |
| Paying | 1,116 px | **0** |

The body of a 390×844 screen with an app bar on it is 788 px. So the old plan screen was 1.9 screens
of scrolling and the old payment screen 1.4, with the button at the far end of both. Neither of the
new ones scrolls at all — `maxScrollExtent` is 0 for both, and still 0 on the Enterprise plan, which
has eight features rather than six. `git checkout main && flutter test test/visual --update-goldens`
renders the old ones if you want to look.

The home, conversations, login and inbox screens have no `before-`: the home screen did not exist
(its body was an emoji over the word "welcome"), and for the other three the before state is on
`main`, reachable by `git checkout main && flutter test test/visual --update-goldens`.

## Regenerating

The font files are gitignored — they belong to the SDK, not to this product. Fetch them first:

```
$FLUTTER_ROOT/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf        -> test/visual/
$FLUTTER_ROOT/engine/src/flutter/txt/third_party/fonts/NotoNaskhArabic-Regular.ttf -> test/visual/
MaterialIcons-Regular.otf, out of `flutter build web`'s asset bundle              -> test/visual/
```

Then `flutter test test/visual --update-goldens`.

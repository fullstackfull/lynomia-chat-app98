// The typing indicator and the feedback bar, as the real widgets.
//
// UNLIKE `chat_surfaces_test.dart`, nothing here is rebuilt. `TypingIndicator` and `LynFeedback` are
// the widgets the chat screen now mounts, pumped whole, so these are pictures of shipping code rather
// than of the same tokens arranged to match. They still are not device screenshots: there is no
// emulator and no KVM in this environment, so `flutter screenshot` is closed. Where a golden and a
// device disagree, the device is right.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/modules/chat/widgets/typing_indicator.dart';
import 'package:chat/shared/app_localizations.dart';
import 'package:chat/shared/styles/lyn_feedback.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// The indicator on the canvas it sits on in the app, with nothing else to look at.
Widget _indicatorScene({required bool isDark}) => Scaffold(
      backgroundColor: LynSurface.canvasAlt(isDark),
      // A Column with the indicator last, which is how the chat screen mounts it: between the message
      // list and the composer, hard against the bottom of the conversation.
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TypingIndicator(isDark: isDark),
          const SizedBox(height: LynSpace.xxl),
        ],
      ),
    );

/// A button that raises one piece of feedback. The golden taps it and shoots the bar.
Widget _feedbackScene({
  required bool isDark,
  required String messageKey,
  required LynTone tone,
  String? actionKey,
}) =>
    Scaffold(
      backgroundColor: LynSurface.canvasAlt(isDark),
      body: Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => LynFeedback.show(
              context,
              messageKey,
              tone: tone,
              actionKey: actionKey,
              onAction: actionKey == null ? null : () {},
            ),
            child: Text(
              AppLocalizations.tr(context, 'Conversation'),
              style: LynType.caption.copyWith(color: LynSurface.textTertiary(isDark)),
            ),
          ),
        ),
      ),
    );

Future<void> _raise(WidgetTester tester) async {
  await tester.tap(find.byType(TextButton));
  await tester.pump();
  // Far enough into the entrance for the bar to be fully in place, short of its dismissal.
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(loadRealFonts);

  group('typing indicator', () {
    testWidgets('light', (tester) async {
      await shoot(
        tester,
        name: 'typing-indicator-light',
        theme: lightTheme,
        child: _indicatorScene(isDark: false),
        localizations: true,
        // A looping animation never produces a settled frame, so the harness advances a fixed
        // distance and shoots whatever that lands on.
        settle: false,
        present: find.byType(TypingIndicator),
      );
    });

    testWidgets('dark', (tester) async {
      await shoot(
        tester,
        name: 'typing-indicator-dark',
        theme: darkTheme,
        child: _indicatorScene(isDark: true),
        localizations: true,
        settle: false,
        present: find.byType(TypingIndicator),
      );
    });

    testWidgets('arabic, tail on the start edge', (tester) async {
      await shoot(
        tester,
        name: 'typing-indicator-ar',
        theme: lightTheme,
        child: _indicatorScene(isDark: false),
        localizations: true,
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        settle: false,
        present: find.byType(TypingIndicator),
      );
    });

    // The state a reduce-motion user gets: the dots hold still, and the staggered weight is what is
    // left to read the row as a sequence. This one DOES settle, because nothing is animating.
    testWidgets('reduced motion holds still', (tester) async {
      await shoot(
        tester,
        name: 'typing-indicator-reduced-motion',
        theme: lightTheme,
        child: _indicatorScene(isDark: false),
        localizations: true,
        disableAnimations: true,
        present: find.byType(TypingIndicator),
      );
    });
  });

  group('feedback', () {
    testWidgets('error, with a way back', (tester) async {
      await shoot(
        tester,
        name: 'feedback-error-light',
        theme: lightTheme,
        child: _feedbackScene(
          isDark: false,
          messageKey: 'Could not start recording',
          tone: LynTone.error,
          actionKey: 'Retry',
        ),
        localizations: true,
        settle: false,
        after: _raise,
      );
    });

    testWidgets('warning on dark', (tester) async {
      await shoot(
        tester,
        name: 'feedback-warning-dark',
        theme: darkTheme,
        child: _feedbackScene(
          isDark: true,
          messageKey: 'Microphone permission required',
          tone: LynTone.warning,
        ),
        localizations: true,
        settle: false,
        after: _raise,
      );
    });

    testWidgets('success', (tester) async {
      await shoot(
        tester,
        name: 'feedback-success-light',
        theme: lightTheme,
        child: _feedbackScene(isDark: false, messageKey: 'Image saved', tone: LynTone.success),
        localizations: true,
        settle: false,
        after: _raise,
      );
    });

    // The sentence that used to be hardcoded Arabic for everyone, now in Arabic because the reader is.
    testWidgets('arabic error', (tester) async {
      await shoot(
        tester,
        name: 'feedback-error-ar',
        theme: lightTheme,
        child: _feedbackScene(
          isDark: false,
          messageKey: 'Could not save image',
          tone: LynTone.error,
          actionKey: 'Retry',
        ),
        localizations: true,
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        settle: false,
        after: _raise,
      );
    });
  });
}

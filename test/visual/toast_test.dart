// The overlay toast, as the real widget, plus the timer bug it used to have.
//
// `CustomToast` is the app's SECOND transient-feedback mechanism. It stays separate from
// `LynFeedback` because it draws into an `Overlay` and works without a `Scaffold` -- the login
// screen has no `ScaffoldMessenger` above it -- but it now has to LOOK like the same system, which
// is what these goldens pin.
//
// Not device screenshots: there is no emulator and no KVM in this environment, so
// `flutter screenshot` is closed. Where a golden and a device disagree, the device is right.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/shared/components/custom_toast.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// A screen with one button that raises a toast. The golden presses it and shoots the result.
Widget _scene({
  required bool isDark,
  required String message,
  required ToastStates state,
  Duration duration = const Duration(seconds: 3),
}) =>
    Scaffold(
      backgroundColor: LynSurface.canvasAlt(isDark),
      body: Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => CustomToast.show(
              context: context,
              message: message,
              state: state,
              duration: duration,
            ),
            child: Text(
              'raise',
              style: LynType.caption.copyWith(color: LynSurface.textTertiary(isDark)),
            ),
          ),
        ),
      ),
    );

Future<void> Function(WidgetTester) _press() => (WidgetTester tester) async {
      await tester.tap(find.text('raise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    };

void main() {
  setUpAll(loadRealFonts);

  group('the overlay toast', () {
    // One dark field per tone, the tone carried by a coloured icon. It used to be the tone colour
    // at 95% with white text over it: white on `LynPalette.danger` is 3.76:1, under the 4.5:1 body
    // text needs, and the warning tone was worse again.
    for (final (name, state) in <(String, ToastStates)>[
      ('error', ToastStates.error),
      ('warning', ToastStates.warning),
      ('success', ToastStates.success),
      ('info', ToastStates.info),
    ]) {
      testWidgets('$name, light', (tester) async {
        await shoot(
          tester,
          name: 'toast-$name-light',
          theme: lightTheme,
          localizations: true,
          child: _scene(
            isDark: false,
            message: 'Sign-in did not complete. Please check your details and try again.',
            state: state,
          ),
          after: _press(),
        );
        // The toast's timer has to be cancelled before the tree is disposed: the test framework
        // asserts on a pending timer at teardown, and it is right to -- a `Timer` outliving its
        // overlay is exactly the shape of the defect this file exists for.
        CustomToast.hide();
      });
    }

    testWidgets('error, dark', (tester) async {
      await shoot(
        tester,
        name: 'toast-error-dark',
        theme: darkTheme,
        localizations: true,
        child: _scene(
          isDark: true,
          message: 'Sign-in did not complete. Please check your details and try again.',
          state: ToastStates.error,
        ),
        after: _press(),
      );
      CustomToast.hide();
    });

    testWidgets('error, Arabic right to left', (tester) async {
      await shoot(
        tester,
        name: 'toast-error-ar',
        theme: lightTheme,
        direction: TextDirection.rtl,
        localizations: true,
        locale: const Locale('ar'),
        child: _scene(
          isDark: false,
          message: 'لم تكتمل عملية تسجيل الدخول. تأكد من بياناتك وحاول مرة أخرى.',
          state: ToastStates.error,
        ),
        after: _press(),
      );
      CustomToast.hide();
    });
  });

  group('the dismissal timer', () {
    // THE DEFECT. The auto-dismiss used to be a bare `Future.delayed` whose closure read the static
    // `_currentToast` when it FIRED, not the entry it was created for. So the first toast's three
    // seconds removed the SECOND toast.
    //
    // The second toast is given ten seconds here on purpose: within the window these tests pump,
    // nothing but a stale timer from the first toast can take it off screen, so the assertion has
    // exactly one way to fail.
    testWidgets('a later toast is not cut short by an earlier one\'s timer', (tester) async {
      await tester.pumpWidget(await testApp(tester,
          home: _scene(isDark: false, message: 'first', state: ToastStates.info)));
      await tester.tap(find.text('raise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('first'), findsOneWidget);

      // 2.5s into the first toast's three: its timer has 500ms left on the clock.
      await tester.pump(const Duration(milliseconds: 2000));

      await tester.pumpWidget(await testApp(tester,
          home: _scene(
            isDark: false,
            message: 'second',
            state: ToastStates.info,
            duration: const Duration(seconds: 10),
          )));
      await tester.tap(find.text('raise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('second'), findsOneWidget);

      // Well past the moment the first toast's timer would have fired, and nowhere near the
      // second's own ten seconds.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('second'), findsOneWidget,
          reason: "the first toast's timer removed the second one");

      CustomToast.hide();
    });

    testWidgets('dismissing by hand leaves no timer behind', (tester) async {
      await tester.pumpWidget(await testApp(tester,
          home: _scene(isDark: false, message: 'first', state: ToastStates.info)));
      await tester.tap(find.text('raise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('first'), findsNothing);

      await tester.pumpWidget(await testApp(tester,
          home: _scene(
            isDark: false,
            message: 'second',
            state: ToastStates.info,
            duration: const Duration(seconds: 10),
          )));
      await tester.tap(find.text('raise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The hand-dismissed toast had ~2.5s left when it went; this pump covers that moment and
      // stops short of the second toast's own ten seconds.
      await tester.pump(const Duration(milliseconds: 4000));
      expect(find.text('second'), findsOneWidget,
          reason: 'a hand-dismissed toast left its timer running');

      CustomToast.hide();
    });
  });
}

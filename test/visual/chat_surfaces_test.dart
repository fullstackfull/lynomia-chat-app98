// The chat screen's own surfaces, rendered by the real engine.
//
// WHAT THIS IS AND IS NOT. `chat_screen.dart` builds its bubbles, composer and banner inside private
// methods on a `State` that needs a Cubit, a socket and a live conversation, so it cannot be pumped whole in
// a unit test. What this file does instead is rebuild those surfaces from THE SAME tokens the screen now
// uses -- `LynSurface`, `LynPalette`, `LynType`, `LynSpace` -- at the same phone size, through the real
// theme. So it is an honest picture of the type scale, the spacing and the two bubble fields as the screen
// resolves them, and it is NOT a screenshot of the running application. Where a golden and the device
// disagree, the device is right.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// One message, as the screen draws it: an outgoing bubble is the brand indigo with white type, an
/// incoming bubble is the themed surface with themed type.
Widget _bubble(String text, String time, {required bool outgoing, required bool isDark}) {
  final fg = outgoing ? Colors.white : LynSurface.textPrimary(isDark);
  return Align(
    alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: LynSpace.xs, horizontal: LynSpace.lg),
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.sm + 2),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: outgoing ? LynPalette.indigo : LynSurface.surface(isDark),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(outgoing ? 18 : 4),
          bottomRight: Radius.circular(outgoing ? 4 : 18),
        ),
        border: outgoing ? null : Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: LynType.body.copyWith(color: fg)),
          const SizedBox(height: LynSpace.xs),
          Text(
            time,
            style: LynType.caption.copyWith(
              color: outgoing ? Colors.white.withOpacity(0.75) : LynSurface.textSecondary(isDark),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _composer(bool isDark) => Container(
      padding: const EdgeInsets.all(LynSpace.md),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        border: Border(top: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.md),
              decoration: BoxDecoration(
                color: LynSurface.surfaceMuted(isDark),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text('Write a reply…',
                  style: LynType.body.copyWith(color: LynSurface.textTertiary(isDark))),
            ),
          ),
          const SizedBox(width: LynSpace.sm),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: LynPalette.indigo, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );

Widget _screen(bool isDark, {TextDirection direction = TextDirection.ltr}) {
  final ar = direction == TextDirection.rtl;
  return Scaffold(
    backgroundColor: LynSurface.canvasAlt(isDark),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(LynSpace.lg),
            color: LynSurface.surface(isDark),
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: LynPalette.indigo.withOpacity(0.15),
                    child: Text(ar ? 'ن' : 'N',
                        style: LynType.subtitle.copyWith(color: LynPalette.indigo))),
                const SizedBox(width: LynSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ar ? 'نورة الفهد' : 'Noura Alfahad',
                          style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark))),
                      Text(ar ? 'واتساب · متصل' : 'WhatsApp · online',
                          style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: LynSurface.textSecondary(isDark)),
              ],
            ),
          ),
          const SizedBox(height: LynSpace.sm),
          Expanded(
            child: ListView(
              children: [
                _bubble(ar ? 'هل وصل طلبي رقم ٤٨٢١؟' : 'Has my order 4821 shipped yet?',
                    '10:42', outgoing: false, isDark: isDark),
                _bubble(ar ? 'نعم، تم شحنه هذا الصباح.' : 'Yes — it went out this morning.',
                    '10:44', outgoing: true, isDark: isDark),
                _bubble(ar ? 'شكراً جزيلاً لك!' : 'Thank you, much appreciated!',
                    '10:45', outgoing: false, isDark: isDark),
              ],
            ),
          ),
          _composer(isDark),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('chat surfaces, light', (t) async {
    await shoot(t, name: 'chat-light', theme: lightTheme, child: _screen(false));
  });

  testWidgets('chat surfaces, dark', (t) async {
    await shoot(t, name: 'chat-dark', theme: darkTheme, child: _screen(true));
  });

  testWidgets('chat surfaces, Arabic RTL', (t) async {
    await shoot(t,
        name: 'chat-arabic-rtl',
        theme: lightTheme,
        direction: TextDirection.rtl,
        child: _screen(false, direction: TextDirection.rtl));
  });
}

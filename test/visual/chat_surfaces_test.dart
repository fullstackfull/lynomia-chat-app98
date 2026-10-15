// The chat screen's own surfaces, rendered by the real engine.
//
// WHAT THIS IS AND IS NOT. `chat_screen.dart` builds its bubbles, composer and banner inside private
// methods on a `State` that needs a Cubit, a socket and a live conversation, so it cannot be pumped whole
// in a unit test. What this file does instead is rebuild those surfaces from THE SAME tokens and THE SAME
// geometry the screen now uses -- `LynSurface`, `LynPalette`, `LynType`, `LynSpace`, the run-aware tail,
// the directional alignment -- at the same phone size, through the real theme. So it is an honest picture
// of the type scale, the spacing and the bubble fields as the screen resolves them, and it is NOT a
// screenshot of the running application. Where a golden and the device disagree, the device is right.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// One message in a conversation, drawn the way the screen draws it.
///
/// [endsRun] is what the screen calls the last bubble of a consecutive burst from one side: only that one
/// gets the pointed tail, so four quick replies read as one utterance instead of four stacked cards.
Widget _bubble(
  String text,
  String time, {
  required bool outgoing,
  required bool isDark,
  bool startsRun = true,
  bool endsRun = true,
}) {
  const tail = Radius.circular(4);
  const round = Radius.circular(18);

  return Align(
    // Directional, so Arabic mirrors rather than keeping the agent pinned to one physical side.
    alignment: outgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
    child: Container(
      margin: EdgeInsets.only(
        left: LynSpace.lg,
        right: LynSpace.lg,
        top: startsRun ? LynSpace.sm + 2 : 2,
        bottom: endsRun ? 2 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.sm + 2),
      constraints: const BoxConstraints(maxWidth: 282),
      decoration: BoxDecoration(
        color: outgoing ? LynPalette.indigo : LynSurface.surface(isDark),
        borderRadius: BorderRadiusDirectional.only(
          topStart: round,
          topEnd: round,
          bottomStart: outgoing || !endsRun ? round : tail,
          bottomEnd: outgoing && endsRun ? tail : round,
        ),
        border: outgoing ? null : Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        // `end`, not `start` + Align: an Align inside a Column takes the full incoming constraint and
        // would stretch every bubble to the 282 cap. This way the Column is as wide as the message and
        // the narrower time row is pushed to the end edge inside it -- the left, in Arabic.
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: LynType.body.copyWith(color: outgoing ? Colors.white : LynSurface.textPrimary(isDark)),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: LynSpace.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: LynType.micro.copyWith(
                  fontWeight: FontWeight.w500,
                  color: outgoing ? Colors.white.withOpacity(0.92) : LynSurface.textSecondary(isDark),
                ),
              ),
              if (outgoing) ...[
                const SizedBox(width: LynSpace.xs),
                Icon(Icons.done_all, size: 14, color: Colors.white.withOpacity(0.92)),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

/// The date, once, above the day's first message -- which is what lets every bubble below it carry a bare
/// clock time instead of repeating "Mar 12," eighty times.
Widget _daySeparator(String label, bool isDark) => Padding(
      padding: const EdgeInsets.symmetric(vertical: LynSpace.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.xs + 2),
          decoration: BoxDecoration(
            color: LynSurface.surface(isDark),
            border: Border.all(color: LynSurface.border(isDark)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: LynType.micro.copyWith(color: LynSurface.textSecondary(isDark))),
        ),
      ),
    );

Widget _composer(bool isDark, String hint) => Container(
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: LynSpace.sm),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        border: Border(top: BorderSide(color: LynSurface.border(isDark))),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: LynPalette.indigo),
          const SizedBox(width: LynSpace.md),
          Icon(Icons.attach_file, color: LynSurface.textSecondary(isDark)),
          const SizedBox(width: LynSpace.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.md),
              decoration: BoxDecoration(
                color: LynSurface.surfaceMuted(isDark),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: LynSurface.border(isDark)),
              ),
              child: Text(hint, style: LynType.body.copyWith(color: LynSurface.textSecondary(isDark))),
            ),
          ),
          const SizedBox(width: LynSpace.sm),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: LynPalette.indigo, shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: Colors.white, size: 22),
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
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.md, vertical: LynSpace.md),
            decoration: BoxDecoration(
              color: LynSurface.surface(isDark),
              border: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
            ),
            child: Row(
              children: [
                Icon(ar ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                    size: 20, color: LynSurface.textPrimary(isDark)),
                const SizedBox(width: LynSpace.md),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: LynPalette.indigo.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: LynSurface.border(isDark)),
                  ),
                  child: Center(
                    child: Text(ar ? 'ن' : 'N',
                        style: LynType.subtitle
                            .copyWith(color: LynPalette.indigo, fontSize: 38 * 0.42, height: 1)),
                  ),
                ),
                const SizedBox(width: LynSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ar ? 'نورة الفهد' : 'Noura Alfahad',
                          style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark))),
                      Text('WhatsApp',
                          style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: LynSurface.textSecondary(isDark)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: LynSpace.sm),
              children: [
                _daySeparator(ar ? 'أمس' : 'Yesterday', isDark),
                _bubble(ar ? 'هل وصل طلبي رقم ٤٨٢١؟' : 'Has my order 4821 shipped yet?', '10:42',
                    outgoing: false, isDark: isDark),
                _daySeparator(ar ? 'اليوم' : 'Today', isDark),
                // A run of two from the agent: the first keeps all four corners, the second takes the tail.
                _bubble(ar ? 'صباح الخير! دعيني أتحقق من ذلك.' : 'Morning! Let me check that for you.',
                    '09:03',
                    outgoing: true, isDark: isDark, endsRun: false),
                _bubble(ar ? 'نعم، تم شحنه هذا الصباح.' : 'Yes — it went out this morning.', '09:04',
                    outgoing: true, isDark: isDark, startsRun: false),
                _bubble(ar ? 'شكراً جزيلاً لك!' : 'Thank you, much appreciated!', '09:06',
                    outgoing: false, isDark: isDark),
              ],
            ),
          ),
          _composer(isDark, ar ? 'اكتب رسالتك...' : 'Type your message...'),
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

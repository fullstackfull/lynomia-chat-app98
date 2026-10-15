// Which way do the directional glyphs actually point?
//
// WHY THIS EXISTS. Both of this app's directional icons were being mirrored TWICE. `LynChevron`
// swapped `arrow_forward_ios` for `arrow_back_ios_new` under RTL, and the chat back button swapped
// the other way, each under a comment asserting that Flutter does not mirror these glyphs itself.
// It does: both icons are declared `matchTextDirection: true` in material/icons.dart, and `Icon`
// answers that by flipping the glyph horizontally under RTL (widgets/icon.dart:334-342). The swap
// landed on top of that flip and cancelled it, so Arabic readers got a "more" chevron pointing
// right and a back button pointing left -- the exact bug each swap was written to prevent.
//
// A comment cannot hold that. These shots can: the arrows are large and the frames are side by
// side, so a wrong one is visible rather than argued about.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/shared/styles/lyn_controls.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// Both glyphs at a size where the direction is unmistakable, captioned with where each one lives.
Widget _scene({required bool isDark}) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row(
              caption: 'LynChevron — a row that drills in',
              isDark: isDark,
              child: LynChevron(color: LynSurface.textSecondary(isDark), size: 56),
            ),
            const SizedBox(height: LynSpace.xxl),
            _Row(
              caption: 'chat app bar — back',
              isDark: isDark,
              child: Icon(Icons.arrow_back_ios_new,
                  size: 56, color: LynSurface.textPrimary(isDark)),
            ),
          ],
        ),
      ),
    );

class _Row extends StatelessWidget {
  const _Row({required this.caption, required this.child, required this.isDark});

  final String caption;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(caption, style: LynType.caption.copyWith(color: LynSurface.textTertiary(isDark))),
          const SizedBox(height: LynSpace.md),
          child,
        ],
      );
}

void main() {
  setUpAll(loadRealFonts);

  // Left to right: the chevron points RIGHT (forward), the back arrow points LEFT.
  testWidgets('arrows, left to right', (tester) async {
    await shoot(
      tester,
      name: 'direction-ltr',
      theme: lightTheme,
      child: _scene(isDark: false),
    );
  });

  // Right to left: both must be the mirror image of the frame above — chevron LEFT, back RIGHT.
  // If a future change reintroduces a manual swap, this frame becomes identical to the one above
  // and the golden fails.
  testWidgets('arrows, right to left', (tester) async {
    await shoot(
      tester,
      name: 'direction-rtl',
      theme: lightTheme,
      direction: TextDirection.rtl,
      child: _scene(isDark: false),
    );
  });
}

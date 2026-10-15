// Renders real widgets to real PNGs, offline.
//
// There is no Android or iOS emulator in this environment and no KVM to host one, so the usual
// `flutter screenshot` route is closed. This uses Flutter's own golden-file mechanism instead: the
// widgets below are the application's actual widgets, laid out by the actual engine at a phone's
// dimensions, and `flutter test --update-goldens` writes what it painted to disk. Nothing here is a
// mockup or a drawing of what the app might look like.
//
//   flutter test test/visual --update-goldens
//
// The font files beside this one are gitignored, because they belong to the SDK rather than to this
// product. Without them a golden renders every glyph as a filled rectangle, which would make the images
// useless for the one thing they exist for, so fetch them before regenerating:
//
//   Roboto-Regular.ttf, NotoNaskhArabic-Regular.ttf
//     $FLUTTER_ROOT/engine/src/flutter/txt/third_party/fonts/
//   MaterialIcons-Regular.otf
//     the asset bundle `flutter build web` writes
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone, in logical pixels: iPhone 14 / Pixel 7 class.
const Size kPhone = Size(390, 844);

/// The family the Arabic face is registered under, and the fallback chain every golden's theme carries.
const String kArabicFamily = 'NotoNaskhArabic';
const List<String> kArabicFallback = <String>[kArabicFamily];

Future<void> loadRealFonts() async {
  Future<void> load(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  await load('Roboto', 'test/visual/Roboto-Regular.ttf');
  // Roboto carries no Arabic glyphs, so without a face that does, every Arabic golden is a wall of
  // filled rectangles and the RTL evidence is worthless. Registering it into the Roboto family does
  // NOT work -- within one family the engine selects by weight and slant, not by coverage -- so it is
  // its own family, reached through `kArabicFallback` on the theme below.
  await load(kArabicFamily, 'test/visual/NotoNaskhArabic-Regular.ttf');
  await load('MaterialIcons', 'test/visual/MaterialIcons-Regular.otf');
  // KNOWN LIMITATION, visible in the goldens: the two TextStyles declared outside `textTheme` --
  // appBarTheme.titleTextStyle and textButtonTheme.textStyle -- carry a weight but no family, so the
  // engine resolves them to its own placeholder font and paints each glyph as a filled rectangle.
  // Registering Roboto under 'FlutterTest' and 'Ahem' does not displace it. Everything that reaches
  // text through `textTheme` renders correctly, so the app bar title and text buttons are the only two
  // places in a golden where you see boxes instead of words. It is an artefact of the harness, not of
  // the application.
  await load('FlutterTest', 'test/visual/Roboto-Regular.ttf');
  await load('Ahem', 'test/visual/Roboto-Regular.ttf');
}

/// Pumps [child] inside a MaterialApp carrying [theme] at phone size, then writes the painted result
/// to `test/visual/goldens/<name>.png`.
Future<void> shoot(
  WidgetTester tester, {
  required String name,
  required ThemeData theme,
  required Widget child,
  Size size = kPhone,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // Every rank in the theme gets the Arabic face appended as a fallback. `LynType` names no family,
      // so its styles inherit this through the ambient DefaultTextStyle and one scale covers both scripts.
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamilyFallback: kArabicFallback),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamilyFallback: kArabicFallback),
      ),
      home: Directionality(textDirection: direction, child: child),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

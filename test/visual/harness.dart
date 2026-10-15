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
//   RobotoMono-Regular.ttf, RobotoMono-Medium.ttf, RobotoMono-Bold.ttf
//     $FLUTTER_ROOT/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto_Mono/
//   MaterialIcons-Regular.otf
//     the asset bundle `flutter build web` writes
//
// ONE THING A GOLDEN HERE CANNOT SHOW, an artefact of the test engine rather than the app: no emoji
// face is registered -- the colour one is 4.7MB -- so an emoji inside a string paints as a box.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/shared/app_localizations.dart';

/// A phone, in logical pixels: iPhone 14 / Pixel 7 class.
const Size kPhone = Size(390, 844);

/// The family the Arabic face is registered under, and the fallback chain every golden's theme carries.
const String kArabicFamily = 'NotoNaskhArabic';
const List<String> kArabicFallback = <String>[kArabicFamily];

Future<void> loadRealFonts() async {
  /// Several cuts under one family name. The engine picks by weight within a family, so a family
  /// registered with only its regular cut paints a w600 string as filled rectangles -- which is what
  /// the first API-reference golden did to every monospace identifier on it.
  Future<void> loadAll(String family, List<String> paths) async {
    final files = paths.map(File.new).where((f) => f.existsSync()).toList();
    if (files.isEmpty) return;
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  Future<void> load(String family, String path) => loadAll(family, <String>[path]);

  await load('Roboto', 'test/visual/Roboto-Regular.ttf');
  // Roboto carries no Arabic glyphs, so without a face that does, every Arabic golden is a wall of
  // filled rectangles and the RTL evidence is worthless. Registering it into the Roboto family does
  // NOT work -- within one family the engine selects by weight and slant, not by coverage -- so it is
  // its own family, reached through `kArabicFallback` on the theme below.
  await load(kArabicFamily, 'test/visual/NotoNaskhArabic-Regular.ttf');
  await load('MaterialIcons', 'test/visual/MaterialIcons-Regular.otf');
  await load('FlutterTest', 'test/visual/Roboto-Regular.ttf');
  await load('Ahem', 'test/visual/Roboto-Regular.ttf');
  // Registered under the name ANDROID'S PLATFORM ALIAS uses, so a code block in a golden is set in
  // the same kind of face a device sets it in. Without it the engine has no monospace family at all
  // and paints every identifier as a filled rectangle -- which says nothing about the app.
  await loadAll('monospace', const <String>[
    'test/visual/RobotoMono-Regular.ttf',
    'test/visual/RobotoMono-Medium.ttf',
    'test/visual/RobotoMono-Bold.ttf',
  ]);
}

/// The real strings, read once from the real `assets/lang/*.json`, keyed by language code.
final Map<String, AppLocalizations> _strings = <String, AppLocalizations>{};

/// Reads every supported locale's file, once per process.
///
/// WHY THIS EXISTS. `AppLocalizations.delegate.load` is an `async` function that reads an asset, so it
/// hands `Localizations` a real Future, and until that completes MaterialApp paints NOTHING. Under
/// `flutter_test` the fake clock resolves that read on the first pump of a file and not afterwards, so
/// in a file of four golden tests the first rendered and the rest came out as blank rectangles -- and
/// `--update-goldens` wrote those blanks and reported a pass. `runAsync` is the one place a test may
/// turn the real event loop, so the read happens here and `_PreloadedStrings` below hands the result
/// to the tree synchronously. The goldens still show the shipped copy from the shipped files; only the
/// delivery is made synchronous.
Future<void> _preloadStrings(WidgetTester tester) async {
  for (final locale in AppLocalizations.supportedLocales) {
    if (_strings.containsKey(locale.languageCode)) continue;
    await tester.runAsync(() async {
      _strings[locale.languageCode] = await AppLocalizations.delegate.load(locale);
    });
  }
}

class _PreloadedStrings extends LocalizationsDelegate<AppLocalizations> {
  const _PreloadedStrings();

  @override
  bool isSupported(Locale locale) => _strings.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(_strings[locale.languageCode]!);

  @override
  bool shouldReload(_PreloadedStrings old) => false;
}

const List<LocalizationsDelegate<dynamic>> _testDelegates = <LocalizationsDelegate<dynamic>>[
  _PreloadedStrings(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

/// Gives every text slot in [theme] a family the test engine actually has.
///
/// `textTheme` only needs the Arabic fallback appended. The two styles declared OUTSIDE it --
/// `appBarTheme.titleTextStyle` and `textButtonTheme.textStyle` -- carry a weight and no family at all;
/// on a device the platform supplies one, but the test engine has no default and paints each of their
/// glyphs as a filled rectangle, which used to leave every app bar title and every text button in these
/// goldens as a row of boxes. Naming the family here fixes the picture without touching the app, whose
/// behaviour on a device was never wrong.
ThemeData _withFonts(ThemeData theme) {
  const family = 'Roboto';
  TextStyle? fix(TextStyle? style) =>
      style?.copyWith(fontFamily: family, fontFamilyFallback: kArabicFallback);

  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: kArabicFallback),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamilyFallback: kArabicFallback),
    appBarTheme: theme.appBarTheme.copyWith(titleTextStyle: fix(theme.appBarTheme.titleTextStyle)),
    textButtonTheme: TextButtonThemeData(
      style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          fix(theme.textButtonTheme.style?.textStyle?.resolve(const <WidgetState>{})),
        ),
      ),
    ),
  );
}

/// Pumps [child] inside a MaterialApp carrying [theme] at phone size, then writes the painted result
/// to `test/visual/goldens/<name>.png`.
///
/// Set [localizations] when the widget under test calls `AppLocalizations.tr`: that installs the real
/// delegate, which reads the real `assets/lang/<code>.json`, so a golden shows the shipped copy rather
/// than the fallback keys. [locale] then picks which file, and is what an Arabic golden needs in
/// addition to [direction] -- direction alone mirrors the layout but leaves the words in English.
///
/// Set [after] to drive the tree before the shot: opening a drawer, pressing a tab.
Future<void> shoot(
  WidgetTester tester, {
  required String name,
  required ThemeData theme,
  required Widget child,
  Size size = kPhone,
  TextDirection direction = TextDirection.ltr,
  bool localizations = false,
  Locale locale = const Locale('en'),
  bool settle = true,
  Future<void> Function(WidgetTester tester)? after,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  // Before the tree exists: `_PreloadedStrings` serves from this map, so it has to be filled first.
  if (localizations) await _preloadStrings(tester);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // Every rank in the theme gets the Arabic face appended as a fallback. `LynType` names no family,
      // so its styles inherit this through the ambient DefaultTextStyle and one scale covers both scripts.
      theme: _withFonts(theme),
      locale: localizations ? locale : null,
      localizationsDelegates: localizations ? _testDelegates : null,
      supportedLocales:
          localizations ? AppLocalizations.supportedLocales : const <Locale>[Locale('en')],
      home: Directionality(textDirection: direction, child: child),
    ),
  );
  // A screen with a perpetual animation on it -- a progress spinner -- never has a settled frame, so
  // `pumpAndSettle` runs until it gives up and the test fails having rendered nothing. For those,
  // advance a fixed distance instead and shoot whatever frame that lands on.
  Future<void> advance() => settle
      ? tester.pumpAndSettle(const Duration(milliseconds: 400))
      : tester.pump(const Duration(milliseconds: 400));

  await advance();

  // `Image.asset` decodes through a real codec, which the fake clock does not drive: without this the
  // FIRST screen in a file paints its logos as blank space while every later one has them, because by
  // then the image cache is warm. `runAsync` is where real work is allowed to finish.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await advance();

  // Some surfaces only exist once something has been opened -- a Drawer is not in the tree until the
  // Scaffold is asked for it. This runs after the first frames have settled and before the shot.
  if (after != null) {
    await after(tester);
    await advance();
  }

  // A golden that paints nothing is worse than no golden: `--update-goldens` writes it and the run
  // reports a pass. Every screen here has words on it, so their absence means the tree never built.
  if (find.byType(Text).evaluate().isEmpty) {
    fail('"$name" painted no text -- the widget tree did not build, so the golden was not written.');
  }

  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

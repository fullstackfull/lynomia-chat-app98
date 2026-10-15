// The chat composer, pumped as the real widget.
//
// `ChatComposer` out of `lib/modules/chat/widgets/` is what the conversation screen builds at the
// bottom of every chat. It takes plain values and callbacks, so unlike the bubble goldens next door
// these are not a reconstruction of the surface -- they are the surface, laid out by the engine at a
// phone's size through the application's own themes.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/modules/chat/widgets/chat_composer.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// The composer sits at the bottom of a screen, so these pump it there rather than floating in the
/// middle: the top border and the safe-area inset only read correctly against a filled page.
Widget _page({
  required bool isDark,
  required TextEditingController controller,
  required AnimationController animation,
  bool isWhatsAppChannel = false,
  bool isRestrictedToTemplates = false,
  bool isRecording = false,
  int recordingSeconds = 0,
}) {
  return Scaffold(
    backgroundColor: LynSurface.canvas(isDark),
    body: Column(
      children: [
        const Spacer(),
        ChatComposer(
          controller: controller,
          isDark: isDark,
          isWhatsAppChannel: isWhatsAppChannel,
          isRestrictedToTemplates: isRestrictedToTemplates,
          isRecording: isRecording,
          recordingSeconds: recordingSeconds,
          recordAnimation: animation,
          onSend: () {},
          onStartRecording: () {},
          onStopRecording: () {},
          onCancelRecording: () {},
          onPickCamera: () {},
          onPickGallery: () {},
          onPickFile: () {},
          onOpenTemplates: () {},
        ),
      ],
    ),
  );
}

void main() {
  setUpAll(loadRealFonts);

  late TextEditingController controller;
  late AnimationController animation;

  setUp(() {
    controller = TextEditingController();
    animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1000),
    );
    // A fixed point in the cycle rather than a running repeat: the waveform is a sine of this value,
    // so a golden of a repeating animation would differ on every run.
    animation.value = 0.35;
  });

  tearDown(() {
    controller.dispose();
    animation.dispose();
  });

  testWidgets('composer, empty, light', (tester) async {
    await shoot(
      tester,
      name: 'composer-light',
      theme: lightTheme,
      localizations: true,
      child: _page(isDark: false, controller: controller, animation: animation),
    );
  });

  testWidgets('composer, empty, dark', (tester) async {
    await shoot(
      tester,
      name: 'composer-dark',
      theme: darkTheme,
      localizations: true,
      child: _page(isDark: true, controller: controller, animation: animation),
    );
  });

  // Typed text swaps the microphone for the send arrow. That swap is the ONLY thing in the app that
  // listens to the field now; it used to rebuild the entire chat screen on every character.
  testWidgets('composer, with text, light', (tester) async {
    controller.text = 'Your order is on its way and should arrive tomorrow morning.';
    await shoot(
      tester,
      name: 'composer-typing-light',
      theme: lightTheme,
      localizations: true,
      child: _page(isDark: false, controller: controller, animation: animation),
    );
  });

  testWidgets('composer, WhatsApp channel, dark', (tester) async {
    controller.text = 'Thanks for waiting.';
    await shoot(
      tester,
      name: 'composer-whatsapp-dark',
      theme: darkTheme,
      localizations: true,
      child: _page(
        isDark: true,
        controller: controller,
        animation: animation,
        isWhatsAppChannel: true,
      ),
    );
  });

  // Meta's 24-hour window has closed: a template is the only way to reach this customer, so the field
  // is replaced by the one thing that still works.
  testWidgets('composer, replies closed, light', (tester) async {
    await shoot(
      tester,
      name: 'composer-restricted-light',
      theme: lightTheme,
      localizations: true,
      child: _page(
        isDark: false,
        controller: controller,
        animation: animation,
        isWhatsAppChannel: true,
        isRestrictedToTemplates: true,
      ),
    );
  });

  testWidgets('composer, recording, light', (tester) async {
    await shoot(
      tester,
      name: 'composer-recording-light',
      theme: lightTheme,
      localizations: true,
      child: _page(
        isDark: false,
        controller: controller,
        animation: animation,
        isRecording: true,
        recordingSeconds: 74,
      ),
    );
  });

  testWidgets('composer, Arabic, right to left', (tester) async {
    controller.text = 'طلبك في الطريق وسيصل غداً صباحاً.';
    await shoot(
      tester,
      name: 'composer-arabic-rtl',
      theme: lightTheme,
      direction: TextDirection.rtl,
      localizations: true,
      locale: const Locale('ar'),
      child: _page(
        isDark: false,
        controller: controller,
        animation: animation,
        isWhatsAppChannel: true,
      ),
    );
  });

  testWidgets('composer, replies closed, Arabic, right to left', (tester) async {
    await shoot(
      tester,
      name: 'composer-restricted-arabic-rtl',
      theme: lightTheme,
      direction: TextDirection.rtl,
      localizations: true,
      locale: const Locale('ar'),
      child: _page(
        isDark: false,
        controller: controller,
        animation: animation,
        isWhatsAppChannel: true,
        isRestrictedToTemplates: true,
      ),
    );
  });
}

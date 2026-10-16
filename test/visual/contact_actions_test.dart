// The contact sheet, the rename dialog and the message-actions sheet, as the real widgets.
//
// All three were closures inside `chat_screen.dart` and could not be pumped. They are widgets now, so
// these are pictures of shipping code. Still not device screenshots: there is no emulator and no KVM
// here, so `flutter screenshot` is closed. Where a golden and a device disagree, the device is right.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/modules/chat/widgets/contact_details_sheet.dart';
import 'package:chat/modules/chat/widgets/message_actions_sheet.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// A date rather than `DateTime.now()`, so the "Last Activity" row reads the same on every run.
final DateTime _lastActivity = DateTime.utc(2026, 3, 12, 14, 35);

const ContactDetails _nadia = ContactDetails(
  name: 'Nadia Al-Rashid',
  email: 'nadia.alrashid@example.com',
  phone: '+965 9712 4408',
  channelType: 'Channel::Whatsapp',
);

/// The sheet over the dimmed conversation, which is how it is actually seen.
Widget _sheetScene({required bool isDark, required Widget sheet}) => Scaffold(
      backgroundColor: LynSurface.canvasAlt(isDark),
      body: Align(alignment: Alignment.bottomCenter, child: sheet),
    );

void main() {
  setUpAll(loadRealFonts);

  group('contact details', () {
    testWidgets('light', (tester) async {
      await shoot(
        tester,
        name: 'contact-light',
        theme: lightTheme,
        localizations: true,
        child: _sheetScene(
          isDark: false,
          sheet: ContactDetailsSheet(
            contact: ContactDetails(
              name: _nadia.name,
              email: _nadia.email,
              phone: _nadia.phone,
              channelType: _nadia.channelType,
              lastActivity: _lastActivity,
            ),
            isDark: false,
            isLoading: false,
            onEditName: () {},
          ),
        ),
      );
    });

    testWidgets('dark', (tester) async {
      await shoot(
        tester,
        name: 'contact-dark',
        theme: darkTheme,
        localizations: true,
        child: _sheetScene(
          isDark: true,
          sheet: ContactDetailsSheet(
            contact: ContactDetails(
              name: _nadia.name,
              email: _nadia.email,
              phone: _nadia.phone,
              channelType: _nadia.channelType,
              lastActivity: _lastActivity,
            ),
            isDark: true,
            isLoading: false,
            onEditName: () {},
          ),
        ),
      );
    });

    // Nothing filled in but the name. The three rows still stand, each saying so, rather than
    // collapsing the sheet to a name and a button.
    testWidgets('nothing known but the name', (tester) async {
      await shoot(
        tester,
        name: 'contact-sparse-light',
        theme: lightTheme,
        localizations: true,
        child: _sheetScene(
          isDark: false,
          // An EMPTY avatar url, not a null one: the case that used to paint a broken image where
          // the initial belongs.
          sheet: ContactDetailsSheet(
            contact: const ContactDetails(
                name: 'Omar', avatarUrl: '', channelType: 'Channel::TwilioSms'),
            isDark: false,
            isLoading: false,
            onEditName: () {},
          ),
        ),
      );
    });

    testWidgets('arabic', (tester) async {
      await shoot(
        tester,
        name: 'contact-ar',
        theme: lightTheme,
        localizations: true,
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        child: _sheetScene(
          isDark: false,
          sheet: ContactDetailsSheet(
            contact: ContactDetails(
              name: 'نادية الرشيد',
              email: _nadia.email,
              phone: _nadia.phone,
              channelType: _nadia.channelType,
              lastActivity: _lastActivity,
            ),
            isDark: false,
            isLoading: false,
            onEditName: () {},
          ),
        ),
      );
    });
  });

  group('rename', () {
    // Opened on the current name, so Save is disabled: there is no change to make yet.
    testWidgets('opens with nothing to save', (tester) async {
      await shoot(
        tester,
        name: 'contact-rename-light',
        theme: lightTheme,
        localizations: true,
        settle: false,
        child: Scaffold(
          backgroundColor: LynSurface.canvasAlt(false),
          body: Center(
            child: EditContactNameDialog(
              currentName: _nadia.name,
              isDark: false,
              onSave: (_) {},
            ),
          ),
        ),
      );
    });
  });

  group('message actions', () {
    testWidgets('light, destructive last', (tester) async {
      await shoot(
        tester,
        name: 'message-actions-light',
        theme: lightTheme,
        localizations: true,
        child: _sheetScene(
          isDark: false,
          // `showModalBottomSheet` puts a Material above the sheet, carrying the colour and the
          // shape. A plain DecoratedBox there would swallow each row's ink splash.
          sheet: Material(
            color: LynSurface.surface(false),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: MessageActionsSheet(
              isDark: false,
              canCopy: true,
              onCopy: () {},
              onSelect: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
    });

    // An attachment with no caption: there is nothing to copy, so that row is not offered.
    testWidgets('dark, nothing to copy', (tester) async {
      await shoot(
        tester,
        name: 'message-actions-dark',
        theme: darkTheme,
        localizations: true,
        child: _sheetScene(
          isDark: true,
          // `showModalBottomSheet` puts a Material above the sheet, carrying the colour and the
          // shape. A plain DecoratedBox there would swallow each row's ink splash.
          sheet: Material(
            color: LynSurface.surface(true),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: MessageActionsSheet(
              isDark: true,
              canCopy: false,
              onCopy: () {},
              onSelect: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
    });

    testWidgets('arabic', (tester) async {
      await shoot(
        tester,
        name: 'message-actions-ar',
        theme: lightTheme,
        localizations: true,
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        child: _sheetScene(
          isDark: false,
          // `showModalBottomSheet` puts a Material above the sheet, carrying the colour and the
          // shape. A plain DecoratedBox there would swallow each row's ink splash.
          sheet: Material(
            color: LynSurface.surface(false),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: MessageActionsSheet(
              isDark: false,
              canCopy: true,
              onCopy: () {},
              onSelect: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
    });
  });
}

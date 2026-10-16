// The two screens an agent meets before the inbox: signing in, and choosing where to work.
//
// The login screen is pumped WHOLE -- `LoginScreen` is the production widget, wrapped only in the
// Cubit it reads `isDark` from. The inbox picker's card cannot be: it lives on a private State that
// fetches on init, so the card here is rebuilt from the same `LynChannel` and `LynSurface` calls the
// screen makes. The inbox names below are invented for this test.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat/layout/cubit/cubit.dart';
import 'package:chat/models/chatwoot_models.dart';
import 'package:chat/modules/login/login_screen.dart';
import 'package:chat/shared/app_localizations.dart';
import 'package:chat/shared/network/local/cache_helper.dart';
import 'package:chat/shared/styles/lyn_channel.dart';
import 'package:chat/shared/styles/lyn_controls.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// The real cubit, with only the one field these screens read set. Nothing on this path makes a
/// request: `LoginScreen.build` reads `isDark` and renders.
AppCubit _cubit(bool isDark) => AppCubit()..isDark = isDark;

Widget _login(bool isDark) => BlocProvider<AppCubit>(
      create: (_) => _cubit(isDark),
      child: const LoginScreen(),
    );

const _inboxes = <ChatwootInbox>[
  ChatwootInbox(id: 1, name: 'WhatsApp — Sales', channelType: 'Channel::Whatsapp'),
  ChatwootInbox(id: 2, name: 'Support inbox', channelType: 'Channel::Email'),
  ChatwootInbox(id: 3, name: 'Website chat', channelType: 'Channel::WebWidget'),
  ChatwootInbox(id: 4, name: 'Instagram', channelType: 'Channel::Instagram'),
  ChatwootInbox(id: 5, name: 'Order alerts', channelType: 'Channel::TwilioSms'),
];

/// The inbox picker's card, built from the same calls `_buildInboxCard` makes.
Widget _inboxCard(BuildContext context, ChatwootInbox inbox, bool isDark) {
  final accent = LynChannel.color(inbox.channelType);
  return Padding(
    padding: const EdgeInsets.only(bottom: LynSpace.md),
    child: Container(
      padding: const EdgeInsets.all(LynSpace.lg),
      decoration: BoxDecoration(
        color: LynSurface.surface(isDark),
        borderRadius: BorderRadius.circular(LynSpace.lg),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(LynSpace.md),
            ),
            child: Icon(LynChannel.icon(inbox.channelType), size: 24, color: accent),
          ),
          const SizedBox(width: LynSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(inbox.name ?? 'Inbox ${inbox.id}',
                    style: LynType.subtitle.copyWith(color: LynSurface.textPrimary(isDark))),
                const SizedBox(height: 2),
                Text(LynChannel.label(context, inbox.channelType),
                    style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark))),
              ],
            ),
          ),
          const SizedBox(width: LynSpace.sm),
          LynChevron(color: LynSurface.borderStrong(isDark), size: 14),
        ],
      ),
    ),
  );
}

Widget _inboxPicker(bool isDark) => Builder(
      builder: (context) => Scaffold(
        backgroundColor: LynSurface.canvas(isDark),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: LynSurface.surface(isDark),
          shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
          centerTitle: true,
          iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
          title: Text(AppLocalizations.tr(context, 'Select Inbox'),
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
        ),
        body: ListView(
          padding: const EdgeInsets.all(LynSpace.lg),
          children: [for (final i in _inboxes) _inboxCard(context, i, isDark)],
        ),
      ),
    );

void main() {
  setUpAll(() async {
    await loadRealFonts();
    // `LoginScreen.initState` reads the remembered email out of SharedPreferences, and
    // `CacheHelper.getString` dereferences its static with `!`. In the app `main` calls `init` first;
    // here the mock store stands in for it, empty, so the email field renders as a new device would
    // show it. Nothing on this path makes a request.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CacheHelper.init();
  });

  testWidgets('login, light', (t) async {
    await shoot(t, name: 'login-light', theme: lightTheme, localizations: true, child: _login(false));
  });

  testWidgets('login, dark', (t) async {
    await shoot(t, name: 'login-dark', theme: darkTheme, localizations: true, child: _login(true));
  });

  testWidgets('login, Arabic RTL', (t) async {
    await shoot(t,
        name: 'login-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _login(false));
  });

  testWidgets('inbox picker, light', (t) async {
    await shoot(t,
        name: 'inboxes-light', theme: lightTheme, localizations: true, child: _inboxPicker(false));
  });

  testWidgets('inbox picker, Arabic RTL', (t) async {
    await shoot(t,
        name: 'inboxes-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _inboxPicker(false));
  });
}

// The home screen, as the application actually builds it.
//
// Unlike the chat goldens, nothing here is a reconstruction: `HomeView` is the production widget, taken
// straight out of `lib/layout/`, and these pump it. It takes plain values and callbacks rather than
// reaching for the cubit, which is what makes that possible — so what the PNGs show is what a device
// shows, down to the layout, short of the platform's own font and status bar.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/layout/home_view.dart';
import 'package:chat/models/chatwoot_models.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

const _subscribed = ChatwootSubscription(
  plan: 'Growth',
  status: 'active',
  endsAt: '2026-04-30',
  isActive: true,
);

Widget _home(bool isDark, {required bool isSubscribed}) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: LynSurface.surface(isDark),
        shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        leading: Icon(Icons.menu, color: LynSurface.textPrimary(isDark)),
        title: const Text('Lynomia Chat'),
        centerTitle: true,
      ),
      body: HomeView(
        isDark: isDark,
        isSubscribed: isSubscribed,
        subscription: isSubscribed ? _subscribed : null,
        onOpenConversations: _noop,
        onOpenPlans: _noop,
        onOpenPaymentHistory: _noop,
        onOpenApiDocumentation: _noop,
      ),
    );

void _noop() {}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('home, subscribed, light', (t) async {
    await shoot(t,
        name: 'home-light',
        theme: lightTheme,
        localizations: true,
        child: _home(false, isSubscribed: true));
  });

  testWidgets('home, subscribed, dark', (t) async {
    await shoot(t,
        name: 'home-dark',
        theme: darkTheme,
        localizations: true,
        child: _home(true, isSubscribed: true));
  });

  testWidgets('home, no subscription', (t) async {
    await shoot(t,
        name: 'home-locked',
        theme: lightTheme,
        localizations: true,
        child: _home(false, isSubscribed: false));
  });

  testWidgets('home, Arabic RTL', (t) async {
    await shoot(t,
        name: 'home-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _home(false, isSubscribed: true));
  });
}

// The navigation drawer, pumped as the real widget.
//
// `AppDrawer` out of `lib/layout/widgets/` is the drawer `LayoutScreen` builds. It takes its sections
// as data, so these are the real rows, the real grouping and the real footer -- not a drawing of them.
// The subscription below is invented for this test and nothing here touches a server.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/layout/widgets/app_drawer.dart';
import 'package:chat/shared/app_localizations.dart';
import 'package:chat/shared/styles/lyn_controls.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// The same three groups the screen builds, with the navigation replaced by nothing.
List<DrawerSection> _sections(BuildContext context, {required bool isDark, required bool isSubscribed}) {
  return <DrawerSection>[
    DrawerSection(
      labelKey: 'section_workspace',
      destinations: <DrawerDestination>[
        DrawerDestination(
          icon: Icons.chat_bubble_outline,
          label: AppLocalizations.tr(context, 'conversations'),
          isLocked: !isSubscribed,
          onTap: () {},
        ),
      ],
    ),
    DrawerSection(
      labelKey: 'section_account',
      destinations: <DrawerDestination>[
        DrawerDestination(
          icon: Icons.card_membership_outlined,
          label: AppLocalizations.tr(context, 'subscriptions'),
          trailing: LynStatusPill(isActive: isSubscribed, isDark: isDark),
          onTap: () {},
        ),
        DrawerDestination(
          icon: Icons.receipt_long_outlined,
          label: AppLocalizations.tr(context, 'Payment history'),
          onTap: () {},
        ),
      ],
    ),
    DrawerSection(
      labelKey: 'section_app',
      destinations: <DrawerDestination>[
        DrawerDestination(
          icon: Icons.language,
          label: AppLocalizations.tr(context, 'language'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: 2),
            decoration: BoxDecoration(
              color: LynPalette.indigo.withOpacity(isDark ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'English',
              style: LynType.micro.copyWith(
                color: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep,
              ),
            ),
          ),
          onTap: () {},
        ),
        DrawerDestination(
          icon: Icons.privacy_tip_outlined,
          label: AppLocalizations.tr(context, 'privacy_policy'),
          onTap: () {},
        ),
        DrawerDestination(
          icon: Icons.code,
          label: AppLocalizations.tr(context, 'api_documentation'),
          onTap: () {},
        ),
      ],
    ),
  ];
}

/// A Drawer only lays out inside a Scaffold that has somewhere to put it, so these open one.
Widget _page({
  required bool isDark,
  required bool isSubscribed,
  String? planLabel,
  String? renewsOn,
}) {
  return Builder(
    builder: (context) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      drawer: AppDrawer(
        isDark: isDark,
        isSubscribed: isSubscribed,
        planLabel: planLabel ??
            AppLocalizations.tr(context, isSubscribed ? 'subscriber' : 'not_subscriber'),
        renewsOn: renewsOn,
        sections: _sections(context, isDark: isDark, isSubscribed: isSubscribed),
        onToggleTheme: () {},
        onBrandTap: () {},
        onLogout: () {},
      ),
      body: const SizedBox.expand(),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  final state = tester.firstState<ScaffoldState>(find.byType(Scaffold));
  state.openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('drawer, subscribed, light', (tester) async {
    await shoot(
      tester,
      name: 'drawer-light',
      theme: lightTheme,
      localizations: true,
      child: _page(
        isDark: false,
        isSubscribed: true,
        planLabel: 'Growth',
        renewsOn: 'Apr 30, 2026',
      ),
      after: _openDrawer,
    );
  });

  testWidgets('drawer, subscribed, dark', (tester) async {
    await shoot(
      tester,
      name: 'drawer-dark',
      theme: darkTheme,
      localizations: true,
      child: _page(
        isDark: true,
        isSubscribed: true,
        planLabel: 'Growth',
        renewsOn: 'Apr 30, 2026',
      ),
      after: _openDrawer,
    );
  });

  // No subscription: Conversations is reachable but padlocked, and the pill reads inactive. The row
  // still responds -- tapping it is how anyone finds out what a plan would unlock.
  testWidgets('drawer, no subscription, light', (tester) async {
    await shoot(
      tester,
      name: 'drawer-locked-light',
      theme: lightTheme,
      localizations: true,
      child: _page(isDark: false, isSubscribed: false),
      after: _openDrawer,
    );
  });

  testWidgets('drawer, Arabic, right to left', (tester) async {
    await shoot(
      tester,
      name: 'drawer-arabic-rtl',
      theme: lightTheme,
      direction: TextDirection.rtl,
      localizations: true,
      locale: const Locale('ar'),
      child: _page(
        isDark: false,
        isSubscribed: true,
        planLabel: 'النمو',
        renewsOn: '٣٠ أبريل ٢٠٢٦',
      ),
      after: _openDrawer,
    );
  });
}

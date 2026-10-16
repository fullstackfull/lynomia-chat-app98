// The loading states, as the application actually builds them.
//
// `ConversationListSkeleton` and `InboxListSkeleton` are the production widgets out of
// `lib/modules/`, and `LynSkeletonGroup` is the production sweep, so these pump the shipped things
// rather than reconstructions. Nothing here touches a server: the two real rows below carry invented
// names so that the height comparisons have something to measure against.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/models/chatwoot_models.dart';
import 'package:chat/modules/conversations_list/conversations_list_screen.dart';
import 'package:chat/modules/inbox_selection/inbox_selection_screen.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_skeleton.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

void _noop() {}

/// The conversations screen's own chrome around the placeholder, so the golden shows what an agent
/// sees in the second before the inbox loads rather than a floating stack of grey bars.
Widget _conversationsLoading(bool isDark, {bool ar = false}) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: LynSurface.surface(isDark),
        shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        title: Text(ar ? 'واتساب — المبيعات' : 'WhatsApp — Sales',
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
      ),
      body: ConversationListSkeleton(isDark: isDark),
    );

Widget _inboxLoading(bool isDark, {bool ar = false}) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: LynSurface.surface(isDark),
        shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        title: Text(ar ? 'اختر صندوق الوارد' : 'Select Inbox',
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
      ),
      body: InboxListSkeleton(isDark: isDark),
    );

ChatwootConversation get _realConversation => ChatwootConversation(
      id: 1,
      status: 'open',
      unreadCount: 0,
      contactName: 'Noura Alfahad',
      lastMessageContent: 'Has my order shipped yet?',
      lastMessageAt: DateTime(2026, 3, 12, 9, 0),
    );

const ChatwootInbox _realInbox = ChatwootInbox(
  id: 7,
  name: 'WhatsApp — Sales',
  channelType: 'Channel::Whatsapp',
);

void main() {
  setUpAll(loadRealFonts);

  // ── The pictures ────────────────────────────────────────────────────────────
  // A sweep never reaches a settled frame, so these advance a fixed distance instead of settling,
  // and `present` names a block rather than a `Text` because a placeholder has no words on it.

  testWidgets('conversations loading, light', (t) async {
    await shoot(t,
        name: 'skeleton-conversations-light',
        theme: lightTheme,
        localizations: true,
        settle: false,
        present: find.byType(LynSkeletonBlock),
        child: _conversationsLoading(false));
  });

  testWidgets('conversations loading, dark', (t) async {
    await shoot(t,
        name: 'skeleton-conversations-dark',
        theme: darkTheme,
        localizations: true,
        settle: false,
        present: find.byType(LynSkeletonBlock),
        child: _conversationsLoading(true));
  });

  testWidgets('conversations loading, Arabic RTL', (t) async {
    await shoot(t,
        name: 'skeleton-conversations-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        settle: false,
        present: find.byType(LynSkeletonBlock),
        child: _conversationsLoading(false, ar: true));
  });

  testWidgets('conversations loading, reduced motion', (t) async {
    await shoot(t,
        name: 'skeleton-conversations-reduced-motion',
        theme: lightTheme,
        localizations: true,
        disableAnimations: true,
        present: find.byType(LynSkeletonBlock),
        child: _conversationsLoading(false));
  });

  testWidgets('inboxes loading, light', (t) async {
    await shoot(t,
        name: 'skeleton-inboxes-light',
        theme: lightTheme,
        localizations: true,
        settle: false,
        present: find.byType(LynSkeletonBlock),
        child: _inboxLoading(false));
  });

  testWidgets('inboxes loading, dark', (t) async {
    await shoot(t,
        name: 'skeleton-inboxes-dark',
        theme: darkTheme,
        localizations: true,
        settle: false,
        present: find.byType(LynSkeletonBlock),
        child: _inboxLoading(true));
  });

  testWidgets('inboxes loading, Arabic RTL', (t) async {
    await shoot(t,
        name: 'skeleton-inboxes-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        settle: false,
        present: find.byType(LynSkeletonBlock),
        child: _inboxLoading(false, ar: true));
  });

  // ── The claims ──────────────────────────────────────────────────────────────

  // The OS font-size setting reaches both screens -- nothing in lib/ clamps `textScaler` -- so the
  // parity these two tests pin has to hold across the range, not only at the default. An earlier
  // version of the placeholders was built from fixed pixel literals and matched at 1.0 and nowhere
  // else: the real conversation row measures 73 / 82 / 113 at scale 1.0 / 1.3 / 2.0, so the fifth
  // row landed 36px, then 160px, from the grey bar that stood for it.
  const scales = <double>[0.85, 1.0, 1.15, 1.3, 1.5, 2.0];

  for (final scale in scales) {
    testWidgets('a placeholder row is as tall as its real row at text scale $scale', (t) async {
      await t.pumpWidget(await testApp(
        t,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SizedBox(
              width: 390,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConversationItem(
                    conversation: _realConversation,
                    isSelected: false,
                    isDark: false,
                    onTap: _noop,
                    now: DateTime(2026, 3, 12, 14, 30),
                  ),
                  const SizedBox(
                      height: 400, child: ConversationListSkeleton(isDark: false, rows: 1)),
                ],
              ),
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));

      // The whole point of a skeleton over a spinner: the real rows arrive in the same place, so the
      // list fills rather than jumping. If this drifts, the jump is back.
      final placeholder = find
          .descendant(
            of: find.byType(ConversationListSkeleton),
            matching: find.byType(Container),
          )
          .first;
      expect(t.getSize(placeholder).height, t.getSize(find.byType(ConversationItem)).height);
    });

    testWidgets('a placeholder card is as tall as the inbox card at text scale $scale', (t) async {
      await t.pumpWidget(await testApp(
        t,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SizedBox(
              width: 390,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    // The real list's gutter, which the card itself does not carry.
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InboxCard(inbox: _realInbox, isDark: false, onTap: _noop),
                  ),
                  const SizedBox(height: 400, child: InboxListSkeleton(isDark: false, cards: 1)),
                ],
              ),
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));

      // Measured on the outer Padding of each, so the 12px gap between cards counts on both sides.
      final placeholder = find
          .descendant(of: find.byType(InboxListSkeleton), matching: find.byType(Padding))
          .first;
      expect(t.getSize(placeholder).height, t.getSize(find.byType(InboxCard)).height);
    });
  }

  testWidgets('the group announces what is loading, in the running locale', (t) async {
    final handle = t.ensureSemantics();

    await t.pumpWidget(await testApp(
      t,
      home: const Scaffold(body: ConversationListSkeleton(isDark: false)),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.getSemantics(find.byType(LynSkeletonGroup)).label, 'Loading conversations…');

    await t.pumpWidget(await testApp(
      t,
      locale: const Locale('ar'),
      home: const Scaffold(body: ConversationListSkeleton(isDark: false)),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.getSemantics(find.byType(LynSkeletonGroup)).label, 'جارٍ تحميل المحادثات…');

    handle.dispose();
  });

  testWidgets('the sweep runs by default and holds still when the system says to', (t) async {
    Future<void> pumpWith({required bool motionOff}) async {
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: motionOff),
          child: const Scaffold(
            // No localizations: the label is passed in, so this asserts motion and nothing else.
            body: LynSkeletonGroup(
              isDark: false,
              label: 'loading',
              child: LynSkeletonBlock(isDark: false, width: 100, height: 10),
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
    }

    await pumpWith(motionOff: false);
    // The sweep is painted by the ShaderMask, and a running controller keeps asking for frames.
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(t.binding.hasScheduledFrame, isTrue);

    await pumpWith(motionOff: true);
    // Not merely stopped: the mask is gone, so the blocks paint in their own base tone and the tree
    // does nothing at all until the content arrives.
    expect(find.byType(ShaderMask), findsNothing);
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a block paints the skeleton tone, not the brand', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LynSkeletonBlock(isDark: false, width: 100, height: 10),
      ),
    ));

    final box = t.widget<Container>(find.byType(Container));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, LynSkeleton.base(false));
    // The spinner this replaces was brand indigo, which on a placeholder reads as content.
    expect(decoration.color, isNot(LynPalette.indigo));
  });
}

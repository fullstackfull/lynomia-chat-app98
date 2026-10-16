// The conversation list row, as the application actually builds it.
//
// `ConversationItem` is the production widget out of `lib/modules/conversations_list/`, and it takes a
// `ChatwootConversation` and nothing else, so these pump the real thing rather than a reconstruction.
// The contacts below are invented for this test and nothing here ever touches a server: no customer's
// name, number or message is in these PNGs.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/models/chatwoot_models.dart';
import 'package:chat/modules/conversations_list/conversations_list_screen.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

/// Fixed so the goldens are stable: the rows are rendered against this instant, not against now.
final DateTime _now = DateTime(2026, 3, 12, 14, 30);

List<ChatwootConversation> _rows(bool ar) => <ChatwootConversation>[
      ChatwootConversation(
        id: 1,
        status: 'open',
        unreadCount: 3,
        contactName: ar ? 'نورة الفهد' : 'Noura Alfahad',
        lastMessageContent: ar ? 'هل وصل طلبي رقم ٤٨٢١؟' : 'Has my order 4821 shipped yet?',
        lastMessageAt: _now.subtract(const Duration(minutes: 8)),
      ),
      ChatwootConversation(
        id: 2,
        status: 'pending',
        unreadCount: 0,
        contactName: ar ? 'خالد العتيبي' : 'Khalid Al-Otaibi',
        lastMessageContent:
            ar ? 'شكراً، سأنتظر رد فريق الشحن.' : 'Thanks, I will wait to hear from shipping.',
        lastMessageAt: _now.subtract(const Duration(hours: 20)),
      ),
      ChatwootConversation(
        id: 3,
        status: 'resolved',
        unreadCount: 0,
        contactName: ar ? 'سارة المطيري' : 'Sara Al-Mutairi',
        lastMessageContent: ar ? 'تمام، تم استلام الطلب.' : 'All good — the order arrived.',
        lastMessageAt: _now.subtract(const Duration(days: 3)),
      ),
      ChatwootConversation(
        id: 4,
        status: 'open',
        unreadCount: 112,
        contactName: ar ? 'متجر الواحة' : 'Oasis Supplies',
        lastMessageContent: ar
            ? 'نحتاج تحديث على الفاتورة قبل نهاية الأسبوع من فضلكم.'
            : 'We need the invoice updated before the end of the week, please.',
        lastMessageAt: _now.subtract(const Duration(days: 40)),
      ),
    ];

Widget _screen(bool isDark, {bool ar = false}) => Scaffold(
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
      body: ListView(
        children: [
          for (final c in _rows(ar))
            ConversationItem(
              conversation: c,
              isSelected: false,
              isDark: isDark,
              onTap: _noop,
              // Pinned to the same instant the rows are built against, so the stamps show what a
              // reader actually sees: a clock time on today's, "Yesterday", a weekday, then a date.
              now: _now,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _noop,
        backgroundColor: LynPalette.indigo,
        icon: const Icon(Icons.chat, color: Colors.white),
        label: Text(ar ? 'محادثة واتساب جديدة' : 'New WhatsApp Chat',
            style: LynType.callout.copyWith(color: Colors.white)),
      ),
    );

void _noop() {}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('conversations, light', (t) async {
    await shoot(t,
        name: 'conversations-light',
        theme: lightTheme,
        localizations: true,
        child: _screen(false));
  });

  testWidgets('conversations, dark', (t) async {
    await shoot(t,
        name: 'conversations-dark',
        theme: darkTheme,
        localizations: true,
        child: _screen(true));
  });

  testWidgets('conversations, Arabic RTL', (t) async {
    await shoot(t,
        name: 'conversations-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _screen(false, ar: true));
  });
}

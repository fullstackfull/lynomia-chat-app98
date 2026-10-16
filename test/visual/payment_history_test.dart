// The receipts: what has been paid, nothing paid yet, and the fetch failing.
//
// `PaymentHistoryList`, `PaymentHistoryEmpty` and `PaymentHistoryFailure` are the production
// widgets, pumped whole. The payments below are invented for this test — the ids are not real
// Stripe intents and the dates are fixed so the goldens do not move.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/models/payment_history_model.dart';
import 'package:chat/modules/payment_history/payment_history_screen.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

PaymentHistoryModel _payment({
  required int id,
  required String intentId,
  required String way,
  required String price,
  required String note,
  required DateTime at,
}) =>
    PaymentHistoryModel(
      id: id,
      userId: '1',
      intentId: intentId,
      platform: 'android',
      updatedAt: at,
      createdAt: at,
      price: price,
      note: note,
      way: way,
    );

final _history = <PaymentHistoryModel>[
  _payment(
    id: 3,
    intentId: 'pi_3QXk8aL2eZvKYlo2C4nJ91Ab',
    way: 'stripe',
    price: '49.00',
    note: 'Package ID: {Growth}',
    at: DateTime(2026, 9, 1),
  ),
  _payment(
    id: 2,
    intentId: 'GPA.3382-9174-5503-21884',
    way: 'google_play',
    price: '49.00',
    note: 'Package ID: {Growth}',
    at: DateTime(2026, 8, 1),
  ),
  // No plan name in the note: the row used to title itself with the English word "Unknown".
  _payment(
    id: 1,
    intentId: 'pi_3QA1kBL2eZvKYlo2ZzQ7m0Cd',
    way: 'stripe',
    price: '19.00',
    note: 'first month',
    at: DateTime(2026, 7, 1),
  ),
];

Widget _screen(Widget body, bool isDark, String title) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        backgroundColor: LynSurface.surface(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        title: Text(title, style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
      ),
      body: body,
    );

Widget _list(bool isDark) => PaymentHistoryList(
      history: _history,
      isDark: isDark,
      onRefresh: () async {},
    );

void main() {
  setUpAll(loadRealFonts);

  testWidgets('history, light', (t) async {
    await shoot(t,
        name: 'history-light',
        theme: lightTheme,
        localizations: true,
        child: _screen(_list(false), false, 'Payment history'));
  });

  testWidgets('history, dark', (t) async {
    await shoot(t,
        name: 'history-dark',
        theme: darkTheme,
        localizations: true,
        child: _screen(_list(true), true, 'Payment history'));
  });

  testWidgets('history, Arabic RTL', (t) async {
    await shoot(t,
        name: 'history-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _screen(_list(false), false, 'سجل المدفوعات'));
  });

  testWidgets('nothing paid yet', (t) async {
    await shoot(t,
        name: 'history-empty-light',
        theme: lightTheme,
        localizations: true,
        child: _screen(const PaymentHistoryEmpty(isDark: false), false, 'Payment history'));
  });

  // The failure the cubit names `history_network`, said in the reader's language. It used to be an
  // Arabic sentence printed as-is to English users.
  testWidgets('the fetch failed', (t) async {
    await shoot(t,
        name: 'history-error-light',
        theme: lightTheme,
        localizations: true,
        child: _screen(
          Builder(
            builder: (context) => PaymentHistoryFailure(
              message: 'Could not reach the network. Check your connection and try again.',
              isDark: false,
              onRetry: () {},
            ),
          ),
          false,
          'Payment history',
        ));
  });
}

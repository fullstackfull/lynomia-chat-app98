// The purchase: choosing a plan, paying for it, and what came of it.
//
// All three are PRODUCTION WIDGETS, pumped whole. `PlanPicker`, `PaymentForm` and `PaymentResultView`
// are what the three screens render; each takes plain values and callbacks, so a golden can pump the
// real tree without a cubit, a socket or a network call. The screens around them do nothing but
// supply those values from the cubit.
//
// The plans below are invented for this test. They are shaped like the API's: a price in cents, limits
// as integers, and features as the snake_case keys the catalogue looks up. The keys are the six the
// catalogue actually carries, plus two it does not, so the goldens show both what a known feature
// renders as and what the fallback does with an unknown one.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/layout/payment/payment_cubit.dart' show PaymentMethod;
import 'package:chat/models/plan_models.dart';
import 'package:chat/modules/payment/payment_screen.dart';
import 'package:chat/modules/payment/plan_selection_screen.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

final _startup = PlanModel(
  id: 'startup',
  name: 'Startup',
  price: 1900,
  agents: 2,
  inboxes: 1,
  features: const ['channels', 'canned_responses', 'email_support'],
);

final _growth = PlanModel(
  id: 'growth',
  name: 'Growth',
  price: 4900,
  agents: 10,
  inboxes: 5,
  features: const [
    'channels',
    'canned_responses',
    'advanced_reports',
    'integrations',
    'ai_features',
    'priority_support',
  ],
);

final _enterprise = PlanModel(
  id: 'enterprise',
  name: 'Enterprise',
  price: 9900,
  agents: 50,
  inboxes: 25,
  features: const [
    'channels',
    'custom_channels',
    'canned_responses',
    'advanced_reports',
    'integrations',
    'ai_features',
    'audit_log',
    'dedicated_account_manager',
  ],
);

List<PlanModel> get _plans => [_startup, _growth, _enterprise];

/// The plan screen's app bar, so a golden shows the screen and not just its body. The screen's own
/// `AppBar` cannot come along: it is built inside `PlanSelectionScreen.build`, above the `BlocProvider`
/// that makes the network call.
Widget _planScreen(Widget body, bool isDark, String title) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        backgroundColor: LynSurface.surface(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        title: Text(title,
            style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
      ),
      body: body,
    );

Widget _picker(PlanModel selected, bool isDark) => PlanPicker(
      plans: _plans,
      selected: selected,
      isDark: isDark,
      onSelect: (_) {},
      onSubscribe: () {},
    );

Widget _form(PaymentMethod method, bool isDark, {bool isProcessing = false}) => PaymentForm(
      plan: _growth,
      method: method,
      isProcessing: isProcessing,
      isDark: isDark,
      onMethodChange: (_) {},
      onPay: () {},
      onCancel: () {},
    );

void main() {
  setUpAll(loadRealFonts);

  group('choosing a plan', () {
    testWidgets('light', (t) async {
      await shoot(t,
          name: 'plans-light',
          theme: lightTheme,
          localizations: true,
          child: _planScreen(_picker(_growth, false), false, 'Choose the plan'));
    });

    testWidgets('dark', (t) async {
      await shoot(t,
          name: 'plans-dark',
          theme: darkTheme,
          localizations: true,
          child: _planScreen(_picker(_growth, true), true, 'Choose the plan'));
    });

    // The top plan selected, to show that the accent follows the plan and that the longest feature
    // list still scrolls under a button that has not moved.
    testWidgets('top plan selected', (t) async {
      await shoot(t,
          name: 'plans-enterprise-light',
          theme: lightTheme,
          localizations: true,
          child: _planScreen(_picker(_enterprise, false), false, 'Choose the plan'));
    });

    testWidgets('Arabic RTL', (t) async {
      await shoot(t,
          name: 'plans-arabic-rtl',
          theme: lightTheme,
          locale: const Locale('ar'),
          localizations: true,
          direction: TextDirection.rtl,
          child: _planScreen(_picker(_growth, false), false, 'اختر الخطة'));
    });
  });

  group('paying', () {
    testWidgets('light', (t) async {
      await shoot(t,
          name: 'payment-light',
          theme: lightTheme,
          localizations: true,
          child: _planScreen(_form(PaymentMethod.stripe, false), false, 'Complete payment'));
    });

    testWidgets('dark', (t) async {
      await shoot(t,
          name: 'payment-dark',
          theme: darkTheme,
          localizations: true,
          child: _planScreen(_form(PaymentMethod.stripe, true), true, 'Complete payment'));
    });

    testWidgets('Arabic RTL', (t) async {
      await shoot(t,
          name: 'payment-arabic-rtl',
          theme: lightTheme,
          locale: const Locale('ar'),
          localizations: true,
          direction: TextDirection.rtl,
          child: _planScreen(_form(PaymentMethod.stripe, false), false, 'إتمام الدفع'));
    });

    // Mid-payment: the button carries the progress and is disabled, and the cancel link is gone, so
    // there is nothing on screen to press twice.
    testWidgets('processing', (t) async {
      await shoot(t,
          name: 'payment-processing-light',
          theme: lightTheme,
          localizations: true,
          // The progress spinner turns forever, so there is no settled frame to wait for.
          settle: false,
          child: _planScreen(
              _form(PaymentMethod.stripe, false, isProcessing: true), false, 'Complete payment'));
    });
  });

  group('the result', () {
    testWidgets('paid', (t) async {
      await shoot(t,
          name: 'payment-result-success-light',
          theme: lightTheme,
          localizations: true,
          child: PaymentResultView(
            isSuccess: true,
            paymentId: 'pi_3QXk8aL2eZvKYlo2C4nJ91Ab',
            planName: 'Growth',
            isDark: false,
            onDone: () {},
          ));
    });

    // The Stripe deep link's entitlements call has not named the plan yet. This used to read
    // "Your subscription to plan الجديدة has been activated successfully" in English.
    testWidgets('paid, plan name not back yet', (t) async {
      await shoot(t,
          name: 'payment-result-success-unnamed-light',
          theme: lightTheme,
          localizations: true,
          child: PaymentResultView(
            isSuccess: true,
            paymentId: 'pi_3QXk8aL2eZvKYlo2C4nJ91Ab',
            planName: '',
            isDark: false,
            onDone: () {},
          ));
    });

    testWidgets('failed, dark', (t) async {
      await shoot(t,
          name: 'payment-result-failure-dark',
          theme: darkTheme,
          localizations: true,
          child: PaymentResultView(
            isSuccess: false,
            paymentId: '',
            planName: 'Growth',
            isDark: true,
            onDone: () {},
          ));
    });
  });
}

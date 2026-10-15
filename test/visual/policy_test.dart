// The legal documents: the privacy policy, the terms, and who the company is.
//
// `PolicyCard` and `PolicyDocument` are the production widgets, pumped whole. The text below is
// invented for this test and is NOT Lynomia's policy — it exists to exercise the parser: headings
// written as `Title: body`, a paragraph with no heading, a paragraph that opens with a URL, and a
// sentence whose colon is too deep in to be a title.
//
// It is given with UNIX line endings on purpose. The old splitter matched '\r\n\r\n' only, so on this
// exact input it found no sections at all and painted the whole document as one block.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/modules/privacy/policy_document.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

const _policy = 'What we collect: your name, your email address, and the messages you send through '
    'the inbox. Nothing else leaves your device.\n'
    '\n'
    'How long we keep it: for as long as your account is open, and for thirty days after you close '
    'it, so that an accidental deletion can be undone.\n'
    '\n'
    'We do not sell anything about you to anyone, and we never have.\n'
    '\n'
    'Where to read more: https://lynomia.com/privacy\n';

const _policyArabic = 'ما الذي نجمعه: اسمك وبريدك الإلكتروني والرسائل التي ترسلها عبر صندوق الوارد. '
    'لا شيء غير ذلك يغادر جهازك.\n'
    '\n'
    'كم نحتفظ به: ما دام حسابك مفتوحاً، ولمدة ثلاثين يوماً بعد إغلاقه، حتى يمكن التراجع عن أي حذف '
    'غير مقصود.\n'
    '\n'
    'نحن لا نبيع أي شيء عنك لأي جهة، ولم نفعل ذلك قط.\n';

Widget _screen(Widget body, bool isDark, String title) => Scaffold(
      backgroundColor: LynSurface.canvas(isDark),
      appBar: AppBar(
        backgroundColor: LynSurface.canvas(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
        title: Text(title, style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LynSpace.lg),
        child: body,
      ),
    );

void main() {
  setUpAll(loadRealFonts);

  testWidgets('privacy policy, light', (t) async {
    await shoot(t,
        name: 'policy-light',
        theme: lightTheme,
        localizations: true,
        child: _screen(
          const PolicyCard(
            title: 'Privacy policy',
            icon: Icons.privacy_tip_outlined,
            text: _policy,
            isDark: false,
          ),
          false,
          'Legal',
        ));
  });

  testWidgets('privacy policy, dark', (t) async {
    await shoot(t,
        name: 'policy-dark',
        theme: darkTheme,
        localizations: true,
        child: _screen(
          const PolicyCard(
            title: 'Privacy policy',
            icon: Icons.privacy_tip_outlined,
            text: _policy,
            isDark: true,
          ),
          true,
          'Legal',
        ));
  });

  testWidgets('privacy policy, Arabic RTL', (t) async {
    await shoot(t,
        name: 'policy-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _screen(
          const PolicyCard(
            title: 'سياسة الخصوصية',
            icon: Icons.privacy_tip_outlined,
            text: _policyArabic,
            isDark: false,
          ),
          false,
          'المعلومات القانونية',
        ));
  });
}

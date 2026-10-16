// The API reference's three pieces, in isolation: the HTTP verb badge, a code block, and a
// parameter row.
//
// `ApiMethodBadge`, `ApiCodeBlock` and `ApiParameterRow` are the production widgets. The screen that
// holds them cannot be pumped — it reads `AppCubit` and `LocaleCubit` from above it and carries 730
// lines of its own content — so these are the parts, not the page.
//
// The Arabic shot is the point of the file: braces, quotes, slashes and colons are directionally
// NEUTRAL, so inside an RTL screen the bidi algorithm used to lay `/auth/sign_in` out as
// `sign_in/auth/` and take every JSON body apart at its punctuation.
//
//   flutter test test/visual --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat/modules/api_documentation/api_reference.dart';
import 'package:chat/shared/styles/lyn_palette.dart';
import 'package:chat/shared/styles/lyn_type.dart';
import 'package:chat/shared/styles/themes.dart';

import 'harness.dart';

const _response = '''{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "account_id": 123,
    "pubsub_token": "abc123xyz",
    "id": 456
  }
}''';

final _params = <ApiParameter>[
  ApiParameter(
    name: 'email',
    type: 'String',
    required: true,
    description: 'Email address',
    example: 'user@example.com',
  ),
  ApiParameter(
    name: 'inbox_id',
    type: 'int',
    required: false,
    description: 'Restrict the result to one inbox',
    example: '42',
  ),
];

final _paramsArabic = <ApiParameter>[
  ApiParameter(
    name: 'email',
    type: 'String',
    required: true,
    description: 'البريد الإلكتروني',
    example: 'user@example.com',
  ),
  ApiParameter(
    name: 'inbox_id',
    type: 'int',
    required: false,
    description: 'حصر النتيجة في صندوق وارد واحد',
    example: '42',
  ),
];

Widget _sheet(bool isDark, List<ApiParameter> params, String endpointLabel) => Builder(
      builder: (context) => Scaffold(
        backgroundColor: LynSurface.canvas(isDark),
        appBar: AppBar(
          backgroundColor: LynSurface.surface(isDark),
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: LynSurface.border(isDark))),
          centerTitle: true,
          iconTheme: IconThemeData(color: LynSurface.textPrimary(isDark)),
          title: Text('API documentation',
              style: LynType.headline.copyWith(color: LynSurface.textPrimary(isDark))),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(LynSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: LynSpace.sm,
                runSpacing: LynSpace.sm,
                children: [
                  for (final m in ['GET', 'POST', 'PUT', 'DELETE'])
                    ApiMethodBadge(method: m, isDark: isDark),
                ],
              ),
              const SizedBox(height: LynSpace.xl),
              Text(endpointLabel,
                  style: LynType.micro.copyWith(color: LynSurface.textTertiary(isDark))),
              const SizedBox(height: LynSpace.sm),
              ApiCodeBlock(code: '/auth/sign_in', isDark: isDark, onCopy: () {}),
              const SizedBox(height: LynSpace.xl),
              ApiCodeBlock(code: _response, isDark: isDark, onCopy: () {}),
              const SizedBox(height: LynSpace.xl),
              for (final p in params) ApiParameterRow(param: p, isDark: isDark),
            ],
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadRealFonts);

  testWidgets('api reference, light', (t) async {
    await shoot(t,
        name: 'api-light',
        theme: lightTheme,
        localizations: true,
        child: _sheet(false, _params, 'Endpoint'));
  });

  testWidgets('api reference, dark', (t) async {
    await shoot(t,
        name: 'api-dark',
        theme: darkTheme,
        localizations: true,
        child: _sheet(true, _params, 'Endpoint'));
  });

  testWidgets('api reference, Arabic RTL', (t) async {
    await shoot(t,
        name: 'api-arabic-rtl',
        theme: lightTheme,
        locale: const Locale('ar'),
        localizations: true,
        direction: TextDirection.rtl,
        child: _sheet(false, _paramsArabic, 'نقطة النهاية'));
  });
}

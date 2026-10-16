import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/app_localizations.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

/// The monospace face, named in a way that resolves on every platform this app ships to.
///
/// The code blocks asked for `fontFamily: 'monospace'`. That is a real family alias on Android and
/// nothing at all on iOS, where it silently falls back to the proportional system face — so the API
/// reference was not monospaced on half the devices. No font is bundled (and none needs to be): this
/// names each platform's own, and the engine takes the first that exists.
/// Android's own alias. Naming it as the FAMILY rather than as a fallback matters: a fallback list
/// is consulted only when the resolved family has no glyph, and the family here is inherited from the
/// ambient text style — so a call site that set the fallbacks alone stayed proportional.
const String kMonoFamily = 'monospace';

/// Where to go when the family above does not exist, which is everywhere that is not Android.
const List<String> kMonoFallback = <String>[
  'Menlo', // iOS, macOS
  'Courier New',
  'Courier',
];

/// An HTTP verb.
///
/// WHITE ON THE BRIGHT FILL WAS UNREADABLE. Measured against white, the four fills came out at
/// 3.30:1 (GET, on success green), 2.15:1 (POST, on warning amber), 3.26:1 (PUT, on blue) and
/// 3.76:1 (DELETE, on danger red). A 12px bold label needs 4.5:1. A tint with the deeper ink on it
/// — the pattern the status pills and limit chips already use — measures 5.39:1 to 7.86:1 in light
/// and 5.86:1 to 7.44:1 in dark, on every verb.
///
/// The hues themselves stay: green-for-GET and red-for-DELETE is the convention every API reference
/// a developer has read already uses, and breaking it to avoid reusing a status colour would cost
/// more than it saves.
class ApiMethodBadge extends StatelessWidget {
  const ApiMethodBadge({super.key, required this.method, required this.isDark});

  final String method;
  final bool isDark;

  static ({Color fill, Color ink}) accent(String method, bool isDark) {
    switch (method.toUpperCase()) {
      case 'GET':
        return (
          fill: LynPalette.success,
          ink: isDark ? LynPalette.successSoft : LynPalette.successInk,
        );
      case 'POST':
        return (
          fill: LynPalette.warning,
          ink: isDark ? LynPalette.warningSoft : LynPalette.warningInk,
        );
      case 'PUT':
      case 'PATCH':
        return (
          fill: LynPalette.blue,
          ink: isDark ? LynPalette.blueOnDark : LynPalette.royal,
        );
      case 'DELETE':
        return (
          fill: LynPalette.danger,
          ink: isDark ? LynPalette.dangerSoft : LynPalette.magentaDeep,
        );
      default:
        return (
          fill: LynSurface.borderStrong(isDark),
          ink: LynSurface.textSecondary(isDark),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = accent(method, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm, vertical: LynSpace.xs),
      decoration: BoxDecoration(
        color: a.fill.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(LynSpace.sm - 2),
      ),
      child: Text(
        method.toUpperCase(),
        // A verb is Latin whichever language the page is in, and must not be mirrored.
        textDirection: TextDirection.ltr,
        style: LynType.micro.copyWith(color: a.ink, fontFamily: kMonoFamily, fontFamilyFallback: kMonoFallback),
      ),
    );
  }
}

/// A block of code: an endpoint path, a request body, a response.
///
/// LOCKED LEFT-TO-RIGHT, which it was not. Braces, quotes, slashes and colons are directionally
/// NEUTRAL characters: inside an Arabic screen the bidi algorithm lays them out right-to-left, so
/// `/auth/sign_in` was drawn as `sign_in/auth/` and every JSON body came apart at its punctuation. A
/// developer copying a path out of the Arabic build got a broken one.
///
/// It also scrolls sideways rather than wrapping, because a wrapped JSON line is a different
/// document from the one the server returns.
class ApiCodeBlock extends StatelessWidget {
  const ApiCodeBlock({super.key, required this.code, required this.isDark, this.onCopy});

  final String code;
  final bool isDark;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? LynPalette.ink : LynPalette.mist,
        borderRadius: BorderRadius.circular(LynSpace.sm),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      // The WHOLE block is left-to-right, not just the text in it. A horizontal scroll view takes
      // its origin from the ambient direction, so on an Arabic screen it opened scrolled to the far
      // END of the code and the first characters of every JSON body were off the left edge.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(LynSpace.md),
                child: Text(
                  code,
                  style: LynType.caption.copyWith(
                    color: LynSurface.textPrimary(isDark),
                    fontFamily: kMonoFamily,
                    fontFamilyFallback: kMonoFallback,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.tr(context, 'Copy'),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy_rounded, color: LynSurface.textSecondary(isDark)),
              onPressed: onCopy ??
                  () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.tr(context, 'Copied')),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}

/// One request parameter.
class ApiParameterRow extends StatelessWidget {
  const ApiParameterRow({super.key, required this.param, required this.isDark});

  final ApiParameter param;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final nameInk = isDark ? LynPalette.blueOnDark : LynPalette.royal;

    return Container(
      margin: const EdgeInsets.only(bottom: LynSpace.sm),
      padding: const EdgeInsets.all(LynSpace.md),
      decoration: BoxDecoration(
        color: LynSurface.canvasAlt(isDark),
        borderRadius: BorderRadius.circular(LynSpace.sm),
        border: Border.all(color: LynSurface.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: LynSpace.sm,
            runSpacing: LynSpace.xs,
            children: [
              Text(
                param.name,
                // A parameter's name is an identifier the caller types verbatim.
                textDirection: TextDirection.ltr,
                style: LynType.caption.copyWith(
                  color: nameInk,
                  fontFamily: kMonoFamily, fontFamilyFallback: kMonoFallback,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm - 2, vertical: 1),
                decoration: BoxDecoration(
                  color: LynSurface.surfaceMuted(isDark),
                  borderRadius: BorderRadius.circular(LynSpace.xs),
                ),
                child: Text(
                  param.type,
                  textDirection: TextDirection.ltr,
                  style: LynType.micro.copyWith(color: LynSurface.textSecondary(isDark)),
                ),
              ),
              if (param.required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: LynSpace.sm - 2, vertical: 1),
                  decoration: BoxDecoration(
                    // Was raw `Colors.red` over a 20%-opacity red — a hue from outside the palette,
                    // set on a tint of itself.
                    color: LynSurface.dangerSurface(isDark),
                    borderRadius: BorderRadius.circular(LynSpace.xs),
                  ),
                  child: Text(
                    AppLocalizations.tr(context, 'required'),
                    style: LynType.micro.copyWith(color: LynSurface.dangerText(isDark)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LynSpace.xs),
          Text(
            param.description,
            style: LynType.caption.copyWith(color: LynSurface.textSecondary(isDark)),
          ),
          if (param.example != null) ...[
            const SizedBox(height: LynSpace.xs),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${AppLocalizations.tr(context, 'Example')}: ',
                    style: LynType.micro.copyWith(color: LynSurface.textTertiary(isDark)),
                  ),
                  TextSpan(
                    text: param.example,
                    style: LynType.micro.copyWith(
                      color: nameInk,
                      fontFamily: kMonoFamily, fontFamilyFallback: kMonoFallback,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ApiParameter {
  final String name;
  final String type;
  final bool required;
  final String description;
  final String? example;

  ApiParameter({
    required this.name,
    required this.type,
    required this.required,
    required this.description,
    this.example,
  });
}
